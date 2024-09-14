local nnoremap = require("core.utility").nnoremap

---Use an on_attach function to only map the following keys
---after the language server attaches to the current buffer
---@param client # client, unused here
---@param bufnr number
local on_attach = function(_, bufnr)
	-- Enable completion triggered by <c-x><c-o>
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	-- Mappings
	local function n(key, func, desc)
		local opts = { noremap = true, silent = true, buffer = bufnr }
		opts["desc"] = desc or ""
		vim.keymap.set("n", key, func, opts)
	end

	-- See `:help vim.lsp.*` for documentation on any of the below functions
	n("gD", vim.lsp.buf.declaration, "Go to declaration")
	n("gd", vim.lsp.buf.definition, "Go to definition")
	n("K", vim.lsp.buf.hover, "Hover documentation")
	n("gi", vim.lsp.buf.implementation, "Go to implementation")
	-- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
	n("<space>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "List workspace folders")
	n("<space>D", vim.lsp.buf.type_definition, "Go to type definition")
	n("<space>rn", vim.lsp.buf.rename, "Rename symbol")
	n("<space>ca", vim.lsp.buf.code_action, "Code action")
	n("gr", vim.lsp.buf.references, "List references to symbol")
	n("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
	n("]d", vim.diagnostic.goto_next, "Next diagnostic")
	n("<space>f", function()
		vim.lsp.buf.format({ async = true })
	end, "Format buffer")
end

local ls_opts = {
	["ruff_lsp"] = function(opts)
		-- disable hover for ruff_lsp
		opts.on_attach = function(client, bufnr)
			on_attach(client, bufnr)
			client.server_capabilities.hoverProvider = false
		end
	end,
	["bashls"] = function(opts)
		opts.filetypes = { "sh", "bash", "zsh" }
	end,
	["tsserver"] = function(opts)
		opts.cmd = { "yarn", "typescript-language-server", "--stdio" }
	end,
	["eslintls"] = function(opts)
		opts.settings = {
			format = { enable = true },
		}
	end,
	["rust_analyzer"] = function(opts)
		opts.settings = {
			cargo = {
				sysroot = "/opt/homebrew/cellar/rust/1.72.1",
			},
		}
	end,
	["lua_ls"] = function(opts)
		local runtime_path = vim.split(package.path, ";", {})
		table.insert(runtime_path, "lua/?.lua")
		table.insert(runtime_path, "lua/?/init.lua")
		opts.settings = {
			Lua = {
				runtime = {
					-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
					version = "LuaJIT",
					-- Setup your lua path
					path = runtime_path,
				},
				diagnostics = {
					-- Get the language server to recognize the `vim` global
					globals = { "vim" },
				},
				workspace = {
					-- Make the server aware of Neovim runtime files
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				-- Do not send telemetry data containing a randomized but unique identifier
				telemetry = {
					enable = false,
				},
			},
		}
	end,
}

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = {
					ui = {
						icons = {
							package_installed = "✓",
						},
					},
				},
			},
			"williamboman/mason-lspconfig.nvim",
			"nvimtools/none-ls.nvim",
		},
		config = function()
			local mason_lspconfig = require("mason-lspconfig")

			mason_lspconfig.setup({
				ensure_installed = { "lua_ls" },
			})

			mason_lspconfig.setup_handlers({
				function(server_name) -- default handler
					local default_caps = vim.lsp.protocol.make_client_capabilities()
					local opts = {
						on_attach = on_attach,
						capabilities = require("cmp_nvim_lsp").default_capabilities(default_caps),
					}
					if ls_opts[server_name] then
						ls_opts[server_name](opts)
					end
					require("lspconfig")[server_name].setup(opts)
					vim.cmd([[ do User LspAttachBuffers ]])
				end,
			})
			vim.lsp.handlers["textDocument/publishDiagnostics"] =
				vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
					virtual_text = {
						spacing = 5,
						prefix = "",
					},
					signs = false, -- rely on highlight styles instead, don't want to clobber signcolumn
				})
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.prettier,
				},
			})
		end,
	},
	{
		"SmiteshP/nvim-navic",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
	},
	{
		"SmiteshP/nvim-navbuddy",
		dependencies = {
			"neovim/nvim-lspconfig",
			"SmiteshP/nvim-navic",
			"MunifTanjim/nui.nvim",
			"numToStr/Comment.nvim", -- Optional
			"nvim-telescope/telescope.nvim", -- Optional
		},
	},
}
