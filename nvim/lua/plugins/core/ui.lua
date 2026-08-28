local keymaps = require("core.keymaps")
local bufferline = keymaps.owner("bufferline")
local noice = keymaps.owner("noice")

return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "kthwaite/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
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
			noice.lazy("<S-Enter>", function()
				require("noice").redirect(vim.fn.getcmdline())
			end, "Redirect Cmdline", { mode = "c" }),
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
	{

		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		opts = {
			options = {
				diagnostics = "nvim_lsp",
			},
		},
		keys = {
			bufferline.lazy("<leader>bb", "<cmd>BufferLineMovePrev<cr>", "Next buffer tab"),
			bufferline.lazy("<leader>bn", "<cmd>BufferLineMoveNext<cr>", "Prev buffer tab"),
			bufferline.lazy("<leader>bp", "<cmd>BufferLinePick<cr>", "Pick buffer tab"),
		},
	},
}
