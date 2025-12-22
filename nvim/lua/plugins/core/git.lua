return {
	{
		"lewis6991/gitsigns.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		lazy = true,
		event = "BufEnter",
		opts = {
			on_attach = function(bufnr)
				local function map(mode, lhs, rhs, opts)
					opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
					vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
				end

				-- Navigation
				map("n", "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true })
				map("n", "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true })

				-- Actions
				map("n", "<leader>hs", ":Gitsigns stage_hunk<CR>")
				map("v", "<leader>hs", ":Gitsigns stage_hunk<CR>")
				map("n", "<leader>hr", ":Gitsigns reset_hunk<CR>")
				map("v", "<leader>hr", ":Gitsigns reset_hunk<CR>")
			end,
		},
	},
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
