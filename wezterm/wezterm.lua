-- Pull in the wezterm API
local wezterm = require("wezterm")
local utility = require("utility")

local config = wezterm.config_builder()

-- default config
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = false
config.color_scheme = "Hopscotch.256"

config = utility.load_host_config(config)

-- and finally, return the configuration to wezterm
return config
