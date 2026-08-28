local keymaps = require("core.keymaps")
local blink = keymaps.owner("blink")
local luasnip = keymaps.owner("luasnip")

local function completion_tab()
	if not require("blink.cmp.config").enabled() then
		return "<Tab>"
	end

	local copilot = require("copilot.suggestion")
	if copilot.is_visible() then
		copilot.accept()
		return ""
	end

	local cmp = require("blink.cmp")
	if cmp.snippet_active() then
		if cmp.accept() then
			return ""
		end
	elseif cmp.select_and_accept() then
		return ""
	end

	if cmp.snippet_forward() then
		return ""
	end
	return "<Tab>"
end

local function cmdline_completion_tab()
	local copilot = require("copilot.suggestion")
	if copilot.is_visible() then
		copilot.accept()
		return ""
	end

	if require("blink.cmp").select_and_accept() then
		return ""
	end
	return "<Tab>"
end

blink.eager("<Tab>", completion_tab, "Accept completion or advance snippet", { mode = "i", expr = true })
blink.eager("<Tab>", cmdline_completion_tab, "Accept command-line completion", { mode = "c", expr = true })
luasnip.eager("<Tab>", function()
	return require("luasnip.util.select").cut_keys
end, "Store selection for snippet", { mode = "x", expr = true })

return {
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		config = function()
			require("luasnip").setup({})
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
				["<Tab>"] = false,
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
}
