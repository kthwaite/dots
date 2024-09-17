local M = {}
local wezterm = require("wezterm")

---Get hostname.
---@return string?
function M.hostname()
    local hostname = os.getenv("HOSTNAME")
    if hostname == nil then
        hostname = os.getenv("HOST")
    end
    if hostname == nil then
        local fh = io.popen("hostname")
        if fh == nil then
            return nil
        end
        hostname = fh:read()
        fh:close()
    end
    -- if hostname ends with .local, remove it
    hostname, _ = hostname:gsub("%.local$", "")
    return hostname
end

---Load host config.
---@param config table
---@param hostname string?
function M.load_host_config(config, hostname)
    if hostname == nil then
        hostname = M.hostname()
    end
    wezterm.log_info("Attempting to load host config for host: " .. hostname)
    local ok, host_config = pcall(require, "hosts." .. hostname)
    if not ok or host_config == nil then
        wezterm.log_warning("No host config found for host: " .. hostname)
        return
    end
    wezterm.log_info("Loading host: " .. hostname)
    if host_config["setup"] ~= nil and type(host_config.setup) == "function" then
        config = host_config.setup(config)
        wezterm.log_info("Setup run for host: " .. hostname)
    else
        wezterm.log_error("No setup function found for host: " .. hostname)
    end
    return config
end

return M
