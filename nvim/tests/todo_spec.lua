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
	if filetype == "lua" then
		vim.treesitter.start(bufnr, "lua")
		vim.treesitter.get_parser(bufnr, "lua"):parse()
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
