return {
	{
		"supermaven-inc/supermaven-nvim",
		lazy = true,
		ft = {
			"bash",
			"c",
			"cpp",
			"css",
			"go",
			"html",
			"java",
			"javascript",
			"javascriptreact",
			"lua",
			"markdown",
			"objc",
			"python",
			"rust",
			"scss",
			"sql",
			"swift",
			"sh",
			"typescript",
			"typescriptreact",
			"zig",
			"zsh",
		},
		opts = {
			keymaps = {
				accept_suggestion = "<Tab>",
				clear_suggestion = "<C-c>",
				accept_word = "<C-j>",
			},
			ignore_filetypes = { markdown = true, none = true, text = true },
		},
	},
}
