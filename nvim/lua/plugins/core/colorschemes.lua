return {
	{
		-- Monokai
		"tanvirtin/monokai.nvim",
		--- Set colorscheme on startup
		opts = function()
			vim.cmd.colorscheme("monokai")
		end,
	},
	{
		-- Kanagawa
		"rebelot/kanagawa.nvim",
	},
}
