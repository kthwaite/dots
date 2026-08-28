local neogen = require("core.keymaps").owner("neogen")

local ensure_filetypes = {
	"bash",
	"c",
	"cpp",
	"go",
	"helm",
	"javascript",
	"json",
	"just",
	"kdl",
	"lua",
	"markdown",
	"python",
	"regex",
	"rust",
	"tsx",
	"typescript",
	"vim",
	"wgsl",
	"yaml",
	"zig",
}

return {
	{
		"kthwaite/nvim-treesitter",
		build = ":TSUpdate",
		branch = "main",
		lazy = true,
		ft = ensure_filetypes,
		cmd = { "TSInstall" },
		config = function()
			require("nvim-treesitter.config").setup({
				ensure_installed = ensure_filetypes,
				modules = {},
				ignore_install = {},
				auto_install = true,
				highlight = { enable = true, additional_vim_regex_highlighting = false },
				indent = { enable = false },
				sync_install = false,
			})
			-- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local treesitter = require("nvim-treesitter")
					if vim.list_contains(treesitter.get_installed(), vim.treesitter.language.get_lang(args.match)) then
						vim.treesitter.start(args.buf)
					end
				end,
			})
		end,
	},

	{
		"danymat/neogen",
		config = function()
			require("neogen").setup({
				snippet_engine = "luasnip",
				input_after_comment = true, -- (default: true) automatic jump (with insert mode) on inserted annotation
			})
		end,
		keys = {
			neogen.lazy("<leader>gn", "<cmd>Neogen<cr>", "Neogen"),
		},
	},
	-- splitting/joining blocks of code using treesitter
	{
		"Wansmer/treesj",
		requires = { "kthwaite/nvim-treesitter" },
	},
	--
}
