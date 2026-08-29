local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(source, ":p:h:h")
vim.opt.runtimepath:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	package.path,
}, ";")

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

local fixture
local action_count = 0
local render_count = 0
package.loaded["plugins.headers.venus"] = {
	render = function()
		render_count = render_count + 1
		return fixture
	end,
}

local startscreen = require("k6e.startscreen")

local function delete_augroup()
	pcall(vim.api.nvim_del_augroup_by_name, "k6e-startscreen")
end

local function with_scratch(callback)
	local existing_buffers = {}
	local listed_buffers = {}
	for _, existing_buffer in ipairs(vim.api.nvim_list_bufs()) do
		existing_buffers[existing_buffer] = true
	end
	for _, existing_window in ipairs(vim.api.nvim_list_wins()) do
		local existing_buffer = vim.api.nvim_win_get_buf(existing_window)
		if vim.bo[existing_buffer].buflisted then
			listed_buffers[existing_buffer] = true
			vim.bo[existing_buffer].buflisted = false
		end
	end

	vim.cmd("tabnew")
	local tab = vim.api.nvim_get_current_tabpage()
	local buffer = vim.api.nvim_create_buf(true, true)
	local window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(window, buffer)

	local ok, err = xpcall(function()
		callback(buffer, window)
	end, debug.traceback)

	if vim.api.nvim_tabpage_is_valid(tab) then
		pcall(vim.api.nvim_set_current_tabpage, tab)
		pcall(vim.cmd, "tabclose!")
	end
	for _, case_buffer in ipairs(vim.api.nvim_list_bufs()) do
		if not existing_buffers[case_buffer] and vim.api.nvim_buf_is_valid(case_buffer) then
			pcall(vim.api.nvim_buf_delete, case_buffer, { force = true })
		end
	end
	for listed_buffer in pairs(listed_buffers) do
		if vim.api.nvim_buf_is_valid(listed_buffer) then
			vim.bo[listed_buffer].buflisted = true
		end
	end
	delete_augroup()

	if not ok then
		error(err)
	end
end

local function is_startscreen(buffer)
	return vim.bo[buffer].filetype == "k6e-startscreen"
end

local function default_fixture()
	return {
		type = "group",
		val = function()
			return {
				{ type = "padding", val = 1 },
				{
					type = "text",
					val = "界",
					opts = { position = "center", hl = "Title" },
				},
				{
					type = "group",
					val = function()
						return {
							{
								type = "text",
								val = "group",
								opts = {
									position = "center",
									hl = { { "ErrorMsg", 1, 4 } },
								},
							},
							{
								type = "button",
								val = "run",
								on_press = function()
									action_count = action_count + 1
								end,
								opts = { position = "center", shortcut = "r" },
							},
						}
					end,
				},
			}
		end,
	}
end

truthy(type(startscreen.setup) == "function", "setup export missing")
truthy(type(startscreen.start) == "function", "start export missing")
truthy(type(startscreen.redraw) == "function", "redraw export missing")

fixture = default_fixture()
with_scratch(function(buffer, window)
	startscreen.start(false)

	equal(vim.bo[buffer].buftype, "nofile", "startscreen buftype changed")
	equal(vim.bo[buffer].bufhidden, "wipe", "startscreen bufhidden changed")
	equal(vim.bo[buffer].swapfile, false, "startscreen swapfile changed")
	equal(vim.bo[buffer].buflisted, false, "startscreen buffer remained listed")
	equal(vim.bo[buffer].modifiable, false, "startscreen buffer remained modifiable")
	equal(vim.bo[buffer].filetype, "k6e-startscreen", "startscreen filetype changed")
	equal(vim.wo[window].number, false, "startscreen window shows line numbers")
	equal(vim.wo[window].relativenumber, false, "startscreen window shows relative line numbers")
	equal(vim.wo[window].signcolumn, "no", "startscreen window shows sign column")
	equal(vim.wo[window].foldcolumn, "0", "startscreen window shows fold column")
end)

