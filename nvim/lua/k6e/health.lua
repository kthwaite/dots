local M = {}

-- External tools that enhance the development experience
local external_tools = {
	{ cmd = "lazygit", name = "lazygit", hint = "Git TUI (brew install lazygit)" },
	{ cmd = "uv", name = "uv", hint = "Python package manager (brew install uv)" },
	{ cmd = "bun", name = "bun", hint = "JS runtime/bundler (brew install bun)" },
	{ cmd = "rg", name = "ripgrep", hint = "Fast grep (brew install ripgrep)" },
	{ cmd = "fd", name = "fd", hint = "Fast find (brew install fd)" },
	{ cmd = "delta", name = "delta", hint = "Git diff pager (brew install git-delta)" },
}

M.check = function()
	vim.health.start("k6e")
	local ok_util, util = pcall(require, "core.utility")
	if not ok_util then
		vim.health.error("require('core.utility') failed")
		return
	end
	vim.health.info("NVIM version " .. util.version_string())
	local uv = vim.uv or vim.loop
	vim.health.info("System Information: " .. vim.inspect(uv.os_uname()))

	if vim.fn.has("nvim-0.9") == 0 then
		vim.health.warn("nvim version is < v0.9.0")
	else
		vim.health.ok("nvim version is >= v0.9.0")
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
			local buffers = vim.lsp.get_buffers_by_client_id(client.id)
			vim.health.info(string.format("  %s (id: %d, buffers: %d)", client.name, client.id, #buffers))
		end
	end

	-- Check external tools
	vim.health.start("k6e: external tools")
	for _, tool in ipairs(external_tools) do
		if vim.fn.executable(tool.cmd) == 1 then
			vim.health.ok(tool.name .. " found")
		else
			vim.health.warn(tool.name .. " not found - " .. tool.hint)
		end
	end
end

return M
