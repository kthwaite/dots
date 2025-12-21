local n = require("core.utility").nnoremap
return {
	-- # telescope
	{
		"nvim-telescope/telescope.nvim",
		lazy = true,
		cmd = "Telescope",
		tag = "v0.2.0",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			n("<space>ec", function()
				require("telescope.builtin").find_files({
					cwd = vim.fn.stdpath("config"),
				})
			end, { desc = "Search over config files" })
		end,
	},
}
