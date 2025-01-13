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
		"hedyhli/outline.nvim",
		config = function()
			-- Example mapping to toggle outline
			vim.keymap.set("n", "<leader>o", "<cmd>Outline<CR>", { desc = "Toggle Outline" })

			require("outline").setup({
				-- Your setup opts here (leave empty to use defaults)
			})
		end,
	},
	-- highlight TODO, FIXME etc
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim", "folke/trouble.nvim" },
		cmd = { "TodoQuickFix", "TodoLocList", "TodoTrouble" },
		opts = {},
	},
}
