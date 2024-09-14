-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = false
-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Hopscotch.256'

-- and finally, return the configuration to wezterm
return config
