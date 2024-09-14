return {
	--------------------------------------------------------------------------------
	-- # colorschemes
	{
		"tanvirtin/monokai.nvim",
		-- set up the colorscheme lazily
		opts = function()
			vim.cmd.colorscheme("monokai")
		end,
	},
	{ "rebelot/kanagawa.nvim" },
}
