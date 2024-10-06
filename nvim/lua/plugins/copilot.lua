local copilot_lua_env = os.getenv("K6E_COPILOT_LUA")
local use_copilot_lua = copilot_lua_env ~= nil and copilot_lua_env == "1"
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
