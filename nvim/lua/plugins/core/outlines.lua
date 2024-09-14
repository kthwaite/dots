return {

	-- # outlines and navigation
	-- error summaries
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
		cmd = { "Trouble", "TroubleToggle" },
		keys = {
			{ "<leader>te", "<cmd>TroubleToggle<CR>" },
		},
	},
	-- symbol outline
	{
		"simrat39/symbols-outline.nvim",
		opts = {},
	},
	-- highlight TODO, FIXME etc
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim", "folke/trouble.nvim" },
		cmd = { "TodoQuickFix", "TodoLocList", "TodoTrouble" },
		opts = {},
	},
}
