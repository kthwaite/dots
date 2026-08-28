local attach_gitsigns = require("core.keymaps").owner("gitsigns").buffer({
	{ "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", "Next hunk", expr = true },
	{ "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", "Previous hunk", expr = true },
	{ "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage hunk" },
	{ "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage hunk", mode = "v" },
	{ "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset hunk" },
	{ "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset hunk", mode = "v" },
})

return {
	{
		"lewis6991/gitsigns.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		lazy = true,
		event = "BufEnter",
		opts = {
			on_attach = attach_gitsigns,
		},
	},
}
