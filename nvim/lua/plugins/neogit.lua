-- neogit: A Magit clone for Neovim that provides a Git interface within Neovim.
-- Fallback when lazygit is not installed; snacks.lazygit is preferred when available
return {
	{
		"NeogitOrg/neogit",
		enabled = function()
			return vim.fn.executable("lazygit") == 0
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"folke/snacks.nvim",
			"sindrets/diffview.nvim",
		},
		config = true,
		keys = {
			{ "<leader>gg", "<cmd>Neogit<CR>", desc = "Neogit" },
			{ "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Neogit commit" },
		},
	},
}
