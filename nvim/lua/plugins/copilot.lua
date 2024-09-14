local use_copilot_lua = os.getenv("K6E_COPILOT_LUA") == "1"
return {
	{
		"github/copilot.vim",
		event = "InsertEnter",
		enabled = not use_copilot_lua,
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		enabled = use_copilot_lua,
	},
}
