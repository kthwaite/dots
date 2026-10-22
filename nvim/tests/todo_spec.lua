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

local function fresh()
	package.loaded["k6e.todo"] = nil
	package.loaded["core.keymaps"] = nil
	return require("k6e.todo")
end

local function draw(todo, bufnr, filetype, text)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, text)
	vim.api.nvim_set_current_buf(bufnr)
	vim.bo[bufnr].filetype = filetype
	if filetype == "lua" or filetype == "c" then
		vim.treesitter.start(bufnr, filetype)
		vim.treesitter.get_parser(bufnr, filetype):parse()
	end
	todo.setup()
	vim.api.nvim__redraw({ win = vim.api.nvim_get_current_win(), flush = true, valid = false })
end

test("match finds a plain keyword", function()
	local todo = fresh()
	local m = todo.match("-- TODO: x")
	equal(m, { kind = "Todo", kw_start = 3, kw_end = 8 }, "plain TODO")
end)

test("match covers author and colon", function()
	local todo = fresh()
	local line = "// FIXME(kit): y"
	local m = todo.match(line)
	equal(m.kind, "Fix", "kind")
	equal(line:sub(m.kw_start + 1, m.kw_end), "FIXME(kit):", "span")
end)

test("match rejects non-words and lowercase", function()
	local todo = fresh()
	equal(todo.match("TODOS: z"), nil, "TODOS")
	equal(todo.match("todo: z"), nil, "lowercase")
end)

test("rg_pattern lists keywords in table order", function()
	local todo = fresh()
	local pattern = todo.rg_pattern()
	equal(pattern:sub(1, 34), "\\b(FIX|FIXME|BUG|FIXIT|ISSUE|TODO|", "prefix")
	equal(pattern:sub(-21), "|FAILED)(\\([^)]*\\))?:", "suffix")
end)

test("provider marks keyword inside a comment only", function()
	local todo = fresh()
	local bufnr = vim.api.nvim_create_buf(false, true)
	draw(todo, bufnr, "lua", { "local a = 1 -- TODO: x", "local TODO = 1" })
	local row0, row1 = {}, {}
	for _, mark in ipairs(todo._last_marks) do
		if mark.row == 0 then
			row0[#row0 + 1] = mark
		elseif mark.row == 1 then
			row1[#row1 + 1] = mark
		end
	end
	local found = false
	for _, mark in ipairs(row0) do
		if mark.hl == "K6eTodoKwTodo" and mark.col == 15 then
			found = true
		end
	end
	truthy(found, "row 0 keyword mark at col 15: " .. vim.inspect(todo._last_marks))
	equal(#row1, 0, "row 1 has no marks")
	equal(#vim.api.nvim_buf_get_extmarks(bufnr, vim.api.nvim_create_namespace("k6e.todo"), 0, -1, {}), 0, "ephemeral")
end)

test("provider skips buffers without a parser", function()
	local todo = fresh()
	local bufnr = vim.api.nvim_create_buf(false, true)
	draw(todo, bufnr, "k6e-none", { "TODO: x" })
	equal(#todo._last_marks, 0, "no marks")
end)

test("quickfix lists matches with title Todo", function()
	local todo = fresh()
	require("core.external_tools").capture()
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	vim.fn.writefile({ "-- NOTE: n" }, dir .. "/a.lua")
	local previous = vim.fn.getcwd()
	vim.cmd.cd(dir)
	todo.quickfix()
	local list = vim.fn.getqflist({ items = true, title = true })
	vim.cmd.cd(previous)
	equal(#list.items, 1, "one item")
	truthy(list.items[1].text:find("NOTE: n", 1, true), "text")
	equal(list.title, "Todo", "title")
end)

test("match accepts a start offset", function()
	local todo = fresh()
	local line = "TODO: a NOTE: b"
	local m = todo.match(line, 5)
	equal(m.kind, "Note", "second match")
	equal(m.kw_start, 8, "second start")
end)

test("provider skips a string keyword but marks the comment one", function()
	local todo = fresh()
	local bufnr = vim.api.nvim_create_buf(false, true)
	draw(todo, bufnr, "lua", { 'local s = "TODO: x" -- NOTE: y' })
	local kw = {}
	for _, mark in ipairs(todo._last_marks) do
		if mark.hl:find("^K6eTodoKw") then
			kw[#kw + 1] = mark
		end
	end
	equal(#kw, 1, "one keyword mark: " .. vim.inspect(todo._last_marks))
	equal(kw[1].hl, "K6eTodoKwNote", "note")
	equal(kw[1].col, 23, "note col")
end)

test("text highlight stops at the comment end", function()
	local todo = fresh()
	local bufnr = vim.api.nvim_create_buf(false, true)
	draw(todo, bufnr, "c", { "/* TODO: x */ foo();" })
	local text
	for _, mark in ipairs(todo._last_marks) do
		if mark.hl == "K6eTodoTextTodo" then
			text = mark
		end
	end
	truthy(text, "text mark: " .. vim.inspect(todo._last_marks))
	equal(text.col, 8, "text start")
	equal(text.end_col, 13, "text end at comment end")
end)

test("provider skips buffers with a parser but no highlighter", function()
	local todo = fresh()
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "-- TODO: x" })
	vim.api.nvim_set_current_buf(bufnr)
	vim.bo[bufnr].filetype = "lua"
	vim.treesitter.stop(bufnr)
	todo.setup()
	vim.api.nvim__redraw({ win = vim.api.nvim_get_current_win(), flush = true, valid = false })
	equal(#todo._last_marks, 0, "no marks without highlighter")
end)

test("quickfix with no results notifies and opens nothing", function()
	local todo = fresh()
	require("core.external_tools").capture()
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	local previous = vim.fn.getcwd()
	vim.cmd.cd(dir)
	vim.fn.setqflist({}, "r")
	local messages = {}
	local original = vim.notify
	vim.notify = function(msg, level)
		messages[#messages + 1] = { msg, level }
	end
	todo.quickfix()
	vim.notify = original
	vim.cmd.cd(previous)
	equal(messages, { { "k6e.todo: no todos found", vim.log.levels.INFO } }, "notify")
	equal(#vim.fn.getqflist(), 0, "qflist untouched")
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
