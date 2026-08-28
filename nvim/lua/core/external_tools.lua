local M = {}

local names = { "lazygit", "uv", "bun", "rg", "fd", "delta" }
local snapshot

local function require_snapshot()
	if snapshot == nil then
		error("EXTERNAL_TOOLS_NOT_CAPTURED", 2)
	end
	return snapshot
end

function M.capture()
	if snapshot ~= nil then
		return
	end

	local captured = {}
	for _, name in ipairs(names) do
		local ok, result = pcall(vim.fn.executable, name)
		if not ok then
			error(("EXTERNAL_TOOL_PROBE_FAILED[%s]: %s"):format(name, result), 2)
		end
		if result ~= 0 and result ~= 1 then
			error(("EXTERNAL_TOOL_PROBE_INVALID[%s]: %s"):format(name, vim.inspect(result)), 2)
		end
		captured[name] = result == 1
	end
	snapshot = captured
end

function M.git_ui()
	return require_snapshot().lazygit and "lazygit" or "neogit"
end

function M.statuses()
	local captured = require_snapshot()
	local rows = {}
	for index, name in ipairs(names) do
		rows[index] = { name = name, available = captured[name] }
	end
	return rows
end

return M
