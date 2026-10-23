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

local uv = vim.uv
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/lazy/snacks.nvim/lua/snacks", "p")
vim.fn.writefile({ "return {}" }, tmp .. "/lazy/snacks.nvim/lua/snacks/init.lua")
package.loaded["lazy.core.config"] = {
	options = { root = tmp .. "/lazy" },
	plugins = { snacks = { dir = tmp .. "/lazy/snacks.nvim" } },
}
package.loaded["k6e.luadev"] = nil
local luadev = require("k6e.luadev")
local snacks_lua = tmp .. "/lazy/snacks.nvim/lua"

test("scan keeps unique third-party top-level modules", function()
	equal(
		luadev.scan({
			'local s = require("snacks.picker")',
			"---@module 'snacks'",
			'require "core.keymaps"',
			"require('vim.lsp')",
		}),
		{ "snacks" },
		"scan result"
	)
end)

test("resolve finds plugin lua dir", function()
	equal(luadev.resolve("snacks"), snacks_lua, "snacks dir")
	equal(luadev.resolve("nope"), nil, "unknown module")
end)

test("is_active", function()
	truthy(luadev.is_active(vim.fn.stdpath("config")), "config root")
	truthy(luadev.is_active(tmp .. "/lazy/snacks.nvim"), "plugin root")
	truthy(not luadev.is_active(tmp), "other root")
	truthy(not luadev.is_active(nil), "nil root")
	truthy(not luadev.is_active(""), "empty root")
end)

test("is_active follows symlinked config root", function()
	local real = uv.fs_realpath(vim.fn.stdpath("config"))
	uv.fs_symlink(real, tmp .. "/cfg")
	truthy(luadev.is_active(tmp .. "/cfg"), "symlink root")
end)

local function lua_buf(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	return buf
end

test("library lists runtime, luv and resolved dirs", function()
	local buf = lua_buf({ 'local s = require("snacks")' })
	local lib = luadev.library({ buf })
	equal(lib[1], vim.env.VIMRUNTIME, "runtime first")
	equal(lib[2], "${3rd}/luv/library", "luv second")
	truthy(vim.tbl_contains(lib, snacks_lua), "snacks dir present")
end)

test("_refresh notifies only on change", function()
	local buf = lua_buf({ 'local s = require("snacks")' })
	local calls = {}
	local client = {
		name = "lua_ls",
		root_dir = vim.fn.stdpath("config"),
		settings = { Lua = { workspace = { library = {} } } },
		notify = function(_, method, params)
			calls[#calls + 1] = { method, params }
		end,
	}
	luadev._refresh(client, { buf })
	luadev._refresh(client, { buf })
	equal(#calls, 1, "notify count")
	equal(calls[1][1], "workspace/didChangeConfiguration", "method")
	truthy(vim.tbl_contains(client.settings.Lua.workspace.library, snacks_lua), "library updated")
end)

test("_refresh creates missing settings tables", function()
	local buf = lua_buf({})
	local n = 0
	local client = {
		name = "lua_ls",
		root_dir = vim.fn.stdpath("config"),
		settings = {},
		notify = function()
			n = n + 1
		end,
	}
	luadev._refresh(client, { buf })
	equal(n, 1, "notify count")
	equal(client.settings.Lua.workspace.library[1], vim.env.VIMRUNTIME, "library set")
end)

test("_refresh ignores inactive roots", function()
	local n = 0
	local client = {
		name = "lua_ls",
		root_dir = tmp,
		settings = {},
		notify = function()
			n = n + 1
		end,
	}
	luadev._refresh(client, { lua_buf({}) })
	equal(n, 0, "no notify")
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
