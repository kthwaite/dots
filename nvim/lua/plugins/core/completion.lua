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
	},
}
