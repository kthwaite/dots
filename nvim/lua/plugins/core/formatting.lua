return {
	"stevearc/conform.nvim",
	opts = {},
	dependencies = {
		"williamboman/mason.nvim",
	},
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				bash = { "shfmt" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				go = { "gofmt" },
				html = { "prettierd", "prettier", stop_after_first = true },
				json = { "biome", "prettierd", "prettier", stop_after_first = true },
				lua = { "stylua" },
				python = { "ruff_format" },
				rust = { "rustfmt", lsp_format = "fallback" },
				sql = { "sql_format" },
				javascript = { "biome-check" },
				javascriptreact = { "biome-check" },
				typescript = { "biome-check" },
				typescriptreact = { "biome-check" },
				zsh = { "shfmt" },
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		})
	end,
}
