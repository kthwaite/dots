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

local function truthy(value, message)
	if not value then
		error(message)
	end
end

local which_key_dir = root .. "/vendor/which-key.nvim"

test("vendored which-key loads from the vendor tree", function()
	vim.opt.runtimepath:prepend(which_key_dir)
	local ok, which_key = pcall(require, "which-key")
	truthy(ok, "require('which-key') failed: " .. tostring(which_key))
	truthy(type(which_key.show) == "function", "which-key.show must be a function")
end)

test("vendored which-key keeps its LICENSE", function()
	truthy(vim.fn.filereadable(which_key_dir .. "/LICENSE") == 1, "LICENSE is not readable")
end)

test("VENDORED.md records a 40-hex commit SHA", function()
	local path = which_key_dir .. "/VENDORED.md"
	truthy(vim.fn.filereadable(path) == 1, "VENDORED.md is not readable")
	local text = table.concat(vim.fn.readfile(path), "\n")
	truthy(
		text:match("%f[%x]%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%f[%X]"),
		"no 40-hex SHA in VENDORED.md"
	)
end)

local failures = {}
for _, case in ipairs(tests) do
	local ok, err = pcall(case.callback)
	if not ok then
		failures[#failures + 1] = string.format("FAIL %s\n%s", case.name, err)
	end
end

if #failures > 0 then
	error(table.concat(failures, "\n"))
end
