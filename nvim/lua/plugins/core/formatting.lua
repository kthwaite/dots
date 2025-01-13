return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				bash = { "shfmt" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				go = { "gofmt" },
				html = { "prettierd", "prettier", stop_after_first = true },
				javascript = { "biome", "prettier", stop_after_first = true },
				javascriptreact = { "biome", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				lua = { "stylua" },
				python = { "ruff_format" },
				rust = { "rustfmt", lsp_format = "fallback" },
				sql = { "sql_format" },
				typescript = { "biome", "prettier", stop_after_first = true },
				typescriptreact = { "biome", "prettier", stop_after_first = true },
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
