local claudecode = require("core.keymaps").owner("claudecode")

return {
	{
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		cmd = { "ClaudeCode", "ClaudeCodeSend", "ClaudeCodeAdd", "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny" },
		opts = { terminal = { provider = "snacks" } },
		keys = {
			claudecode.lazy("<C-,>", "<cmd>ClaudeCode<cr>", "Toggle Claude", { mode = { "n", "t" } }),
			claudecode.lazy("<leader>cs", "<cmd>ClaudeCodeSend<cr>", "Send selection to Claude", { mode = "v" }),
			claudecode.lazy("<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", "Add buffer to Claude", { mode = "n" }),
			claudecode.lazy("<leader>cy", "<cmd>ClaudeCodeDiffAccept<cr>", "Accept Claude diff", { mode = "n" }),
			claudecode.lazy("<leader>cn", "<cmd>ClaudeCodeDiffDeny<cr>", "Deny Claude diff", { mode = "n" }),
		},
	},
}
