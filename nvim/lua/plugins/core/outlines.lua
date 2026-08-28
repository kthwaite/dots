local keymaps = require("core.keymaps")
local outline = keymaps.owner("outline")
local todo_comments = keymaps.owner("todo-comments")
local trouble = keymaps.owner("trouble")

return {

	-- # outlines and navigation
	-- error summaries
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
		cmd = { "Trouble" },
		keys = {
			trouble.lazy("<leader>te", "<cmd>Trouble diagnostics toggle<CR>", "Toggle diagnostics"),
		},
	},
	-- symbol outline
	{
		"hedyhli/outline.nvim",
		cmd = { "Outline", "OutlineOpen", "OutlineClose" },
		keys = {
			outline.lazy("<leader>o", "<cmd>Outline<CR>", "Toggle Outline"),
		},
		opts = {},
	},
	-- highlight TODO, FIXME etc
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim", "folke/trouble.nvim" },
		cmd = { "TodoQuickFix", "TodoLocList", "TodoTrouble" },
		keys = {
			todo_comments.lazy("<leader>tt", "<cmd>TodoTrouble<CR>", "Todo list (Trouble)"),
			todo_comments.lazy("<leader>tq", "<cmd>TodoQuickFix<CR>", "Todo list (Quickfix)"),
		},
		opts = {},
	},
}
