return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				enabled = true,
				suggestion = { enabled = true, auto_trigger = true },
				panel = { enabled = true },
				filetypes = {
					javascript = true,
					javascriptreact = true,
					typescript = true,
					typescriptreact = true,
					python = true,
					rust = true,
					zig = true,
					bash = true,
					lua = true,
					markdown = false,
					sh = function()
						if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "^%.env.*") then
							-- disable for .env files
							return false
						end
						return true
					end,
					-- disable for all other filetypes and ignore default `filetypes`
					["*"] = false,
				},
			})
			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuOpen",
				callback = function()
					vim.b.copilot_suggestion_hidden = true
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuClose",
				callback = function()
					vim.b.copilot_suggestion_hidden = false
				end,
			})
		end,
	},
}
