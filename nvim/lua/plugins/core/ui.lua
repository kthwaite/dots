return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		opts = {
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
				format = {},
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = false,
				command_palette = true,
				long_message_to_split = true,
				lsp_doc_border = true,
				inc_rename = true,
			},
		},
		keys = {
			{
				"<S-Enter>",
				function()
					require("noice").redirect(vim.fn.getcmdline())
				end,
				mode = "c",
				desc = "Redirect Cmdline",
			},
		},
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
				lualine_b = { "branch", "diff" },
				lualine_c = { "filename" },
				lualine_x = { [[%{&filetype!=#''?&filetype:'none'}]] },
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
	{

		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		opts = {
			diagnostics = "nvim_lsp",
		},
		keys = {
			{ "<leader>bb", "<cmd>BufferLineMovePrev<cr>", desc = "Next buffer tab" },
			{ "<leader>bn", "<cmd>BufferLineMoveNext<cr>", desc = "Prev buffer tab" },
			{ "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer tab" },
		},
	},
}
