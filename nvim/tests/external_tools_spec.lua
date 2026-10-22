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

local function fails_with(callback, expected, message)
	local ok, err = pcall(callback)
	if ok or not tostring(err):find(expected, 1, true) then
		error(string.format("%s\nexpected error containing: %s\nactual: %s", message, expected, tostring(err)))
	end
end

local original_executable = vim.fn.executable
local function reset_scenario()
	vim.fn.executable = original_executable
	package.loaded["core.external_tools"] = nil
end

local function isolated(name, callback)
	test(name, function()
		reset_scenario()
		local ok, err = xpcall(callback, debug.traceback)
		reset_scenario()
		if not ok then
			error(err)
		end
	end)
end

isolated("requires capture before reads", function()
	fails_with(function()
		require("core.external_tools").git_ui()
	end, "EXTERNAL_TOOLS_NOT_CAPTURED", "Git UI read must require capture")

	fails_with(function()
		require("core.external_tools").statuses()
	end, "EXTERNAL_TOOLS_NOT_CAPTURED", "status read must require capture")
end)

isolated("captures tools in order and prefers LazyGit", function()
	local calls = {}
	local available = { lazygit = true, rg = true }
	vim.fn.executable = function(name)
		calls[#calls + 1] = name
		return available[name] and 1 or 0
	end

	local tools = require("core.external_tools")
	tools.capture()

	equal(calls, { "lazygit", "uv", "bun", "rg", "fd", "delta" }, "capture order")
	equal(tools.git_ui(), "lazygit", "lazygit must be preferred")
end)

isolated("falls back to Neogit when LazyGit is absent", function()
	vim.fn.executable = function()
		return 0
	end

	local tools = require("core.external_tools")
	tools.capture()

	equal(tools.git_ui(), "neogit", "missing lazygit must select neogit")
end)

isolated("keeps reads stable after the adapter changes", function()
	local available = { lazygit = true, uv = true }
	vim.fn.executable = function(name)
		return available[name] and 1 or 0
	end

	local tools = require("core.external_tools")
	tools.capture()
	available.lazygit = false
	available.uv = false
	available.bun = true

	equal(tools.git_ui(), "lazygit", "Git UI must read the captured snapshot")
	equal(tools.statuses(), {
		{ name = "lazygit", available = true },
		{ name = "uv", available = true },
		{ name = "bun", available = false },
		{ name = "rg", available = false },
		{ name = "fd", available = false },
		{ name = "delta", available = false },
	}, "status reads must not re-probe")
end)

isolated("makes repeated successful capture a no-op", function()
	local calls = 0
	vim.fn.executable = function()
		calls = calls + 1
		return 0
	end

	local tools = require("core.external_tools")
	tools.capture()
	tools.capture()

	equal(calls, 6, "second capture must not probe")
end)

isolated("returns all ordered tool statuses", function()
	local available = { lazygit = true, bun = true, fd = true }
	vim.fn.executable = function(name)
		return available[name] and 1 or 0
	end

	local tools = require("core.external_tools")
	tools.capture()

	equal(tools.statuses(), {
		{ name = "lazygit", available = true },
		{ name = "uv", available = false },
		{ name = "bun", available = true },
		{ name = "rg", available = false },
		{ name = "fd", available = true },
		{ name = "delta", available = false },
	}, "statuses must preserve the public tool order")
end)

isolated("does not leak mutable status rows", function()
	vim.fn.executable = function(name)
		return name == "rg" and 1 or 0
	end

	local tools = require("core.external_tools")
	tools.capture()
	local rows = tools.statuses()
	rows[1].name = "changed"
	rows[4].available = false
	table.remove(rows, 6)

	equal(tools.statuses(), {
		{ name = "lazygit", available = false },
		{ name = "uv", available = false },
		{ name = "bun", available = false },
		{ name = "rg", available = true },
		{ name = "fd", available = false },
		{ name = "delta", available = false },
	}, "callers must receive fresh status rows")
end)

isolated("reports probe errors without publishing a snapshot", function()
	vim.fn.executable = function(name)
		if name == "bun" then
			error("probe exploded")
		end
		return 0
	end

	local tools = require("core.external_tools")
	fails_with(tools.capture, "EXTERNAL_TOOL_PROBE_FAILED[bun]", "probe errors must name the failing tool")
	fails_with(tools.statuses, "EXTERNAL_TOOLS_NOT_CAPTURED", "failed probes must not publish partial state")
end)

isolated("rejects invalid probe results without publishing a snapshot", function()
	vim.fn.executable = function(name)
		return name == "rg" and 2 or 0
	end

	local tools = require("core.external_tools")
	fails_with(tools.capture, "EXTERNAL_TOOL_PROBE_INVALID[rg]", "invalid probe results must name the failing tool")
	fails_with(tools.git_ui, "EXTERNAL_TOOLS_NOT_CAPTURED", "invalid probes must not publish partial state")
end)

isolated("retries successfully after a failed capture", function()
	local should_fail = true
	vim.fn.executable = function(name)
		if should_fail and name == "uv" then
			error("temporary failure")
		end
		return name == "lazygit" and 1 or 0
	end

	local tools = require("core.external_tools")
	fails_with(tools.capture, "EXTERNAL_TOOL_PROBE_FAILED[uv]", "first capture must expose the probe failure")
	should_fail = false
	tools.capture()

	equal(tools.git_ui(), "lazygit", "a later successful capture must publish its snapshot")
	truthy(#tools.statuses() == 6, "successful retry must publish every status")
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
