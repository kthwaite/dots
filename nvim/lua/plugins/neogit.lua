local git_ui = require("core.external_tools").git_ui()
local neogit = require("core.keymaps").owner("neogit")
local enabled = git_ui == "neogit"
local keys
if enabled then
	keys = {
		neogit.lazy("<leader>gc", "<cmd>Neogit commit<CR>", "Neogit commit"),
	}
end

-- neogit: A Magit clone for Neovim that provides a Git interface within Neovim.
-- Fallback when lazygit is not installed; snacks.lazygit is preferred when available
return {
	{
		"NeogitOrg/neogit",
		cmd = "Neogit",
		enabled = function()
			return enabled
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"folke/snacks.nvim",
			"sindrets/diffview.nvim",
		},
		config = true,
		keys = keys,
	},
}
