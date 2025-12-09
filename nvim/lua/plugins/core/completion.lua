local ignore_filetypes = require("core.utility").default_ignore_filetypes
return {
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		config = function()
			require("luasnip").setup({ store_selection_keys = "<Tab>" })
			require("luasnip.loaders.from_snipmate").lazy_load()
		end,
	},
	{
		"Saghen/blink.cmp",

		dependencies = {
			{ "L3MON4D3/LuaSnip", version = "v2.*" },
			-- optional: provides snippets for the snippet source
			"rafamadriz/friendly-snippets",
		},
		-- use a release tag to download pre-built binaries
		version = "1.*",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-space: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			keymap = {
				preset = "super-tab",
				["<Tab>"] = {
					function(cmp)
						local copilot = require("copilot.suggestion")
						if copilot.is_visible() then
							copilot.accept()
							-- IMPORTANT: don’t run blink’s fallback when we just accepted Copilot
							return
						end

						-- otherwise, do whatever blink would normally do on <Tab>
						return cmp.select_and_accept()
					end,
					"fallback",
				},
			},

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			-- (Default) Only show the documentation popup when manually triggered
			completion = { documentation = { auto_show = true } },
			snippets = { preset = "luasnip" },

			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			cmdline = {
				keymap = { preset = "inherit" },
				completion = { menu = { auto_show = true } },
			},
			signature = { enabled = true },

			-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
			-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
			-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
			--
			-- See the fuzzy documentation for more information
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
	--[[{
		"hrsh7th/nvim-cmp",
		version = false,
		lazy = true,
		dependencies = {
			"hrsh7th/cmp-path", -- Path plugin for nvim-cmp
			"hrsh7th/cmp-cmdline", -- Command-line plugin for nvim-cmp
			"hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
			"saadparwaiz1/cmp_luasnip", -- Snippets for nvim-cmp
			"hrsh7th/cmp-buffer", -- nvim-cmp source for buffer words.
		},
		event = "InsertEnter",
		config = function()
			local cmp = require("cmp")
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(
					vim.lsp.protocol.make_client_capabilities()
				),
			})
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = {
					["<C-p>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						else
							cmp.complete()
						end
					end, { "i", "c" }),
					["<C-n>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_next_item()
						else
							cmp.complete()
						end
					end, { "i", "c" }),
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.close(),
					["<CR>"] = cmp.mapping.confirm({
						--behavior = cmp.ConfirmBehavior.Replace,
						--select = true,
					}),
				},
				sources = {
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "nvim_lsp" },
				},
			})
			cmp.setup.cmdline(":", {
				sources = { { name = "cmdline" } },
			})
		end,
	},]]
	--
}