fixture = default_fixture()
action_count = 0
with_scratch(function(buffer, window)
	startscreen.start(false)

	local width = vim.api.nvim_win_get_width(window)
	local height = vim.api.nvim_win_get_height(window)
	local top_padding = math.max(0, math.floor((height - 4) / 2))
	local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
	local expected = {}
	for _ = 1, top_padding + 1 do
		expected[#expected + 1] = ""
	end
	expected[#expected + 1] = string.rep(" ", math.max(0, math.floor((width - 2) / 2))) .. "界"
	expected[#expected + 1] = string.rep(" ", math.max(0, math.floor((width - 5) / 2))) .. "group"
	expected[#expected + 1] = string.rep(" ", math.max(0, math.floor((width - 3) / 2))) .. "run"
	equal(lines, expected, "layout order or centering changed")

	local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
	local highlights = {}
	for _, mark in ipairs(extmarks) do
		local details = mark[4]
		if details.hl_group then
			highlights[#highlights + 1] = {
				row = mark[2],
				column = mark[3],
				end_column = details.end_col,
				hl_group = details.hl_group,
			}
		end
	end
	table.sort(highlights, function(left, right)
		return left.row < right.row
	end)
	equal(highlights, {
		{
			row = top_padding + 1,
			column = math.max(0, math.floor((width - 2) / 2)),
			end_column = math.max(0, math.floor((width - 2) / 2)) + #"界",
			hl_group = "Title",
		},
		{
			row = top_padding + 2,
			column = math.max(0, math.floor((width - 5) / 2)) + 1,
			end_column = math.max(0, math.floor((width - 5) / 2)) + 4,
			hl_group = "ErrorMsg",
		},
	}, "string or range highlights changed")

	local button_row = top_padding + 3
	vim.api.nvim_win_set_cursor(window, { button_row + 1, 0 })
	vim.api.nvim_feedkeys("r", "x", false)
	vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
	equal(action_count, 2, "button shortcut or <CR> mapping did not invoke its action")
end)

fixture = default_fixture()
action_count = 0
with_scratch(function(buffer)
	startscreen.start(false)
	fixture = {
		type = "group",
		val = {
			{
				type = "button",
				val = "save",
				on_press = function()
					action_count = action_count + 10
				end,
				opts = { shortcut = "s", hl = "Identifier" },
			},
			{
				type = "button",
				val = "open",
				on_press = function()
					action_count = action_count + 1
				end,
				opts = { shortcut = "o" },
			},
		},
	}
	local original_set_lines = vim.api.nvim_buf_set_lines
	local target_mutations = 0
	vim.api.nvim_buf_set_lines = function(target, ...)
		if target == buffer then
			target_mutations = target_mutations + 1
		end
		return original_set_lines(target, ...)
	end
	local ok, err = xpcall(startscreen.redraw, debug.traceback)
	vim.api.nvim_buf_set_lines = original_set_lines
	if not ok then
		error(err)
	end
	equal(target_mutations, 1, "redraw did not use exactly one target-buffer line mutation")
	vim.api.nvim_feedkeys("r", "x", false)
	equal(action_count, 0, "redraw left a stale button shortcut")
	vim.api.nvim_feedkeys("s", "x", false)
	equal(action_count, 10, "redraw did not install the current button shortcut")
	vim.api.nvim_feedkeys("o", "x", false)
	equal(action_count, 11, "button shortcuts invoked the wrong configured action")
	local text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
	equal(text:match("save\nopen$"), "save\nopen", "redraw did not rebuild layout")

	local extmarks = vim.api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })
	local highlight_groups = {}
	for _, mark in ipairs(extmarks) do
		if mark[4].hl_group then
			highlight_groups[#highlight_groups + 1] = mark[4].hl_group
		end
	end
	equal(highlight_groups, { "Identifier" }, "redraw retained stale namespace highlights")
end)

local original_argc = vim.fn.argc
local original_v = vim.v
local function with_startup_inputs(argc, argv, callback)
	vim.fn.argc = function()
		return argc
	end
	vim.v = { argv = argv }
	local ok, err = xpcall(callback, debug.traceback)
	vim.fn.argc = original_argc
	vim.v = original_v
	if not ok then
		error(err)
	end
end

fixture = default_fixture()
with_scratch(function(buffer)
	with_startup_inputs(1, { "nvim", "file" }, function()
		startscreen.start(true)
	end)
	equal(is_startscreen(buffer), false, "startup ignored argc")
end)

fixture = default_fixture()
with_scratch(function(buffer)
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "content" })
	with_startup_inputs(0, { "nvim" }, function()
		startscreen.start(true)
	end)
	equal(is_startscreen(buffer), false, "startup replaced non-empty content")
end)

fixture = default_fixture()
with_scratch(function(buffer)
	vim.bo[buffer].modifiable = false
	with_startup_inputs(0, { "nvim" }, function()
		startscreen.start(true)
	end)
	equal(is_startscreen(buffer), false, "startup replaced a non-modifiable buffer")
	vim.bo[buffer].modifiable = true
end)

fixture = default_fixture()
with_scratch(function(buffer)
	vim.cmd("vsplit")
	local other = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(0, other)
	vim.cmd("wincmd p")
	with_startup_inputs(0, { "nvim" }, function()
		startscreen.start(true)
	end)
	equal(is_startscreen(buffer), false, "startup ignored another displayed listed buffer")
end)

for _, argument in ipairs({ "-b", "-c", "+Oil", "-S" }) do
	fixture = default_fixture()
	with_scratch(function(buffer)
		with_startup_inputs(0, { "nvim", argument }, function()
			startscreen.start(true)
		end)
		equal(is_startscreen(buffer), false, ("startup ignored %s"):format(argument))
	end)
end

fixture = default_fixture()
with_scratch(function(buffer)
	with_startup_inputs(0, { "nvim", "--startuptime", "/tmp/startup.log" }, function()
		startscreen.start(true)
	end)
	equal(is_startscreen(buffer), true, "--startuptime incorrectly disabled the startscreen")
end)

fixture = default_fixture()
with_scratch(function(buffer)
	with_startup_inputs(0, { "nvim", "--startuptime", "-c" }, function()
		startscreen.start(true)
	end)
	equal(is_startscreen(buffer), false, "startup ignored a blocked argument after --startuptime")
end)

fixture = default_fixture()
with_scratch(function()
	startscreen.setup()
	local nested_calls = 0
	local probe = vim.api.nvim_create_augroup("k6e-startscreen-nested-probe", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = probe,
		pattern = "k6e-startscreen",
		callback = function()
			nested_calls = nested_calls + 1
		end,
	})
	local ok, err = xpcall(function()
		with_startup_inputs(0, { "nvim" }, function()
			vim.api.nvim_exec_autocmds("VimEnter", {})
		end)
	end, debug.traceback)
	vim.api.nvim_del_augroup_by_id(probe)
	if not ok then
		error(err)
	end
	equal(nested_calls, 1, "VimEnter autocmd did not permit nested FileType behavior")
end)

