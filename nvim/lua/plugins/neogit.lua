-- neogit: A Magit clone for Neovim that provides a Git interface within Neovim.
-- included here because we default to using lazygit with snacks for git operations, but this may not be available on all systems
return {
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim", -- optional dx fzf
			"sindrets/diffview.nvim", -- optional - Diff integration
		},
		config = true,
		keys = {
			{ "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit UI" },
			{ "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Neogit commit" },
			{ "<leader>gl", "<cmd>Neogit log<CR>", desc = "Neogit log" },
		},
	},
}
