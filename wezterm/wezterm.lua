-- Pull in the wezterm API
local wezterm = require("wezterm")
local utility = require("utility")

wezterm.log_error("Loading wezterm config")
-- This will hold the configuration.
local config = wezterm.config_builder()

-- default config
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = false
config.color_scheme = "Hopscotch.256"

local hostname = utility.hostname()
wezterm.log_error("Hostname: " .. hostname)
if hostname ~= nil then
	local ok, host_config = pcall(require, "hosts." .. hostname)
	wezterm.log_error("Loading host: " .. hostname)
	if host_config ~= nil and host_config["setup"] ~= nil and type(host_config.setup) == "function" then
		config = host_config.setup(config)
		wezterm.log_error("Setup function found for host: " .. hostname)
	else
		wezterm.log_error("No setup function found for host: " .. hostname)
	end
end

-- and finally, return the configuration to wezterm
return config
