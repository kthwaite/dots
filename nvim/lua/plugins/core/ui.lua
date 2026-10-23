return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "kthwaite/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	-- # statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				icons_enabled = true,
				disabled_filetypes = {},
				always_divide_middle = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "lsp_status" },
				lualine_c = { "filename" },
				lualine_x = {
					{
						function()
							return vim.fn.wordcount().words .. " words"
						end,
						cond = function()
							return vim.tbl_contains({ "markdown", "text" }, vim.bo.filetype)
						end,
					},
					[[%{&filetype!=#''?&filetype:'none'}]],
				},
				lualine_y = {
					[=[%{strlen(&fenc)?&fenc:&enc}[%{&fileformat}]]=],
					{
						"diagnostics",
						diagnostics_color = {},
						symbols = { warn = " W:", hint = " H:", info = " I:" },
					},
				},
				lualine_z = { { "%p%% L:%3l/%L C:%c", padding = { left = 1, right = 1 } } },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			extensions = {},
		},
	},
}
