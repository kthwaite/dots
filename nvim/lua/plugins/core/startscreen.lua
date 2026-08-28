local header = require("plugins.headers.venus")
local function version_string()
	local version = vim.version()
	if version == nil then
		return "UNKNOWN"
	end
	return ("v%d.%d.%d"):format(version.major, version.minor, version.patch)
end
return {
	{
		"goolord/alpha-nvim",
		config = function()
			local alpha = require("alpha")

			local startify = require("alpha.themes.startify")
			local section = startify.section
			startify.opts.layout = {
				{ type = "padding", val = 1 },
				header.header,
				{ type = "padding", val = 1 },
				{ type = "text", val = "NVIM " .. version_string(), opts = { position = "center" } },
				{ type = "padding", val = 1 },
				section.top_buttons,
				{ type = "group", val = { section.mru }, opts = { position = "center" } },
				section.mru_cwd,
				{ type = "padding", val = 1 },
				section.bottom_buttons,
				section.footer,
			}
			vim.api.nvim_create_autocmd("User", {
				pattern = "AlphaReady",
				callback = function()
					header.set_highlights()
					require("alpha").redraw()
				end,
			})

			alpha.setup(startify.opts)
		end,
	},
}
