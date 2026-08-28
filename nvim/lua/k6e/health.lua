local M = {}
local external_tools = require("core.external_tools")

local tool_presentation = {
	lazygit = { label = "lazygit", hint = "Git TUI (brew install lazygit)" },
	uv = { label = "uv", hint = "Python package manager (brew install uv)" },
	bun = { label = "bun", hint = "JS runtime/bundler (brew install bun)" },
	rg = { label = "ripgrep", hint = "Fast grep (brew install ripgrep)" },
	fd = { label = "fd", hint = "Fast find (brew install fd)" },
	delta = { label = "delta", hint = "Git diff pager (brew install git-delta)" },
}

-- Helper function to count the number of buffers attached to a given LSP client
-- @param client table vim.LSP.Client or nil
local function _count_buffers(client)
	local buffers = client and client.attached_buffers or {}
	local count = 0
	for _ in pairs(buffers) do
		count = count + 1
	end
	return count
end

M.check = function()
	vim.health.start("k6e")
	local version = vim.version()
	local version_line = "UNKNOWN"
	if version ~= nil then
		version_line = ("v%d.%d.%d"):format(version.major, version.minor, version.patch)
	end
	vim.health.info("NVIM version " .. version_line)
	local uv = vim.uv or vim.loop
	vim.health.info("System Information: " .. vim.inspect(uv.os_uname()))

	if vim.fn.has("nvim-0.12") == 0 then
		vim.health.warn("nvim version is < v0.12.0")
	else
		vim.health.ok("nvim version is >= v0.12.0")
	end

	-- Check extra plugins
	vim.health.start("k6e: plugins")
	local ok_lazy, lazy_load = pcall(require, "core.02_lazy")
	if not ok_lazy then
		vim.health.error("require('core.02_lazy') failed")
	else
		local extra_plugins = lazy_load.extra_plugins
		if extra_plugins ~= nil and #extra_plugins > 0 then
			vim.health.info("Extra plugins loaded:")
			for _, plugin in pairs(extra_plugins) do
				vim.health.info("  " .. plugin)
			end
		else
			vim.health.info("No extra plugins loaded")
		end
	end

	-- Check LSP clients
	vim.health.start("k6e: lsp")
	local clients = vim.lsp.get_clients()
	if #clients == 0 then
		vim.health.info("No LSP clients currently attached")
	else
		vim.health.ok(#clients .. " LSP client(s) attached:")
		for _, client in ipairs(clients) do
			local bufcount = _count_buffers(client)
			vim.health.info(string.format("  %s (id: %d, buffers: %d)", client.name, client.id, bufcount))
		end
	end

	-- Check external tools
	vim.health.start("k6e: external tools")
	for _, status in ipairs(external_tools.statuses()) do
		local presentation = tool_presentation[status.name]
		if status.available then
			vim.health.ok(presentation.label .. " found")
		else
			vim.health.warn(presentation.label .. " not found - " .. presentation.hint)
		end
	end
end

return M
