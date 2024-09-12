local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath)

local default_spec = {
	{ import = "plugins.core" },
	{ import = "plugins.extras" },
}

---Build a list of extra plugins from a comma-separated list in K6E_NVIM_EXTRA_PLUGINS.
local function build_spec()
	local spec = default_spec
	local extra_plugins = os.getenv("K6E_NVIM_EXTRA_PLUGINS")
	if extra_plugins ~= nil then
		for plugin in extra_plugins:gmatch("[^,]+") do
			plugin = string.gsub(plugin, "^%s*(.-)%s*$", "%1")
			if plugin ~= "" then
				local resolved_name = "plugins." .. plugin
				local ok, _ = pcall(require, resolved_name)
				if not ok then
					vim.notify("Failed to load plugin: " .. resolved_name, vim.log.levels.ERROR)
				else
					-- vim.notify("Loading extra plugin: " .. resolved_name, vim.log.levels.DEBUG)
					table.insert(spec, { import = resolved_name })
				end
			end
		end
	end
	return spec
end

return require("lazy").setup({
	spec = build_spec(),
})
