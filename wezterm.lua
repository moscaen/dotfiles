local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Macchiato"
config.font = wezterm.font_with_fallback({
  wezterm.font("MesloLGS NF"),
  wezterm.font("Cascadia Code PL"),
  wezterm.font("DejaVu Sans Mono"),
})

config.keys = {
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.DisableDefaultAssignment,
	},
}

-- https://github.com/wez/wezterm/discussions/4728
local is_darwin <const> = wezterm.target_triple:find("darwin") ~= nil

if is_darwin then
	config.font_size = 16.0
else
	config.font_size = 14.0
end

return config
