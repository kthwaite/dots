return {

	-- # outlines and navigation
	-- error summaries
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
		cmd = { "Trouble" },
		keys = {
			{ "<leader>te", "<cmd>Trouble diagnostics toggle<CR>" },
		},
	},
	-- symbol outline
	{
		"hedyhli/outline.nvim",
		cmd = { "Outline", "OutlineOpen", "OutlineClose" },
		keys = {
			{ "<leader>o", "<cmd>Outline<CR>", desc = "Toggle Outline" },
		},
		opts = {},
	},
	-- highlight TODO, FIXME etc
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim", "folke/trouble.nvim" },
		cmd = { "TodoQuickFix", "TodoLocList", "TodoTrouble" },
		keys = {
			{ "<leader>tt", "<cmd>TodoTrouble<CR>", desc = "Todo list (Trouble)" },
			{ "<leader>tq", "<cmd>TodoQuickFix<CR>", desc = "Todo list (Quickfix)" },
		},
		opts = {},
	},
}
