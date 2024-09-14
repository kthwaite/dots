local ensure_filetypes = {
	"bash",
	"javascript",
	"lua",
	"markdown",
	"python",
	"regex",
	"tsx",
	"typescript",
	"vim",
	"wgsl",
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
				highlight = {
					enable = true,
				},
			})
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			parser_config.just = {
				install_info = {
					url = "https://github.com/IndianBoy42/tree-sitter-just",
					files = { "src/parser.c", "src/scanner.cc" },
					branch = "main",
					-- use_makefile = true, -- this may be necessary on MacOS (try if you see compiler errors)
				},
				maintainers = { "@IndianBoy42" },
			}
		end,
	},
	-- splitting/joining blocks of code using treesitter
	--[[{
		"Wansmer/treesj",
		requires = { "nvim-treesitter/nvim-treesitter" },
	},]]
	--
}
