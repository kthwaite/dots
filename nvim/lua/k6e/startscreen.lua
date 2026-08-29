local venus = require("plugins.headers.venus")

local M = {}
local mru_cache = {}
local mru_sources = {}
local icon_providers = {
	loader = nil,
	mini = nil,
	devicons = nil,
}

M._test = {
	oldfiles = function()
		return vim.v.oldfiles or {}
	end,
	filereadable = function(path)
		return vim.fn.filereadable(path) == 1
	end,
	getcwd = vim.fn.getcwd,
	fnamemodify = vim.fn.fnamemodify,
	load_icon_provider = function(name)
		local ok, provider = pcall(require, name)
		if ok then
			return provider
		end
	end,
}

local namespace = vim.api.nvim_create_namespace("k6e-startscreen")
local states = {}

local function starts_with(value, prefix)
	return value:sub(1, #prefix) == prefix
end

local function version_string()
	local version = vim.version()
	if version == nil then
		return "UNKNOWN"
	end
	return ("v%d.%d.%d"):format(version.major, version.minor, version.patch)
end

local function extension(path)
	local basename = path:match("[^/\\]+$") or path
	return basename:match("^.+%.(.+)$") or ""
end

local function ignored_mru_path(path)
	return path:find("COMMIT_EDITMSG", 1, true) ~= nil or extension(path) == "gitcommit"
end

local function inside_cwd(path, cwd)
	if path == cwd then
		return true
	end
	local separator = cwd:sub(-1) == "/" and "" or "/"
	return starts_with(path, cwd .. separator)
end

local function mru_paths(cwd)
	if mru_sources.oldfiles ~= M._test.oldfiles or mru_sources.filereadable ~= M._test.filereadable then
		mru_cache = {}
		mru_sources.oldfiles = M._test.oldfiles
		mru_sources.filereadable = M._test.filereadable
	end
	local key = cwd or "global"
	if mru_cache[key] ~= nil then
		return mru_cache[key]
	end

	local found = {}
	local seen = {}
	for _, path in ipairs(M._test.oldfiles()) do
		if
			not seen[path]
			and (cwd == nil or inside_cwd(path, cwd))
			and not ignored_mru_path(path)
			and M._test.filereadable(path)
		then
			found[#found + 1] = path
			seen[path] = true
			if #found == 10 then
				break
			end
		end
	end
	mru_cache[key] = found
	return found
end

local function icon_provider(field, name)
	local loader = M._test.load_icon_provider
	if icon_providers.loader ~= loader then
		icon_providers.loader = loader
		icon_providers.mini = nil
		icon_providers.devicons = nil
	end
	if icon_providers[field] == nil then
		icon_providers[field] = loader(name) or false
	end
	return icon_providers[field]
end

local function mini_icon(provider, path)
	if not provider then
		return
	end
	local ext = extension(path)
	local kind = ext == "" and "file" or "extension"
	local name = ext == "" and path or ext
	local ok, icon, highlight = pcall(provider.get, kind, name)
	if ok and icon ~= nil and icon ~= "" then
		return icon, highlight
	end
end

local function devicon(provider, path)
	if not provider then
		return
	end
	local ok, icon, highlight = pcall(provider.get_icon, path, extension(path), { default = true })
	if ok and icon ~= nil and icon ~= "" then
		return icon, highlight
	end
end

local function file_icon(path)
	local icon, highlight = mini_icon(icon_provider("mini", "mini.icons"), path)
	if icon == nil then
		icon, highlight = devicon(icon_provider("devicons", "nvim-web-devicons"), path)
	end
	return icon, highlight
end

local function shortcut_highlights(shortcut)
	return {
		{ "Operator", 0, 1 },
		{ "Number", 1, #shortcut + 1 },
		{ "Operator", #shortcut + 1, #shortcut + 2 },
	}
end

local function command_action(command)
	return function()
		local keys = vim.api.nvim_replace_termcodes(command .. "<Ignore>", true, false, true)
		vim.api.nvim_feedkeys(keys, "t", false)
	end
end

local function button(shortcut, label, command)
	return {
		type = "button",
		val = ("[%s] %s"):format(shortcut, label),
		on_press = command_action(command),
		opts = {
			shortcut = shortcut,
			hl = shortcut_highlights(shortcut),
		},
	}
end

local function file_button(path, shortcut, short_path)
	local shortcut_text = ("[%s] "):format(shortcut)
	local icon, icon_highlight = file_icon(path)
	local icon_text = icon and (icon .. "  ") or ""
	local highlights = shortcut_highlights(shortcut)

	if icon and icon_highlight then
		highlights[#highlights + 1] = {
			icon_highlight,
			#shortcut_text,
			#shortcut_text + #icon,
		}
	end
	local directory = short_path:match(".*[/\\]")
	if directory then
		highlights[#highlights + 1] = {
			"Comment",
			#shortcut_text + #icon_text,
			#shortcut_text + #icon_text + #directory,
		}
	end

	return {
		type = "button",
		val = shortcut_text .. icon_text .. short_path,
		on_press = command_action("<cmd>e " .. vim.fn.fnameescape(path) .. " <CR>"),
		opts = {
			shortcut = shortcut,
			hl = highlights,
		},
	}
end

local function mru_buttons(start, cwd)
	local buttons = {}
	local modifier = cwd and ":." or ":~"
	for index, path in ipairs(mru_paths(cwd)) do
		buttons[#buttons + 1] = file_button(path, tostring(index + start - 1), M._test.fnamemodify(path, modifier))
	end
	return {
		type = "group",
		val = buttons,
	}
end

local function production_layout()
	local cwd = M._test.getcwd()
	return {
		{ type = "padding", val = 1 },
		venus.render(),
		{ type = "padding", val = 1 },
		{ type = "text", val = "NVIM " .. version_string(), opts = { position = "center" } },
		{ type = "padding", val = 1 },
		{
			type = "group",
			val = {
				button("e", "New file", "<cmd>ene <CR>"),
			},
		},
		{
			type = "group",
			val = {
				{
					type = "group",
					val = {
						{ type = "padding", val = 1 },
						{ type = "text", val = "MRU", opts = { hl = "SpecialComment" } },
						{ type = "padding", val = 1 },
						mru_buttons(10),
					},
				},
			},
		},
		{
			type = "group",
			val = {
				{ type = "padding", val = 1 },
				{
					type = "text",
					val = "MRU " .. M._test.fnamemodify(cwd, ":~"),
					opts = { hl = "SpecialComment" },
				},
				{ type = "padding", val = 1 },
				mru_buttons(0, cwd),
			},
		},
		{ type = "padding", val = 1 },
		{
			type = "group",
			val = {
				button("q", "Quit", "<cmd>q <CR>"),
			},
		},
		{ type = "group", val = {} },
	}
end

local layout_factory = venus.render

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
			end, { buffer = state.buffer, silent = true })
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
	local layout = state.layout or layout_factory()
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

local function restore_colorcolumn(state)
	if not state.colorcolumn_hidden then
		return
	end
	if vim.api.nvim_win_is_valid(state.window) then
		pcall(vim.api.nvim_set_option_value, "colorcolumn", state.colorcolumn, { win = state.window })
	end
	state.colorcolumn_hidden = false
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
	vim.api.nvim_set_option_value("colorcolumn", "", { win = window })
end

function M.start(on_vimenter)
	if on_vimenter and should_skip_startup() then
		return
	end

	local buffer = vim.api.nvim_get_current_buf()
	local window = vim.api.nvim_get_current_win()
	local state = states[buffer]
	if state == nil then
		state = {
			buffer = buffer,
			window = window,
			layout = layout_factory(),
			buttons = {},
			mappings = {},
			colorcolumn = vim.api.nvim_get_option_value("colorcolumn", { win = window }),
			colorcolumn_hidden = false,
		}
		states[buffer] = state
	else
		state.window = window
		state.layout = layout_factory()
	end

	configure_buffer(buffer)
	configure_window(window)
	state.colorcolumn_hidden = true
	draw(state)
end

function M.redraw()
	for buffer, state in pairs(states) do
		if vim.api.nvim_buf_is_valid(buffer) then
			state.layout = layout_factory()
			draw(state)
		else
			states[buffer] = nil
		end
	end
end

function M.setup()
	layout_factory = production_layout
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
			mru_cache = {}
			for _, state in pairs(states) do
				state.layout = nil
			end
			M.redraw()
		end,
	})
	vim.api.nvim_create_autocmd("BufLeave", {
		group = group,
		callback = function(event)
			local state = states[event.buf]
			if state ~= nil then
				restore_colorcolumn(state)
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(event)
			local state = states[event.buf]
			if state ~= nil then
				restore_colorcolumn(state)
				states[event.buf] = nil
			end
		end,
	})
end

return M
