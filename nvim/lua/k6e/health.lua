local M = {}

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
	local ok_lazy, lazy_load = pcall(require, "core.02_lazy")
	if not ok_lazy then
		vim.health.error("require('core.02_lazy') failed")
	else
		local extra_plugins = lazy_load.extra_plugins
		if extra_plugins ~= nil then
			vim.health.info("Extra plugins loaded: ")
			for _, plugin in pairs(extra_plugins) do
				vim.health.info(" " .. plugin)
			end
		else
			vim.health.info("No extra plugins loaded")
		end
	end
end

return M
