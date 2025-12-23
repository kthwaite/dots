return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
		},
		config = function()
			local mason_lspconfig = require("mason-lspconfig")

			-- TODO: replace
			mason_lspconfig.setup({
				ensure_installed = {
					"astro",
					"bashls",
					"biome",
					"clangd",
					"lua_ls",
					"ruff",
					"rust_analyzer",
					"stylua",
					"ts_ls",
					"ty",
					"zls",
				},
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
