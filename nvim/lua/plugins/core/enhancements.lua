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
			--
		},
		keys = {
			{
				"<leader>lg",
				function()
					require("snacks").lazygit()
				end,
				desc = "Lazygit",
			},
			{
				"<leader>gl",
				function()
					require("snacks").lazygit.log()
				end,
				desc = "Lazygit Logs",
			},
			{
				"<leader>rN",
				function()
					require("snacks").rename.rename_file()
				end,
				desc = "Fast Rename Current File",
			},
			{
				"<leader>th",
				function()
					require("snacks").picker.colorschemes({ layout = "ivy" })
				end,
				desc = "Pick Color Schemes",
			},
			{
				"<leader>vh",
				function()
					require("snacks").picker.help()
				end,
				desc = "Help Pages",
			},
		},
	},
	-- # neotree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
		},
		lazy = true,
		cmd = "Neotree",
		init = function()
			vim.g.neo_tree_remove_legacy_commands = 1
			if vim.fn.argc() == 1 then
				local stat = vim.loop.fs_stat(vim.fn.argv(0))
				if stat and stat.type == "directory" then
					require("neo-tree")
				end
			end
		end,
		opts = {
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = true,
				hijack_netrw_behavior = "open_default",
			},
		},
	},
	{
		dir = vim.fn.stdpath("config") .. "/plugins/surround",
		lazy = true,
		event = "InsertEnter",
		opts = {
			mappings = true, -- Enable default mappings
			insert_mappings = true, -- Enable insert mode mappings
		},
	},
	-- Neovim setup for init.lua and plugin development with full signature help, docs and completion for the nvim lua API.
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {},
	},
	-- register peeking (using local implementation)
	{
		dir = vim.fn.stdpath("config") .. "/plugins/peekup",
		name = "peekup",
		config = function()
			require("peekup").setup()
		end,
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
	-- Local repeat implementation (replaces tpope/vim-repeat)
	{
		dir = vim.fn.stdpath("config") .. "/plugins/repeat",
		lazy = false, -- Load immediately as other plugins depend on it
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
