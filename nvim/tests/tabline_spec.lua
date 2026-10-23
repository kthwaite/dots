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

local function plain(s)
	s = s:gsub("%%#[^#]*#", "")
	s = s:gsub("%%%d*@[^@]*@", "")
	s = s:gsub("%%%d*[XT]", "")
	s = s:gsub("%%<", "")
	s = s:gsub("%%%%", "%%")
	return s
end

local run = 0

local function fresh()
	vim.cmd("silent! tabonly!")
	vim.cmd("silent! %bwipeout!")
	vim.bo.buflisted = false
	_G.Snacks = nil
	vim.o.columns = 200
	run = run + 1
	package.loaded["k6e.tabline"] = nil
	package.loaded["core.keymaps"] = nil
	local tabline = require("k6e.tabline")
	tabline.setup()
	return tabline
end

local function named(path)
	path = path:gsub("^/x/", "/x" .. run .. "/")
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, path)
	return buf
end

test("order follows creation", function()
	local t = fresh()
	local a, b, c = named("/x/a.lua"), named("/x/b.lua"), named("/x/c.lua")
	equal(t.order(), { a, b, c }, "order")
end)

test("move swaps without wrapping", function()
	local t = fresh()
	local a, b, c = named("/x/a.lua"), named("/x/b.lua"), named("/x/c.lua")
	vim.api.nvim_set_current_buf(b)
	t.move(-1)
	equal(t.order(), { b, a, c }, "moved left")
	t.move(-1)
	equal(t.order(), { b, a, c }, "unchanged at edge")
end)

test("cycle wraps", function()
	local t = fresh()
	local a, _, c = named("/x/a.lua"), named("/x/b.lua"), named("/x/c.lua")
	vim.api.nvim_set_current_buf(c)
	t.cycle(1)
	equal(vim.api.nvim_get_current_buf(), a, "wrap forward")
	t.cycle(-1)
	equal(vim.api.nvim_get_current_buf(), c, "wrap back")
end)

test("unlisted current buffer", function()
	local t = fresh()
	named("/x/a.lua")
	named("/x/b.lua")
	local scratch = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(scratch)
	local ok, out = pcall(t.render)
	truthy(ok, "render errors: " .. tostring(out))
	truthy(not out:find("K6eTablineCurrent"), "no current cell")
	t.cycle(1)
	equal(vim.api.nvim_get_current_buf(), t.order()[1], "cycle goes to first")
end)

test("names dedups tails", function()
	local t = fresh()
	local a, b, c = named("/x/a/init.lua"), named("/x/b/init.lua"), named("/x/c.lua")
	local names = t.names({ a, b, c })
	equal({ names[a], names[b], names[c] }, { "a/init.lua", "b/init.lua", "c.lua" }, "names")
end)

test("unnamed buffer", function()
	local t = fresh()
	local buf = vim.api.nvim_create_buf(true, false)
	equal(t.names({ buf })[buf], "[No Name]", "no name")
end)

test("modified marker", function()
	local t = fresh()
	local a = named("/x/a.lua")
	named("/x/b.lua")
	vim.bo[a].modified = true
	truthy(plain(t.render()):find("●", 1, true), "modified marker")
end)

test("diagnostic count", function()
	local t = fresh()
	local a = named("/x/a.lua")
	vim.api.nvim_buf_set_lines(a, 0, -1, false, { "x" })
	local ns = vim.api.nvim_create_namespace("tabline_test")
	local E = vim.diagnostic.severity.ERROR
	vim.diagnostic.set(ns, a, {
		{ lnum = 0, col = 0, severity = E, message = "e" },
		{ lnum = 0, col = 0, severity = E, message = "e" },
	})
	truthy(plain(t.render()):find("E2", 1, true), "E2")
end)

test("click handlers", function()
	local t = fresh()
	local a, b = named("/x/a.lua"), named("/x/b.lua")
	vim.api.nvim_set_current_buf(a)
	local r = t.render()
	truthy(r:find("%" .. b .. "@v:lua.K6eTablineClick@", 1, true), "click region")
	truthy(r:find("@v:lua.K6eTablineClose@×", 1, true), "close region")
	_G.K6eTablineClick(b, 1, "l", "")
	equal(vim.api.nvim_get_current_buf(), b, "left click")
	local seen
	_G.Snacks = {
		bufdelete = function(x)
			seen = x
		end,
	}
	_G.K6eTablineClick(b, 1, "m", "")
	equal(seen, b, "middle click deletes")
	seen = nil
	_G.K6eTablineClose(a, 1, "l", "")
	equal(seen, a, "close deletes")
	_G.Snacks = nil
end)

test("close falls back to bdelete", function()
	local t = fresh()
	local a = named("/x/a.lua")
	local b = named("/x/b.lua")
	vim.api.nvim_set_current_buf(a)
	_G.K6eTablineClose(b, 1, "l", "")
	equal(t.order(), { a }, "b removed")
end)

test("scroll keeps current visible", function()
	local t = fresh()
	local bufs = {}
	for i = 1, 30 do
		bufs[i] = named(string.format("/x/file%02d.lua", i))
	end
	vim.o.columns = 60
	vim.api.nvim_set_current_buf(bufs[25])
	local text = plain(t.render())
	truthy(text:find("file25.lua", 1, true), "current visible")
	truthy(text:find("‹", 1, true), "left marker")
	truthy(vim.api.nvim_strwidth(text) <= 60, "fits: " .. vim.api.nvim_strwidth(text))
end)

test("narrow columns", function()
	local t = fresh()
	local a = named("/x/" .. string.rep("n", 40) .. ".lua")
	vim.api.nvim_set_current_buf(a)
	vim.o.columns = 12
	local ok, out = pcall(t.render)
	truthy(ok, "render errors: " .. tostring(out))
	truthy(vim.api.nvim_strwidth(plain(out)) <= 12, "fits: " .. vim.api.nvim_strwidth(plain(out)))
end)

test("percent in names is escaped", function()
	local t = fresh()
	named("/x/100%.lua")
	truthy(t.render():find("100%%.lua", 1, true), "escaped")
end)

test("tabpage section", function()
	local t = fresh()
	named("/x/a.lua")
	local r = t.render()
	truthy(not r:find("%1T", 1, true) and not r:find("%2T", 1, true), "single tab")
	vim.cmd.tabnew()
	r = t.render()
	truthy(r:find("%1T", 1, true) and r:find("%2T", 1, true), "two tabs")
	vim.cmd("silent! tabonly!")
end)

test("pick", function()
	local t = fresh()
	local a, b = named("/x/a.lua"), named("/x/b.lua")
	vim.api.nvim_set_current_buf(a)
	local original = vim.fn.getcharstr
	local seen_label
	vim.fn.getcharstr = function()
		seen_label = plain(t.render()):find(" s ", 1, true) ~= nil
		return "s"
	end
	t.pick()
	equal(vim.api.nvim_get_current_buf(), b, "picked second")
	truthy(seen_label, "label shown during pick")
	vim.fn.getcharstr = function()
		return "\27"
	end
	t.pick()
	equal(vim.api.nvim_get_current_buf(), b, "esc leaves current")
	vim.fn.getcharstr = original
	truthy(not plain(t.render()):find(" a ", 1, true), "labels cleared")
end)

test("setup options", function()
	fresh()
	equal(vim.o.showtabline, 2, "showtabline")
	equal(vim.o.tabline, "%!v:lua.require'k6e.tabline'.render()", "tabline")
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