fixture = default_fixture()
with_scratch(function(buffer, window)
	startscreen.setup()
	vim.wo[window].colorcolumn = "81,101"

	startscreen.start(false)
	equal(vim.wo[window].colorcolumn, "", "startscreen retained the window color column")

	startscreen.start(false)
	equal(vim.wo[window].colorcolumn, "", "startscreen re-entry changed the hidden color column")

	local replacement = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(window, replacement)
	equal(vim.wo[window].colorcolumn, "81,101", "wiping the startscreen did not restore the color column")
	equal(vim.api.nvim_buf_is_valid(buffer), false, "leaving the startscreen did not wipe its buffer")
end)

fixture = default_fixture()
with_scratch(function(buffer, window)
	startscreen.setup()
	vim.wo[window].colorcolumn = "72,+1"
	startscreen.start(false)
	vim.bo[buffer].bufhidden = ""

	local replacement = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(window, replacement)
	equal(vim.wo[window].colorcolumn, "72,+1", "leaving the startscreen did not restore the color column")

	vim.api.nvim_win_set_buf(window, buffer)
	vim.wo[window].colorcolumn = "90,+3"
	startscreen.start(false)
	equal(vim.wo[window].colorcolumn, "", "a new startscreen lifecycle retained the replacement color column")

	startscreen.redraw()
	equal(vim.wo[window].colorcolumn, "", "redraw changed the hidden color column")

	vim.bo[buffer].bufhidden = ""
	local final_buffer = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(window, final_buffer)
	equal(vim.wo[window].colorcolumn, "90,+3", "a new startscreen lifecycle did not restore its color column")

	vim.wo[window].colorcolumn = "99"
	vim.api.nvim_buf_delete(buffer, { force = true })
	equal(vim.wo[window].colorcolumn, "99", "later startscreen cleanup restored a stale color column")
end)

