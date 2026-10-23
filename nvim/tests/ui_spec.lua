local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(source, ":p:h:h")
vim.opt.runtimepath:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	package.path,
}, ";")

local tests = {}
local function test(name, callback)
	tests[#tests + 1] = { name = name, callback = callback }
end

local function equal(actual, expected, message)
	if not vim.deep_equal(actual, expected) then
		error(string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
	end
end

local function truthy(value, message)
	if not value then
		error(message)
	end
end

local SEARCH = "\u{f002}"
local CALC = "\u{f1ec}"
local LUA = "\u{e620}"
local CMDLINE = "\u{f120}"
local PROMPT = "\u{f097b}"
local HELP = "\u{f02d6}"

local function fresh()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative ~= "" then
			vim.api.nvim_win_close(win, true)
		end
	end
	vim.g.ui_cmdline_pos = nil
	vim.o.columns = 120
	vim.o.lines = 40
	package.loaded["k6e.ui"] = nil
	return require("k6e.ui")
end

local function show(ui, text, pos, firstc, level, prompt)
	ui.handle("cmdline_show", { { 0, text } }, pos or #text, firstc or ":", prompt or "", 0, level or 1, 0)
end

test("kind table", function()
	local ui = fresh()
	local cases = {
		{ { "", "", "Name: " }, { icon = PROMPT, title = " Name: " } },
		{ { "", "abc", "" }, { icon = PROMPT, title = " Input " } },
		{ { "/", "foo", "" }, { icon = SEARCH, title = " Search ", lang = "regex" } },
		{ { "?", "foo", "" }, { icon = SEARCH, title = " Search ", lang = "regex" } },
		{ { "=", "1+1", "" }, { icon = CALC, title = " Calculator ", lang = "vim" } },
		{ { ":", "!ls", "" }, { icon = "$", title = " Shell ", lang = "bash" } },
		{ { ":", "  !ls", "" }, { icon = "$", title = " Shell ", lang = "bash" } },
		{ { ":", "lua print(1)", "" }, { icon = LUA, title = " Lua ", lang = "lua" } },
		{ { ":", "lua= 1", "" }, { icon = LUA, title = " Lua ", lang = "lua" } },
		{ { ":", " lua =1", "" }, { icon = LUA, title = " Lua ", lang = "lua" } },
		{ { ":", "=1+1", "" }, { icon = LUA, title = " Lua ", lang = "lua" } },
		{ { ":", "luafile x", "" }, { icon = CMDLINE, title = " Cmdline ", lang = "vim" } },
		{ { ":", "h foo", "" }, { icon = HELP, title = " Help ", lang = "vim" } },
		{ { ":", "hel foo", "" }, { icon = HELP, title = " Help ", lang = "vim" } },
		{ { ":", "help foo", "" }, { icon = HELP, title = " Help ", lang = "vim" } },
		{ { ":", "hide foo", "" }, { icon = CMDLINE, title = " Cmdline ", lang = "vim" } },
		{ { ":", "helpx foo", "" }, { icon = CMDLINE, title = " Cmdline ", lang = "vim" } },
		{ { ":", "hello", "" }, { icon = CMDLINE, title = " Cmdline ", lang = "vim" } },
		{ { ":", "", "" }, { icon = CMDLINE, title = " Cmdline ", lang = "vim" } },
	}
	for _, case in ipairs(cases) do
		equal(ui.kind(unpack(case[1])), case[2], "kind" .. vim.inspect(case[1]))
	end
end)

test("show and hide", function()
	local ui = fresh()
	ui.handle("cmdline_show", { { 0, "ec" } }, 2, ":", "", 0, 1, 0)
	local state = ui._state()
	truthy(state.visible, "visible after show")
	equal(state.lines, { "ec" }, "lines")
	equal(state.title, " Cmdline ", "title")
	equal(state.level, 1, "level")
	local config = vim.api.nvim_win_get_config(state.win)
	equal(config.relative, "editor", "relative")
	equal(config.row, math.floor(40 * 0.25), "row")
	truthy(config.width >= 60, "width at least 60")
	equal(config.width, 60, "width")
	equal(config.height, 1, "height")
	equal(config.col, math.floor((120 - 60 - 2) / 2), "col")
	equal(config.zindex, 200, "zindex")
	equal(config.focusable, false, "focusable")
	equal(vim.api.nvim_win_get_buf(state.win), state.buf, "buffer")
	-- blink places its menu at pos[2] + start_col (1-based), so pos[2] is the text start col - 1.
	equal(vim.g.ui_cmdline_pos, { config.row + 2, config.col + vim.api.nvim_strwidth(CMDLINE .. " ") }, "pos")

	local win = state.win
	ui.handle("cmdline_hide", 1, false)
	state = ui._state()
	truthy(not state.visible, "hidden")
	truthy(not vim.api.nvim_win_is_valid(win), "window closed")
	equal(vim.g.ui_cmdline_pos, nil, "pos cleared")
end)

test("buffer is reused", function()
	local ui = fresh()
	show(ui, "ec")
	local buf = ui._state().buf
	ui.handle("cmdline_hide", 1, false)
	show(ui, "ec")
	equal(ui._state().buf, buf, "same buffer")
	equal(vim.bo[buf].buftype, "nofile", "scratch")
end)

test("width grows and is capped", function()
	local ui = fresh()
	local long = ("x"):rep(80)
	show(ui, long)
	equal(
		vim.api.nvim_win_get_config(ui._state().win).width,
		vim.api.nvim_strwidth(CMDLINE .. " " .. long) + 2,
		"grown"
	)
	show(ui, ("x"):rep(200))
	equal(vim.api.nvim_win_get_config(ui._state().win).width, 120 - 4, "capped")
end)

test("width stays positive on a tiny editor", function()
	local ui = fresh()
	vim.o.columns = 4
	show(ui, "ec")
	truthy(ui._state().visible, "shown")
	equal(vim.api.nvim_win_get_config(ui._state().win).width, 1, "clamped to 1")
end)

test("icon is inline virtual text", function()
	local ui = fresh()
	ui.handle("cmdline_block_show", { { { 0, "if 1" } } })
	show(ui, "ec")
	local ns = vim.api.nvim_get_namespaces()["k6e.ui.text"]
	local marks = vim.api.nvim_buf_get_extmarks(ui._state().buf, ns, 0, -1, { details = true })
	local icons = vim.tbl_filter(function(mark)
		return mark[4].virt_text ~= nil
	end, marks)
	equal(#icons, 1, "one icon mark")
	equal({ icons[1][2], icons[1][3] }, { 1, 0 }, "icon at col 0 of the text line")
	equal(icons[1][4].virt_text, { { CMDLINE .. " ", "K6eUiIcon" } }, "icon text")
	equal(icons[1][4].virt_text_pos, "inline", "inline")
end)

local function cursor_mark(ui)
	local ns = vim.api.nvim_get_namespaces()["k6e.ui.cursor"]
	local marks = vim.api.nvim_buf_get_extmarks(ui._state().buf, ns, 0, -1, { details = true })
	equal(#marks, 1, "one cursor mark")
	return marks[1]
end

test("fake cursor", function()
	local ui = fresh()
	show(ui, "ec", 2)
	local mark = cursor_mark(ui)
	equal({ mark[2], mark[3] }, { 0, 2 }, "end of line position")
	equal(mark[4].virt_text, { { " ", "K6eUiCursor" } }, "end of line virt text")

	ui.handle("cmdline_pos", 1, 1)
	mark = cursor_mark(ui)
	equal({ mark[2], mark[3] }, { 0, 1 }, "mid line position")
	equal(mark[4].hl_group, "K6eUiCursor", "mid line highlight")
	equal(mark[4].end_col, 2, "covers one char")
end)

test("special char", function()
	local ui = fresh()
	show(ui, "ec", 1)
	ui.handle("cmdline_special_char", "^", true, 1)
	equal(ui._state().lines, { "e^c" }, "inserted")
	show(ui, "ec", 1)
	equal(ui._state().lines, { "ec" }, "replaced by next show")
end)

test("literal newline in cmdline", function()
	local ui = fresh()
	show(ui, 'echo "a\nb"', 7)
	equal(ui._state().lines, { 'echo "a\0b"' }, "NL shown as NUL (^@)")
	equal(cursor_mark(ui)[3], 7, "byte offsets kept")
end)

test("block lines", function()
	local ui = fresh()
	ui.handle("cmdline_block_show", { { { 0, "lua <<EOF" } } })
	show(ui, "print(1)")
	equal(ui._state().lines, { "lua <<EOF", "print(1)" }, "block then text")
	equal(vim.api.nvim_win_get_config(ui._state().win).height, 2, "height")
	equal(vim.g.ui_cmdline_pos[1], vim.api.nvim_win_get_config(ui._state().win).row + 3, "pos row on text line")
	ui.handle("cmdline_block_append", { { 0, "print(1)" } })
	show(ui, "")
	equal(ui._state().lines, { "lua <<EOF", "print(1)", "" }, "appended")
	ui.handle("cmdline_block_hide")
	equal(ui._state().lines, { "" }, "block hidden")
end)

test("long cmdline wraps and keeps its tail visible", function()
	local ui = fresh()
	vim.o.columns = 100
	local text = "lua " .. ("x"):rep(150)
	show(ui, text)
	local win = ui._state().win
	local config = vim.api.nvim_win_get_config(win)
	local icon_width = vim.api.nvim_strwidth(LUA .. " ")
	equal(config.width, 96, "capped width")
	-- Icon (2) + text (154) + end-of-line cursor (1) = 157 cells on 96-cell rows.
	equal(config.height, 2, "height counts wrapped rows")
	truthy(vim.fn.screenpos(win, 1, #text).row ~= 0, "last char on screen")
	equal(vim.g.ui_cmdline_pos, { config.row + 3, config.col + icon_width - 96 }, "pos follows the wrapped cursor row")

	ui.handle("cmdline_pos", 0, 1)
	equal(vim.g.ui_cmdline_pos, { config.row + 2, config.col + icon_width }, "pos on the first row")
end)

test("wide block lines count their wrapped rows", function()
	local ui = fresh()
	vim.o.columns = 100
	ui.handle("cmdline_block_show", { { { 0, ("y"):rep(150) } } })
	show(ui, "ec")
	local win = ui._state().win
	local config = vim.api.nvim_win_get_config(win)
	equal(config.width, 60, "width from the text line")
	equal(config.height, 3 + 1, "block line wraps to 3 rows")
	truthy(vim.fn.screenpos(win, 1, 150).row ~= 0, "block tail on screen")
	equal(vim.g.ui_cmdline_pos[1], config.row + 1 + 4, "pos row below the wrapped block")
end)

test("height is capped and the cursor row stays visible", function()
	local ui = fresh()
	local block = {}
	for i = 1, 30 do
		block[i] = { { 0, "line " .. i } }
	end
	ui.handle("cmdline_block_show", block)
	show(ui, "ec")
	local win = ui._state().win
	local config = vim.api.nvim_win_get_config(win)
	equal(config.height, 20, "capped at half the editor")
	equal(vim.api.nvim_win_call(win, vim.fn.winsaveview).topline, 12, "scrolled to the text line")
	equal(vim.g.ui_cmdline_pos[1], config.row + 1 + 20, "pos on the bottom row")

	ui.handle("cmdline_block_hide")
	vim.o.columns = 100
	local text = ("x"):rep(3000)
	show(ui, text)
	config = vim.api.nvim_win_get_config(win)
	equal(config.height, 20, "long line capped")
	truthy(vim.fn.screenpos(win, 1, #text).row ~= 0, "last char on screen")
	equal(vim.g.ui_cmdline_pos[1], config.row + 1 + 20, "pos on the bottom row")
end)

test("nested level", function()
	local ui = fresh()
	show(ui, "ec", 2, ":", 1)
	show(ui, "1+1", 3, "=", 2)
	equal(ui._state().title, " Calculator ", "level 2 title")
	equal(ui._state().level, 2, "level 2 shown")
	ui.handle("cmdline_hide", 2, false)
	equal(ui._state().title, " Cmdline ", "level 1 title")
	equal(ui._state().lines, { "ec" }, "level 1 lines")
	truthy(ui._state().visible, "still visible")
	ui.handle("cmdline_hide", 1, false)
	truthy(not ui._state().visible, "closed")
end)

--- Highlight groups of the treesitter marks covering byte `col` of the text line.
local function groups_at(ui, col)
	local ns = vim.api.nvim_get_namespaces()["k6e.ui.text"]
	local marks = vim.api.nvim_buf_get_extmarks(ui._state().buf, ns, 0, -1, { details = true })
	local groups = {}
	for _, mark in ipairs(marks) do
		local d = mark[4]
		if d.hl_group and mark[3] <= col and col < d.end_col then
			groups[#groups + 1] = d.hl_group
		end
	end
	return groups
end

local function has(groups, pattern)
	for _, group in ipairs(groups) do
		if group:find(pattern) then
			return true
		end
	end
	return false
end

test("treesitter highlighting", function()
	local ui = fresh()
	show(ui, "lua print(1)")
	local print_groups = groups_at(ui, 4)
	truthy(has(print_groups, "^@function.*%.lua$"), "lua function capture on print: " .. vim.inspect(print_groups))
	truthy(has(groups_at(ui, 10), "^@number%.lua$"), "lua number capture: " .. vim.inspect(groups_at(ui, 10)))
	equal(groups_at(ui, 0), {}, "lua prefix not parsed as lua")

	show(ui, "=1+1")
	truthy(has(groups_at(ui, 1), "^@number%.lua$"), "= expression parsed as lua: " .. vim.inspect(groups_at(ui, 1)))
	equal(groups_at(ui, 0), {}, "= prefix not parsed")

	show(ui, "echo 1")
	truthy(has(groups_at(ui, 0), "%.vim$"), "vim capture on echo: " .. vim.inspect(groups_at(ui, 0)))

	show(ui, "!ls")
	truthy(ui._state().visible, "shell kind renders without a bash parser")

	show(ui, "x", 1, "", 1, "Name: ")
	equal(groups_at(ui, 0), {}, "no highlighting for prompt")
end)

test("attach defines highlights", function()
	local ui = fresh()
	ui.attach()
	equal(ui._attached, true, "attached")
	equal(vim.api.nvim_get_hl(0, { name = "K6eUiCursor" }).link, "Cursor", "cursor link")
	equal(vim.api.nvim_get_hl(0, { name = "K6eUiIcon" }).link, "Special", "icon link")
	ui.detach()
	equal(ui._attached, false, "detached")
end)

test("fallback on handler error", function()
	local ui = fresh()
	ui.attach()
	show(ui, "ec")
	local win = ui._state().win
	local notified = {}
	local original_notify = vim.notify
	vim.notify = function(msg, level)
		notified[#notified + 1] = { msg = msg, level = level }
	end
	ui.handle = function()
		error("boom")
	end
	local ok, err = pcall(ui._on_event, "cmdline_show", { { 0, "ec" } }, 2, ":", "", 0, 1, 0)
	vim.wait(50)
	vim.notify = original_notify
	truthy(ok, "no raise: " .. tostring(err))
	truthy(not ui._state().visible, "popup closed")
	truthy(not vim.api.nvim_win_is_valid(win), "window closed")
	equal(ui._attached, false, "detached")
	equal(#notified, 1, "one notification")
	truthy(notified[1].msg:find("falling back", 1, true), "message: " .. notified[1].msg)
	truthy(notified[1].msg:find("boom", 1, true), "error in message: " .. notified[1].msg)
	equal(notified[1].level, vim.log.levels.ERROR, "error level")
end)

test("child nvim cmdline", function()
	local sock = vim.fn.tempname() .. ".sock"
	local child = vim.fn.jobstart(
		{ vim.v.progpath, "--headless", "--embed", "-u", "NONE", "--listen", sock },
		{ rpc = true }
	)
	truthy(child > 0, "failed to start embedded Neovim")
	local ok, err = xpcall(function()
		-- The UI client sits on its own raw socket channel: an rpc channel closes
		-- when it receives the `redraw` notifications, so they are discarded here.
		vim.rpcrequest(child, "nvim_eval", "1")
		local ui_chan = vim.fn.sockconnect("pipe", sock, { on_data = function() end })
		truthy(ui_chan > 0, "failed to connect UI channel")
		vim.fn.chansend(ui_chan, vim.mpack.encode({ 0, 1, "nvim_ui_attach", { 80, 24, { ext_linegrid = true } } }))
		truthy(
			vim.wait(5000, function()
				return #vim.rpcrequest(child, "nvim_list_uis") == 1
			end, 10),
			"UI did not attach"
		)
		vim.rpcrequest(
			child,
			"nvim_exec_lua",
			[[
			local root = ...
			vim.opt.runtimepath:prepend(root)
			package.path = table.concat({ root .. "/lua/?.lua", root .. "/lua/?/init.lua", package.path }, ";")
			require("k6e.ui").attach()
		]],
			{ root }
		)
		local function state()
			return vim.rpcrequest(child, "nvim_exec_lua", "return require('k6e.ui')._state()", {})
		end
		vim.rpcnotify(child, "nvim_input", ":ec")
		truthy(
			vim.wait(5000, function()
				local s = state()
				return s.visible and vim.deep_equal(s.lines, { "ec" })
			end, 10),
			"popup not shown: " .. vim.inspect(state())
		)
		vim.rpcnotify(child, "nvim_input", "<Esc>")
		truthy(
			vim.wait(5000, function()
				return not state().visible
			end, 10),
			"popup not hidden: " .. vim.inspect(state())
		)
		equal(vim.rpcrequest(child, "nvim_exec_lua", "return require('k6e.ui')._attached", {}), true, "still attached")
	end, debug.traceback)
	vim.fn.jobstop(child)
	if not ok then
		error(err)
	end
end)

test("redirect shows command output in a scratch split", function()
	local ui = require("k6e.ui")
	ui.redirect("echo 'hi'")
	local b = vim.api.nvim_get_current_buf()
	equal(vim.bo[b].filetype, "k6e-redirect", "filetype")
	equal(vim.api.nvim_buf_get_lines(b, 0, -1, false), { "hi" }, "output lines")
	equal(vim.bo[b].buflisted, false, "not listed")
	vim.cmd("bwipeout!")
end)

--- The <S-CR> expr callback, after a fresh setup and activation.
local function shift_enter(ui)
	package.loaded["core.keymaps"] = nil
	ui.setup()
	require("core.keymaps").activate()
	local callback = vim.fn.maparg("<S-CR>", "c", false, true).callback
	ui.detach()
	truthy(type(callback) == "function", "<S-CR> mapped with a callback")
	return callback
end

--- Call `callback` as if the cmdline type were `cmdtype`; return its result and the redirected commands.
local function press(ui, callback, cmdtype)
	local redirected = {}
	local original_redirect, original_type, original_line = ui.redirect, vim.fn.getcmdtype, vim.fn.getcmdline
	ui.redirect = function(cmd)
		redirected[#redirected + 1] = cmd
	end
	vim.fn.getcmdtype = function()
		return cmdtype
	end
	vim.fn.getcmdline = function()
		return "d"
	end
	local ok, result = pcall(callback)
	vim.fn.getcmdtype, vim.fn.getcmdline = original_type, original_line
	vim.wait(20)
	ui.redirect = original_redirect
	assert(ok, result)
	return result, redirected
end

test("<S-CR> redirects only Ex cmdlines", function()
	local ui = fresh()
	local callback = shift_enter(ui)
	local result, redirected = press(ui, callback, ":")
	equal(result, "<C-c>", "Ex cmdline is cancelled")
	equal(redirected, { "d" }, "Ex cmdline redirected")
	for _, cmdtype in ipairs({ "/", "?", "@", "=" }) do
		result, redirected = press(ui, callback, cmdtype)
		equal(result, "<CR>", cmdtype .. " cmdline accepts normally")
		equal(redirected, {}, cmdtype .. " cmdline not redirected")
	end
end)

test("redirect trims blank lines around the output", function()
	local ui = require("k6e.ui")
	ui.redirect([[echo "\nhi\n"]])
	local b = vim.api.nvim_get_current_buf()
	equal(vim.api.nvim_buf_get_lines(b, 0, -1, false), { "hi" }, "leading and trailing blanks must be trimmed")
	vim.cmd("bwipeout!")
end)

test("redirect shows the error when the command fails", function()
	local ui = require("k6e.ui")
	ui.redirect("bogus_cmd")
	local b = vim.api.nvim_get_current_buf()
	equal(vim.bo[b].filetype, "k6e-redirect", "filetype")
	truthy(vim.api.nvim_buf_get_lines(b, 0, 1, false)[1]:find("E492", 1, true), "E492 expected")
	vim.cmd("bwipeout!")
end)

local failures = {}
for _, case in ipairs(tests) do
	local ok, err = pcall(case.callback)
	if not ok then
		failures[#failures + 1] = case.name .. ": " .. err
	end
end

if #failures > 0 then
	io.stderr:write(table.concat(failures, "\n") .. "\n")
	os.exit(1)
end
