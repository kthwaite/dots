return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = {
					ui = {
						icons = {
							package_installed = "✓",
						},
					},
				},
			},
			{
				"SmiteshP/nvim-navbuddy",
				dependencies = {
					"neovim/nvim-lspconfig",
					"SmiteshP/nvim-navic",
					"MunifTanjim/nui.nvim",
					"numToStr/Comment.nvim", -- Optional
					"nvim-telescope/telescope.nvim", -- Optional
				},
				opts = {
					diagnostics = { virtual_text = true },
					lsp = { auto_attach = true },
				},
			},
			"mason-org/mason-lspconfig.nvim",
		},
		config = function()
			local mason_lspconfig = require("mason-lspconfig")

			-- TODO: replace
			mason_lspconfig.setup({
				ensure_installed = { "lua_ls" },
				automatic_enable = true,
			})
		end,
	},
	{
		"SmiteshP/nvim-navic",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
	},
}