fixture = default_fixture()
with_scratch(function(buffer, window)
	startscreen.setup()
	vim.wo[window].colorcolumn = "88"
	startscreen.start(false)

	vim.cmd("vsplit")
	local remaining_window
	for _, candidate in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if candidate ~= window then
			remaining_window = candidate
			break
		end
	end
	truthy(remaining_window ~= nil, "split did not create a second startscreen window")
	vim.api.nvim_set_current_win(remaining_window)
	vim.api.nvim_win_close(window, true)
	equal(vim.api.nvim_win_is_valid(window), false, "tracked startscreen window remained valid")

	local ok, err = xpcall(function()
		vim.api.nvim_buf_delete(buffer, { force = true })
	end, debug.traceback)
	truthy(ok, "cleanup failed after the tracked startscreen window closed: " .. tostring(err))
end)

local dynamic_count = 0
fixture = {
	type = "group",
	val = function()
		dynamic_count = dynamic_count + 1
		return { { type = "text", val = ("dynamic-%d"):format(dynamic_count) } }
	end,
}
with_scratch(function(buffer)
	startscreen.setup()
	startscreen.setup()

	local expected_events = {
		BufLeave = 1,
		BufWipeout = 1,
		DirChanged = 1,
		VimEnter = 1,
		VimResized = 1,
	}
	local actual_events = {}
	for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = "k6e-startscreen" })) do
		actual_events[autocmd.event] = (actual_events[autocmd.event] or 0) + 1
	end
	equal(actual_events, expected_events, "setup was not idempotent")

	render_count = 0
	dynamic_count = 0
	startscreen.start(false)
	equal({ render_count, dynamic_count }, { 1, 1 }, "initial dynamic layout was not built once")

	vim.api.nvim_exec_autocmds("VimResized", {})
	equal({ render_count, dynamic_count }, { 2, 2 }, "VimResized did not redraw and rebuild dynamic layout")

	vim.api.nvim_exec_autocmds("DirChanged", {})
	equal({ render_count, dynamic_count }, { 3, 3 }, "DirChanged did not rebuild dynamic layout and redraw")

	vim.api.nvim_buf_delete(buffer, { force = true })
	render_count = 0
	local original_buf_is_valid = vim.api.nvim_buf_is_valid
	local wiped_buffer_checks = 0
	vim.api.nvim_buf_is_valid = function(target)
		if target == buffer then
			wiped_buffer_checks = wiped_buffer_checks + 1
		end
		return original_buf_is_valid(target)
	end
	local ok, err = xpcall(startscreen.redraw, debug.traceback)
	vim.api.nvim_buf_is_valid = original_buf_is_valid
	truthy(ok, "redraw retained wiped startscreen state: " .. tostring(err))
	equal(wiped_buffer_checks, 0, "redraw still inspected state for a wiped startscreen buffer")
	equal(render_count, 0, "redraw rendered state after its startscreen buffer was wiped")
end)

local cwd = "/home/test/project"
local oldfiles = {
	"/home/test/outside.txt",
	cwd .. "/src/a.lua",
	cwd .. "/COMMIT_EDITMSG",
	cwd .. "/src/missing.lua",
	cwd .. "/src/a.lua",
	cwd .. "/src/b.lua",
	cwd .. "/src/rebase.gitcommit",
	cwd .. "/src/c.lua",
	cwd .. "/src/d.lua",
	cwd .. "/src/e.lua",
	cwd .. "/src/f.lua",
	cwd .. "/src/g.lua",
	cwd .. "/src/h.lua",
	cwd .. "/src/i.lua",
	cwd .. "/src/j.lua",
	cwd .. "/src/k.lua",
}

local function configure_production_adapters(load_icon_provider, oldfiles_adapter)
	startscreen._test.oldfiles = oldfiles_adapter or function()
		return oldfiles
	end
	startscreen._test.filereadable = function(path)
		return path ~= cwd .. "/src/missing.lua"
	end
	startscreen._test.getcwd = function()
		return cwd
	end
	startscreen._test.fnamemodify = function(path, modifier)
		if modifier == ":~" then
			return path:gsub("^/home/test", "~")
		end
		if modifier == ":." then
			return path:gsub("^" .. vim.pesc(cwd .. "/"), "")
		end
		error("unexpected modifier: " .. modifier)
	end
	startscreen._test.load_icon_provider = load_icon_provider
	startscreen.setup()
	vim.api.nvim_exec_autocmds("DirChanged", {})
