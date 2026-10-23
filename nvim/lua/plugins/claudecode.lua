-- 02_lazy requires an extra module and Lazy then imports it again, which would claim every key twice.
local cache_key = "k6e.plugins.claudecode.specs"
if package.loaded[cache_key] then
	return package.loaded[cache_key]
end

local claudecode = require("core.keymaps").owner("claudecode")

local specs = {
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
package.loaded[cache_key] = specs
return specs
