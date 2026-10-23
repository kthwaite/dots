--- Cmdline popup driven by ext_cmdline ui events.
local M = {}

local ICONS = {
	search = "\u{f002}",
	calculator = "\u{f1ec}",
	lua = "\u{e620}",
	cmdline = "\u{f120}",
	prompt = "\u{f097b}",
	help = "\u{f02d6}",
	shell = "$",
}

local ns = vim.api.nvim_create_namespace("k6e.ui")
local cursor_ns = vim.api.nvim_create_namespace("k6e.ui.cursor")
local group = vim.api.nvim_create_augroup("k6e.ui", { clear = true })

---@class k6e.ui.Kind
---@field icon string
---@field title string
---@field lang string?

---@class k6e.ui.Level
---@field text string
---@field pos integer
---@field firstc string
---@field prompt string
---@field special { c: string, shift: boolean }?

--- Active cmdlines keyed by level. The popup shows the highest level.
---@type table<integer, k6e.ui.Level>
local levels = {}
---@type string[]
local block = {}
---@type integer?
local buf
---@type integer?
local win
---@type { title: string, level: integer }?
local shown
--- Treesitter language currently started on `buf`.
---@type string?
local started_lang

M._attached = false

---@param text string
---@return boolean
local function is_help(text)
	local word = text:match("^%s*(h%a*)%s")
	return word ~= nil and vim.startswith("help", word)
end

---@param firstc string
---@param text string
---@param prompt string
---@return k6e.ui.Kind
function M.kind(firstc, text, prompt)
	if firstc == "" then
		local label = vim.trim(prompt)
		return { icon = ICONS.prompt, title = label ~= "" and " " .. label .. " " or " Input " }
	elseif firstc == "/" or firstc == "?" then
		return { icon = ICONS.search, title = " Search ", lang = "regex" }
	elseif firstc == "=" then
		return { icon = ICONS.calculator, title = " Calculator ", lang = "vim" }
	elseif firstc == ":" then
		if text:find("^%s*!") then
			return { icon = ICONS.shell, title = " Shell ", lang = "bash" }
		elseif text:find("^%s*lua%s") or text:find("^%s*lua%s*=") or text:find("^%s*=") then
			return { icon = ICONS.lua, title = " Lua ", lang = "lua" }
		elseif is_help(text) then
			return { icon = ICONS.help, title = " Help ", lang = "vim" }
		end
	end
	return { icon = ICONS.cmdline, title = " Cmdline ", lang = "vim" }
end

---@param content [any, string][]
---@return string
local function concat(content)
	local parts = {}
	for _, chunk in ipairs(content) do
		parts[#parts + 1] = chunk[2]
	end
	return table.concat(parts)
end

local function define_highlights()
	vim.api.nvim_set_hl(0, "K6eUiCursor", { link = "Cursor", default = true })
end

local function close()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	win, shown = nil, nil
	vim.g.ui_cmdline_pos = nil
end

---@param lang string?
local function highlight(lang)
	if lang == started_lang then
		return
	end
	if started_lang then
		pcall(vim.treesitter.stop, buf)
		started_lang = nil
	end
	if not lang then
		return
	end
	local ok, added = pcall(vim.treesitter.language.add, lang)
	if ok and added and pcall(vim.treesitter.start, buf, lang) then
		started_lang = lang
	end
end

---@param entry k6e.ui.Level
---@return string
local function display_text(entry)
	local text, special = entry.text, entry.special
	if special then
		local rest = entry.pos + 1
		if not special.shift and rest <= #text then
			rest = rest + 1 + vim.str_utf_end(text, rest)
		end
		text = text:sub(1, entry.pos) .. special.c .. text:sub(rest)
	end
	-- A literal NL (c_CTRL-V CTRL-J) cannot go into a buffer line. NUL keeps the byte
	-- offsets and the API stores it as NL, so it displays as ^@ like the native cmdline.
	return (text:gsub("\n", "\0"))
end

---@param line string
---@param row integer
---@param col integer
local function place_cursor(line, row, col)
	vim.api.nvim_buf_clear_namespace(buf, cursor_ns, 0, -1)
	if col >= #line then
		vim.api.nvim_buf_set_extmark(buf, cursor_ns, row, #line, {
			virt_text = { { " ", "K6eUiCursor" } },
			virt_text_pos = "overlay",
		})
	else
		vim.api.nvim_buf_set_extmark(buf, cursor_ns, row, col, {
			end_col = col + 1 + vim.str_utf_end(line, col + 1),
			hl_group = "K6eUiCursor",
		})
	end