end

local function nonempty_lines(buffer)
	local result = {}
	for _, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)) do
		line = vim.trim(line)
		if line ~= "" then
			result[#result + 1] = line
		end
	end
	return result
end

local function row_start(buffer, text)
	for _, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)) do
		local column = line:find(text, 1, true)
		if column then
			return column - 1
		end
	end
	error("missing rendered row: " .. text)
end

local function row_highlights(buffer, text)
	local row
	local left
	for index, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)) do
		local column = line:find(text, 1, true)
		if column then
			row = index - 1
			left = column - 1
			break
		end
	end
	truthy(row ~= nil, "missing rendered row: " .. text)

	local result = {}
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buffer, -1, { row, 0 }, { row, -1 }, { details = true })) do
		if mark[4].hl_group then
			result[#result + 1] = {
				group = mark[4].hl_group,
				start_col = mark[3] - left,
				end_col = mark[4].end_col - left,
			}
		end
	end
	table.sort(result, function(left_mark, right_mark)
		return left_mark.start_col < right_mark.start_col
	end)
	return result
end

fixture = { type = "text", val = "VENUS" }
configure_production_adapters(function(name)
	if name == "mini.icons" then
		return {
			get = function()
				return "M", "MiniIcon"
			end,
		}
	end
end)
with_scratch(function(buffer)
	startscreen.setup()
	startscreen.start(false)

	local version = vim.version()
	equal(nonempty_lines(buffer), {
		"VENUS",
		("NVIM v%d.%d.%d"):format(version.major, version.minor, version.patch),
		"[e] New file",
		"MRU",
		"[10] M  ~/outside.txt",
		"[11] M  ~/project/src/a.lua",
		"[12] M  ~/project/src/b.lua",
		"[13] M  ~/project/src/c.lua",
		"[14] M  ~/project/src/d.lua",
		"[15] M  ~/project/src/e.lua",
		"[16] M  ~/project/src/f.lua",
		"[17] M  ~/project/src/g.lua",
		"[18] M  ~/project/src/h.lua",
		"[19] M  ~/project/src/i.lua",
		"MRU ~/project",
		"[0] M  src/a.lua",
		"[1] M  src/b.lua",
		"[2] M  src/c.lua",
		"[3] M  src/d.lua",
		"[4] M  src/e.lua",
		"[5] M  src/f.lua",
		"[6] M  src/g.lua",
		"[7] M  src/h.lua",
		"[8] M  src/i.lua",
		"[9] M  src/j.lua",
		"[q] Quit",
	}, "production layout, filtering, numbering, shortening, or section limits changed")

	equal({
		row_start(buffer, "MRU"),
		row_start(buffer, "[10] M  ~/outside.txt"),
		row_start(buffer, "MRU ~/project"),
		row_start(buffer, "[0] M  src/a.lua"),
	}, { 0, 0, 0, 0 }, "global and cwd MRU sections did not share the normal left edge")

	equal(row_highlights(buffer, "[11] M  ~/project/src/a.lua"), {
		{ group = "Operator", start_col = 0, end_col = 1 },
		{ group = "Number", start_col = 1, end_col = 3 },
		{ group = "Operator", start_col = 3, end_col = 4 },
		{ group = "MiniIcon", start_col = 5, end_col = 6 },
		{ group = "Comment", start_col = 8, end_col = 22 },
	}, "file button shortcut, icon, or directory highlights changed")

	local commands = {}
	local original_replace_termcodes = vim.api.nvim_replace_termcodes
	vim.api.nvim_replace_termcodes = function(keys)
		commands[#commands + 1] = keys
		return ""
	end
	local ok, err = xpcall(function()
		vim.api.nvim_feedkeys("e", "x", false)
		vim.api.nvim_feedkeys("q", "x", false)
	end, debug.traceback)
	vim.api.nvim_replace_termcodes = original_replace_termcodes
	if not ok then
		error(err)
	end
	equal(commands, { "<cmd>ene <CR><Ignore>", "<cmd>q <CR><Ignore>" }, "New file or Quit command changed")
end)

local child = vim.fn.jobstart({ vim.v.progpath, "--headless", "--embed", "-u", "NONE" }, { rpc = true })
truthy(child > 0, "failed to start embedded Neovim for mapping behavior")
local child_tmp = vim.uv.fs_realpath("/tmp") or "/tmp"
local child_ok, child_err = xpcall(function()
	vim.rpcrequest(
		child,
		"nvim_exec_lua",
		[[
		local root = ...
		vim.opt.runtimepath:prepend(root)
		package.path = table.concat({
			root .. "/lua/?.lua",
			root .. "/lua/?/init.lua",
			package.path,
		}, ";")
		package.loaded["plugins.headers.venus"] = {
			render = function()
				return { type = "text", val = "VENUS" }
			end,
		}

		local startscreen = require("k6e.startscreen")
		local cwd = "/tmp/startscreen-project"
		startscreen._test.oldfiles = function()
			return {
				"/tmp/startscreen-global.txt",
				cwd .. "/a.lua",
				cwd .. "/b.lua",
			}
		end
		startscreen._test.filereadable = function()
			return true
		end
		startscreen._test.getcwd = function()
			return cwd
		end
		startscreen._test.fnamemodify = function(path)
			return path
		end
		startscreen._test.load_icon_provider = function()
			return nil
		end
		vim.o.timeoutlen = 200
		startscreen.setup()
		startscreen.start(false)
		_G.restart_startscreen_mapping_test = function()
			vim.cmd("enew")
			startscreen.start(false)
		end
	]],
		{ root }
	)

	local function child_buffer_is(path)
		return vim.rpcrequest(child, "nvim_buf_get_name", 0) == path
	end

	vim.rpcnotify(child, "nvim_input", "1")
	vim.wait(5)
	vim.rpcnotify(child, "nvim_input", "0")
	local selected_global = vim.wait(500, function()
		return child_buffer_is(child_tmp .. "/startscreen-global.txt")
	end, 5)
	truthy(
		selected_global,
		"separate user inputs 1 then 0 selected "
			.. vim.rpcrequest(child, "nvim_buf_get_name", 0)
			.. " instead of global MRU item 10"
	)

	vim.rpcrequest(child, "nvim_exec_lua", "_G.restart_startscreen_mapping_test()", {})
	vim.rpcnotify(child, "nvim_input", "1")
	local selected_cwd = vim.wait(500, function()
		return child_buffer_is("/tmp/startscreen-project/b.lua")
	end, 5)
	truthy(
		selected_cwd,
		"lone user input 1 selected "
			.. vim.rpcrequest(child, "nvim_buf_get_name", 0)
			.. " instead of cwd MRU item 1 after mapping timeout"
	)
end, debug.traceback)
vim.fn.jobstop(child)
if not child_ok then
	error(child_err)
end

local provider_attempts = {}
configure_production_adapters(function(name)
	provider_attempts[#provider_attempts + 1] = name
	if name == "nvim-web-devicons" then
		return {
			get_icon = function()
				return "D", "DevIcon"
			end,
		}
	end
end, function()
	return { "/home/test/outside.txt" }
end)
with_scratch(function(buffer)
	startscreen.start(false)
	equal(provider_attempts, { "mini.icons", "nvim-web-devicons" }, "icon provider fallback order changed")
	truthy(vim.tbl_contains(nonempty_lines(buffer), "[10] D  ~/outside.txt"), "devicons fallback did not render")
end)

configure_production_adapters(function()
	return nil
end, function()
	return { "/home/test/outside.txt" }
end)
with_scratch(function(buffer)
	startscreen.start(false)
	truthy(
		vim.tbl_contains(nonempty_lines(buffer), "[10] ~/outside.txt"),
		"missing icon providers removed or padded the MRU entry"
	)
end)

local oldfiles_calls = 0
configure_production_adapters(function()
	return nil
end, function()
	oldfiles_calls = oldfiles_calls + 1
	return { "/home/test/outside.txt", cwd .. "/src/a.lua" }
end)
with_scratch(function()
	startscreen.start(false)
	equal(oldfiles_calls, 2, "initial global and cwd MRU lists were not built")
	startscreen.redraw()
	equal(oldfiles_calls, 2, "redraw did not reuse the MRU cache")
	vim.api.nvim_exec_autocmds("DirChanged", {})
	equal(oldfiles_calls, 4, "DirChanged did not invalidate both MRU cache entries before redraw")
end)
