local keymaps = require("core.keymaps")
local outline = keymaps.owner("outline")

return {

	-- # outlines and navigation
	-- symbol outline
	{
		"hedyhli/outline.nvim",
		cmd = { "Outline", "OutlineOpen", "OutlineClose" },
		keys = {
			outline.lazy("<leader>o", "<cmd>Outline<CR>", "Toggle Outline"),
		},
		opts = {},
	},
}
