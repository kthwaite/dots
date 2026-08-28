local keymaps = require("core.keymaps")
local git_ui = keymaps.owner("git-ui")
local snacks = keymaps.owner("snacks")
local which_key = keymaps.owner("which-key")
local has_lazygit = vim.g.has_lazygit == true
local git_ui_action = "<cmd>Neogit<cr>"
if has_lazygit then
	git_ui_action = function()
		require("snacks").lazygit()
	end
end

return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			filter = function()
				-- example to exclude mappings without a description
				-- return mapping.desc and mapping.desc ~= ""
				return true
			end,
			---@type number|fun(node: wk.Node):boolean?
			expand = 0, -- expand groups when <= n mappings
		},
		keys = {
			which_key.lazy("<leader>?", function()
				require("which-key").show({ global = false })
			end, "Buffer Local Keymaps (which-key)"),
		},
	},
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			indent = {
				enabled = true,
				animate = {
					enabled = false,
				},
			},
			picker = {
				enabled = true,
				sources = {
					explorer = {
						win = {
							list = {
								wo = {
									number = true,
									relativenumber = false,
								},
							},
						},
					},
				},
			},
			lazygit = {
				enabled = function()
					return has_lazygit
				end,
			},
			dim = { enabled = true },
			explorer = { enabled = true },
			zen = { enabled = true },
		},
		keys = {
			-- pickers
			snacks.lazy("<leader>.", function()
				Snacks.picker.smart()
			end, "Find files"),
			snacks.lazy("<leader>,", function()
				Snacks.picker.buffers()
			end, "Find buffers"),
			snacks.lazy("<leader>/", function()
				Snacks.picker.grep({
					live = true,
				})
			end, "Live grep"),
			snacks.lazy("<leader>:", function()
				Snacks.picker.command_history()
			end, "Command history"),
			snacks.lazy("<leader>n", function()
				Snacks.picker.notifications()
			end, "Notification history"),
			snacks.lazy("<leader>th", function()
				require("snacks").picker.colorschemes({ layout = "ivy" })
			end, "Pick color scheme"),
			snacks.lazy("<leader>sh", function()
				require("snacks").picker.help()
			end, "Help pages"),
			snacks.lazy("<leader>cf", function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end, "Find config file"),
			snacks.lazy("<leader>cg", function()
				Snacks.picker.grep({ cwd = vim.fn.stdpath("config") })
			end, "Grep config files"),
			snacks.lazy("<leader>sk", "<cmd>Keymaps<cr>", "Inspect keymap ownership"),

			-- explorer
			snacks.lazy("<leader>e", function()
				Snacks.explorer()
			end, "File Explorer"),
			-- # git
			-- git
			snacks.lazy("<leader>gb", function()
				require("snacks").git.blame_line()
			end, "git blame (line)"),
			snacks.lazy("<leader>gl", function()
				Snacks.picker.git_log()
			end, "Git Log"),
			snacks.lazy("<leader>gs", function()
				Snacks.picker.git_status()
			end, "Git Status"),

			-- lazygit with Neogit fallback
			git_ui.lazy("<leader>gg", git_ui_action, "Git UI"),
			-- utility
			snacks.lazy("<leader>rN", function()
				require("snacks").rename.rename_file()
			end, "Fast Rename Current File"),
			snacks.lazy("<leader>z", function()
				Snacks.zen()
			end, "Toggle Zen Mode"),
		},
	},
	-- Neovim setup for init.lua and plugin development with full signature help, docs and completion for the nvim lua API.
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {},
	},
	{
		"numToStr/Comment.nvim",
		opts = {
			---Add a space b/w comment and the line
			padding = true,
			---Whether the cursor should stay at its position
			sticky = true,
			---Lines to be ignored while (un)comment
			ignore = nil,
		},
	},
	{
		"kylechui/nvim-surround",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{ "windwp/nvim-autopairs" },
	{
		"andymass/vim-matchup",
		config = function()
			vim.api.nvim_set_hl(0, "OffScreenPopup", { fg = "#fe8019", bg = "#3c3836", italic = true })
			vim.g.matchup_matchparen_offscreen = {
				method = "popup",
				highlight = "OffScreenPopup",
			}
		end,
	},
	--------------------------------------------------------------------------------
	-- # disabled
	-- A plugin for profiling Vim and Neovim startup time.
	-- "dstein64/vim-startuptime"
}
