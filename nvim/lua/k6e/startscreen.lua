local venus = require("plugins.headers.venus")

local M = {}

local namespace = vim.api.nvim_create_namespace("k6e-startscreen")
local states = {}

local function starts_with(value, prefix)
	return value:sub(1, #prefix) == prefix
end

local function resolve(value)
	while type(value) == "function" do
		value = value()
	end
	return value
end

local function merge_opts(parent, child)
	if parent == nil then
		return child or {}
	end
	if child == nil then
		return parent
	end
	return vim.tbl_extend("force", parent, child)
end

local function text_lines(value)
	value = resolve(value)
	if type(value) == "string" then
		local lines = vim.split(value, "\n", { plain = true })
		if lines[#lines] == "" and value:sub(-1) == "\n" then
			table.remove(lines)
		end
		return lines
	end
	if type(value) == "table" then
		return value
	end
	return { tostring(value or "") }
end

local function add_highlight(rendered, row, left, text, highlight)
	if type(highlight) == "string" then
		rendered.highlights[#rendered.highlights + 1] = {
			row = row,
			start_col = left,
			end_col = left + #text,
			group = highlight,
		}
		return
	end

	if type(highlight) ~= "table" then
		return
	end

	for _, range in ipairs(highlight) do
		local end_col = range[3]
		if end_col < 0 then
			end_col = #text + end_col + 1
		end
		rendered.highlights[#rendered.highlights + 1] = {
			row = row,
			start_col = left + range[2],
			end_col = left + end_col,
			group = range[1],
		}
	end
end

local function render_text(element, opts, rendered, width)
	local lines = text_lines(element.val)
	local highlights = opts.hl
	local line_highlights = type(highlights) == "table"
		and type(highlights[1]) == "table"
		and type(highlights[1][1]) == "table"

	for index, text in ipairs(lines) do
		local left = 0
		if opts.position == "center" then
			left = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
		end
		local row = #rendered.lines
		rendered.lines[#rendered.lines + 1] = string.rep(" ", left) .. text
		local highlight = line_highlights and highlights[index] or highlights
		add_highlight(rendered, row, left, text, highlight)
	end
end

local render_element

local function render_group(element, opts, rendered, width)
	local value = resolve(element.val)
	if type(value) ~= "table" then
		return
	end
	if value.type ~= nil then
		render_element(value, opts, rendered, width)
		return
	end
	for _, child in ipairs(value) do
		child = resolve(child)
		if child ~= nil then
			render_element(child, opts, rendered, width)
		end
	end
end

local function render_padding(element, rendered)
	local count = tonumber(resolve(element.val)) or 0
	for _ = 1, math.max(0, math.floor(count)) do
		rendered.lines[#rendered.lines + 1] = ""
	end
end

local function render_button(element, opts, rendered, width)
	local value = resolve(element.val)
	local text
	if type(value) == "table" then
		text = table.concat(value, "")
	else
		text = tostring(value or "")
	end
	local left = 0
	if opts.position == "center" then
		left = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
	end
	local row = #rendered.lines
	rendered.lines[#rendered.lines + 1] = string.rep(" ", left) .. text
	add_highlight(rendered, row, left, text, opts.hl)
	rendered.buttons[#rendered.buttons + 1] = {
		row = row,
		shortcut = opts.shortcut,
		action = element.on_press,
	}
end

render_element = function(element, parent_opts, rendered, width)
	if type(element) ~= "table" then
		return
	end
	local opts = merge_opts(parent_opts, element.opts)
	if element.type == "text" then
		render_text(element, opts, rendered, width)
	elseif element.type == "padding" then
		render_padding(element, rendered)
	elseif element.type == "group" then
		render_group(element, opts, rendered, width)
	elseif element.type == "button" then
		render_button(element, opts, rendered, width)
	else
		error(("unknown startscreen element type: %s"):format(tostring(element.type)))
	end
end

local function clear_mappings(state)
	if not vim.api.nvim_buf_is_valid(state.buffer) then
		state.mappings = {}
		return
	end
	for _, lhs in ipairs(state.mappings) do
		pcall(vim.keymap.del, "n", lhs, { buffer = state.buffer })
	end
	state.mappings = {}
end

local function invoke(action)
	if type(action) == "function" then
		action()
	elseif type(action) == "string" then
		vim.cmd(action)
	end
end

local function install_mappings(state, buttons)
	clear_mappings(state)
	local mapped = {}

	for _, button in ipairs(buttons) do
		local shortcut = button.shortcut
		if type(shortcut) == "string" and shortcut ~= "" and not mapped[shortcut] then
			vim.keymap.set("n", shortcut, function()
				invoke(button.action)
			end, { buffer = state.buffer, nowait = true, silent = true })
			state.mappings[#state.mappings + 1] = shortcut
			mapped[shortcut] = true
		end
	end

	vim.keymap.set("n", "<CR>", function()
		local row = vim.api.nvim_win_get_cursor(0)[1] - 1
		for _, button in ipairs(state.buttons) do
			if button.row == row then
				invoke(button.action)
				return
			end
		end
	end, { buffer = state.buffer, nowait = true, silent = true })
	state.mappings[#state.mappings + 1] = "<CR>"
end

local function active_window(state)
	if vim.api.nvim_win_is_valid(state.window) and vim.api.nvim_win_get_buf(state.window) == state.buffer then
		return state.window
	end
	for _, window in ipairs(vim.fn.win_findbuf(state.buffer)) do
		if vim.api.nvim_win_is_valid(window) then
			state.window = window
			return window
		end
	end
end

local function draw(state)
	if not vim.api.nvim_buf_is_valid(state.buffer) then
		states[state.buffer] = nil
		return
	end
	local window = active_window(state)
	if window == nil then
		return
	end

	local rendered = { lines = {}, highlights = {}, buttons = {} }
	local width = vim.api.nvim_win_get_width(window)
	local layout = state.layout or venus.render()
	state.layout = layout
	if layout.type ~= nil then
		render_element(layout, nil, rendered, width)
	else
		for _, element in ipairs(layout) do
			render_element(resolve(element), nil, rendered, width)
		end
	end

	local height = vim.api.nvim_win_get_height(window)
	local top = math.max(0, math.floor((height - #rendered.lines) / 2))
	if top > 0 then
		local centered = {}
		for _ = 1, top do
			centered[#centered + 1] = ""
		end
		vim.list_extend(centered, rendered.lines)
		rendered.lines = centered
		for _, highlight in ipairs(rendered.highlights) do
			highlight.row = highlight.row + top
		end
		for _, button in ipairs(rendered.buttons) do
			button.row = button.row + top
		end
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = state.buffer })
	vim.api.nvim_buf_clear_namespace(state.buffer, namespace, 0, -1)
	vim.api.nvim_buf_set_lines(state.buffer, 0, -1, false, rendered.lines)
	for _, highlight in ipairs(rendered.highlights) do
		vim.api.nvim_buf_set_extmark(state.buffer, namespace, highlight.row, highlight.start_col, {
			end_col = highlight.end_col,
			hl_group = highlight.group,
		})
	end
	vim.api.nvim_set_option_value("modifiable", false, { buf = state.buffer })

	state.buttons = rendered.buttons
	install_mappings(state, rendered.buttons)
end

local function should_skip_startup()
	if vim.fn.argc() > 0 then
		return true
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, 2, false)
	if #lines > 1 or (#lines == 1 and lines[1] ~= "") then
		return true
	end

	local current = vim.api.nvim_get_current_buf()
	for _, window in ipairs(vim.api.nvim_list_wins()) do
		local buffer = vim.api.nvim_win_get_buf(window)
		if buffer ~= current and vim.bo[buffer].buflisted then
			return true
		end
	end

	if not vim.bo[current].modifiable then
		return true
	end

	for _, argument in ipairs(vim.v.argv) do
		if argument == "-b" or argument == "-c" or starts_with(argument, "+") or argument == "-S" then
			return true
		end
	end

	return false
end

local function configure_buffer(buffer)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buffer })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buffer })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buffer })
	vim.api.nvim_set_option_value("buflisted", false, { buf = buffer })
	vim.api.nvim_set_option_value("filetype", "k6e-startscreen", { buf = buffer })
end

local function configure_window(window)
	vim.api.nvim_set_option_value("number", false, { win = window })
	vim.api.nvim_set_option_value("relativenumber", false, { win = window })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = window })
	vim.api.nvim_set_option_value("foldcolumn", "0", { win = window })
end

function M.start(on_vimenter)
	if on_vimenter and should_skip_startup() then
		return
	end

	local buffer = vim.api.nvim_get_current_buf()
	local window = vim.api.nvim_get_current_win()
	configure_buffer(buffer)
	configure_window(window)

	local state = states[buffer]
	if state == nil then
		state = {
			buffer = buffer,
			window = window,
			layout = venus.render(),
			buttons = {},
			mappings = {},
		}
		states[buffer] = state
	else
		state.window = window
		state.layout = venus.render()
	end
	draw(state)
end

function M.redraw()
	for buffer, state in pairs(states) do
		if vim.api.nvim_buf_is_valid(buffer) then
			state.layout = venus.render()
			draw(state)
		else
			states[buffer] = nil
		end
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("k6e-startscreen", { clear = true })
	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		nested = true,
		callback = function()
			M.start(true)
		end,
	})
	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		callback = M.redraw,
	})
	vim.api.nvim_create_autocmd("DirChanged", {
		group = group,
		callback = function()
			for _, state in pairs(states) do
				state.layout = nil
			end
			M.redraw()
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(event)
			states[event.buf] = nil
		end,
	})
end

return M
