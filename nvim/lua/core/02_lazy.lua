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

---Get a list of extra plugins from a comma-separated list in K6E_NVIM_EXTRA_PLUGINS.
---@return string[]
local function get_extra_plugins()
    local extra_plugins = os.getenv("K6E_NVIM_EXTRA_PLUGINS")
    if extra_plugins == nil then
        return {}
    end
    local plugins = {}
    for plugin in extra_plugins:gmatch("[^,]+") do
        plugin = string.gsub(plugin, "^%s*(.-)%s*$", "%1")
        if plugin ~= "" then
            table.insert(plugins, plugin)
        end
    end
    return plugins
end

---Build a spec, interpolating extra plugins into the default spec.
---@param extra_plugins? string[]
---@return table
local function build_spec(extra_plugins)
    local spec = default_spec
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
    return spec
end

local M = {}
M.lazypath = lazypath
M.extra_plugins = get_extra_plugins()
M.spec = build_spec(M.extra_plugins)

require("lazy").setup({
    spec = M.spec,
})

return M
