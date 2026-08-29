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
package.loaded["plugins.headers.venus"] = {
	render = function()
		return fixture
	end,
}

local startscreen = require("k6e.startscreen")

local function delete_augroup()
	pcall(vim.api.nvim_del_augroup_by_name, "k6e-startscreen")
end

local function with_scratch(callback)
	local listed_buffers = {}
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
		vim.api.nvim_set_current_tabpage(tab)
		vim.cmd("tabclose!")
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
				opts = { shortcut = "s" },
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
	startscreen.redraw()
	vim.api.nvim_feedkeys("r", "x", false)
	equal(action_count, 0, "redraw left a stale button shortcut")
	vim.api.nvim_feedkeys("s", "x", false)
	equal(action_count, 10, "redraw did not install the current button shortcut")
	vim.api.nvim_feedkeys("o", "x", false)
	equal(action_count, 11, "button shortcuts invoked the wrong configured action")
	local text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
	equal(text:match("save\nopen$"), "save\nopen", "redraw did not rebuild layout")
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
with_scratch(function(buffer)
	startscreen.setup()
	startscreen.setup()

	local expected_events = {
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

	startscreen.start(false)
	vim.api.nvim_buf_delete(buffer, { force = true })
	local ok, err = pcall(startscreen.redraw)
	truthy(ok, "redraw retained wiped startscreen state: " .. tostring(err))
end)
