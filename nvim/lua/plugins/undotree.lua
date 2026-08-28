local undotree = require("core.keymaps").owner("undotree")

return {
	{
		"mbbill/undotree",
		lazy = true,
		cmd = "UndotreeToggle",
		keys = {
			undotree.lazy("<leader>u", "<cmd>UndotreeToggle<CR>", "Toggle undo tree"),
		},
	},
}
