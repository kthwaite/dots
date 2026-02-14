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
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
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
			lazygit = {
				enabled = function()
					return vim.fn.executable("lazygit") == 1
				end,
			},
			dim = { enabled = true },
			explorer = { enabled = true },
			picker = { enabled = true },
			zen = { enabled = true },
		},
		keys = {
			-- pickers
			{
				"<leader>.",
				function()
					Snacks.picker.smart()
				end,
				desc = "Find files",
			},
			{
				"<leader>,",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Find buffers",
			},
			{
				"<leader>/",
				function()
					Snacks.picker.grep()
				end,
				desc = "Live grep",
			},
			{
				"<leader>:",
				function()
					Snacks.picker.command_history()
				end,
				desc = "Command history",
			},
			{
				"<leader>n",
				function()
					Snacks.picker.notifications()
				end,
				desc = "Notification history",
			},
			{
				"<leader>th",
				function()
					require("snacks").picker.colorschemes({ layout = "ivy" })
				end,
				desc = "Pick color scheme",
			},
			{
				"<leader>sh",
				function()
					require("snacks").picker.help()
				end,
				desc = "Help pages",
			},
			{
				"<leader>cf",
				function()
					Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find config file",
			},
			{
				"<leader>cg",
				function()
					Snacks.picker.grep({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Grep config files",
			},
			{
				"<leader>sk",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "Keymaps",
			},

			-- explorer
			{
				"<leader>e",
				function()
					Snacks.explorer()
				end,
				desc = "File Explorer",
			},
			-- # git
			-- git
			{
				"<leader>gb",
				function()
					require("snacks").git.blame_line()
				end,
				desc = "git blame (line)",
			},
			{
				"<leader>gl",
				function()
					Snacks.picker.git_log()
				end,
				desc = "Git Log",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Git Status",
			},

			-- lazygit (only when installed)
			{
				"<leader>gg",
				function()
					require("snacks").lazygit()
				end,
				desc = "Lazygit",
			},
			-- utility
			{
				"<leader>rN",
				function()
					require("snacks").rename.rename_file()
				end,
				desc = "Fast Rename Current File",
			},
			{
				"<leader>z",
				function()
					Snacks.zen()
				end,
				desc = "Toggle Zen Mode",
			},
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
			---LHS of toggle mappings in NORMAL mode
			toggler = {
				---Line-comment toggle keymap
				line = "gcc",
				---Block-comment toggle keymap
				block = "gbc",
			},
			---LHS of operator-pending mappings in NORMAL and VISUAL mode
			opleader = {
				---Line-comment keymap
				line = "gc",
				---Block-comment keymap
				block = "gb",
			},
			---LHS of extra mappings
			extra = {
				---Add comment on the line above
				above = "gcO",
				---Add comment on the line below
				below = "gco",
				---Add comment at the end of line
				eol = "gcA",
			},
			---Enable keybindings
			---NOTE: If given `false` then the plugin won't create any mappings
			mappings = {
				---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
				basic = true,
				---Extra mapping; `gco`, `gcO`, `gcA`
				extra = true,
			},
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
	{ "wellle/targets.vim" },
	--------------------------------------------------------------------------------
	-- # disabled
	-- A plugin for profiling Vim and Neovim startup time.
	-- "dstein64/vim-startuptime"
}