end

local function render()
	local level
	for l in pairs(levels) do
		level = (level == nil or l > level) and l or level
	end
	if not level then
		return close()
	end
	local entry = levels[level]
	local kind = M.kind(entry.firstc, entry.text, entry.prompt)
	local lines = vim.list_extend(vim.list_slice(block), { kind.icon .. " " .. display_text(entry) })
	local last = lines[#lines]

	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		buf = vim.api.nvim_create_buf(false, true)
		vim.bo[buf].undolevels = -1
		started_lang = nil
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = math.min(math.max(60, vim.api.nvim_strwidth(last) + 2), vim.o.columns - 4)
	local config = {
		relative = "editor",
		row = math.floor(vim.o.lines * 0.25),
		col = math.floor((vim.o.columns - width - 2) / 2),
		width = width,
		height = #lines,
		border = "rounded",
		title = kind.title,
		title_pos = "center",
		zindex = 200,
		focusable = false,
	}
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_set_config(win, config)
	else
		config.style = "minimal"
		config.noautocmd = true
		win = vim.api.nvim_open_win(buf, false, config)
	end
	shown = { title = kind.title, level = level }

	highlight(kind.lang)
	place_cursor(last, #lines - 1, #kind.icon + 1 + entry.pos)
	-- Screen position of the text line: 1-based row below the top border, 0-based col after the icon.
	vim.g.ui_cmdline_pos = { config.row + 1 + #lines, config.col + 1 + vim.api.nvim_strwidth(kind.icon .. " ") }
end

local handlers = {}

function handlers.cmdline_show(content, pos, firstc, prompt, _, level)
	levels[level] = { text = concat(content), pos = pos, firstc = firstc, prompt = prompt }
end

function handlers.cmdline_pos(pos, level)
	if levels[level] then
		levels[level].pos = pos
	end
end

function handlers.cmdline_special_char(c, shift, level)
	if levels[level] then
		levels[level].special = { c = c, shift = shift }
	end
end

function handlers.cmdline_hide(level)
	levels[level] = nil
end

function handlers.cmdline_block_show(lines)
	block = vim.tbl_map(concat, lines)
end

function handlers.cmdline_block_append(line)
	block[#block + 1] = concat(line)
end

function handlers.cmdline_block_hide()
	block = {}
end

--- Apply one ui-cmdline event and re-render the popup. Arguments as in |ui-cmdline|.
---@param event string
function M.handle(event, ...)
	local handler = handlers[event]
	if handler then
		handler(...)
		render()
	end
end

--- Looks up M.handle at call time so it can be replaced.
local function dispatch(...)
	M.handle(...)
	if #vim.api.nvim_list_uis() > 0 then
		vim.api.nvim__redraw({ flush = true, cursor = true })
	end
end

--- ui_attach callback. On error, detach and fall back to the native cmdline.
---@param event string
---@return true?
function M._on_event(event, ...)
	local ok, err = xpcall(dispatch, tostring, event, ...)
	if ok then
		return true
	end
	M.detach()
	vim.schedule(function()
		vim.notify("k6e.ui: " .. err .. "; falling back to native cmdline", vim.log.levels.ERROR)
	end)
end

function M.attach()
	if M._attached then
		return
	end
	define_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
	vim.ui_attach(ns, { ext_cmdline = true }, function(...)
		return M._on_event(...)
	end)
	M._attached = true
end

function M.detach()
	if M._attached then
		vim.ui_detach(ns)
		M._attached = false
	end
	vim.api.nvim_clear_autocmds({ group = group })
	levels, block = {}, {}
	pcall(close)
end

---@return { visible: boolean, win: integer?, buf: integer?, lines: string[], title: string?, level: integer? }
function M._state()
	local visible = win ~= nil and vim.api.nvim_win_is_valid(win)
	return {
		visible = visible,
		win = visible and win or nil,
		buf = buf,
		lines = visible and vim.api.nvim_buf_get_lines(buf --[[@as integer]], 0, -1, false) or {},
		title = shown and shown.title,
		level = shown and shown.level,
	}
end

return M
