local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
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

---Get a list of plugins from a comma-separated list.
---@param plugins string
---@return string[]
local function plugins_from_string(plugins)
	local plugin_list = {}
	for plugin in plugins:gmatch("[^,]+") do
		plugin = string.gsub(plugin, "^%s*(.-)%s*$", "%1")
		if plugin ~= "" then
			table.insert(plugin_list, plugin)
		end
	end

	return plugin_list
end

---Get a list of plugins from a comma-separated list in an environment variable.
---@param env_var string
---@return string[]
local function plugins_from_env(env_var)
	local plugins = os.getenv(env_var)
	if plugins == nil then
		return {}
	end
	return plugins_from_string(plugins)
end

---Get a list of extra plugins from a comma-separated list in K6E_NVIM_SESSION_PLUGINS.
---@return string[]
local function get_session_plugins()
	return plugins_from_env("K6E_NVIM_SESSION_PLUGINS")
end

---Get a list of extra plugins from a comma-separated list in K6E_NVIM_EXTRA_PLUGINS.
---@return string[]
local function get_extra_plugins()
	return plugins_from_env("K6E_NVIM_EXTRA_PLUGINS")
end

---Build a spec, interpolating extra plugins into the default spec.
---@param ... string[]
---@return table
local function build_spec(...)
	local spec = default_spec
	for _, extra_plugins in ipairs({ ... }) do
		if extra_plugins ~= nil then
			for _, plugin in ipairs(extra_plugins) do
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

local M = {}
M.lazypath = lazypath
M.extra_plugins = get_extra_plugins()
M.session_plugins = get_session_plugins()
M.spec = build_spec(M.extra_plugins, M.session_plugins)

require("lazy").setup({
	spec = M.spec,
})

return M
