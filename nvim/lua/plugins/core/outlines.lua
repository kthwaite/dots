local keymaps = require("core.keymaps")
local outline = keymaps.owner("outline")
local trouble = keymaps.owner("trouble")

return {

	-- # outlines and navigation
	-- error summaries
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
		cmd = { "Trouble" },
		keys = {
			trouble.lazy("<leader>te", "<cmd>Trouble diagnostics toggle<CR>", "Toggle diagnostics"),
		},
	},
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
