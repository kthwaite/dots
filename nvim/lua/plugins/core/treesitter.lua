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
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		lazy = true,
		ft = ensure_filetypes,
		cmd = { "TSInstall" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = ensure_filetypes,
				-- modules = {},
				ignore_install = {},
				auto_install = true,
				highlight = { enable = true, additional_vim_regex_highlighting = false },
				indent = { enable = false },
				sync_install = false,
			})
			-- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
		end,
	},
	{
		"danymat/neogen",
		config = function()
			require("neogen").setup({ snippet_engine = "luasnip" })
		end,
		keys = {
			{ "<leader>gn", "<cmd>Neogen<cr>", desc = "Neogen" },
		},
	},
	-- splitting/joining blocks of code using treesitter
	--[[{
		"Wansmer/treesj",
		requires = { "nvim-treesitter/nvim-treesitter" },
	},]]
	--
}
