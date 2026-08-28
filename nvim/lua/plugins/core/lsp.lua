local function configure_diagnostics()
	vim.diagnostic.config({
		virtual_text = {
			prefix = "●",
			spacing = 5,
			source = "if_many",
			format = function(diagnostic)
				return string.format("[%s] %s: %s", diagnostic.source, diagnostic.severity, diagnostic.message)
			end,
		},
		signs = false,
		update_in_insert = true,
		severity_sort = true,
		float = {
			border = "rounded",
			source = "if_many",
			header = "",
			prefix = "",
		},
	})
end

local function register_lsp_status()
	vim.api.nvim_create_user_command("LspStatus", function()
		local clients = vim.lsp.get_clients()
		if #clients == 0 then
			vim.notify("No LSP clients running", vim.log.levels.WARN)
			return
		end

		local lines = { "Active Language Servers:" }
		for _, client in pairs(clients) do
			local line = "- " .. client.name
			if client.name ~= client.id then
				line = line .. string.format(" (id: %d)", client.id)
			end
			table.insert(lines, line)
		end

		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	end, {})
end

local function register_lsp_attach()
	local lsp_group = vim.api.nvim_create_augroup("k6e_lsp", {})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = lsp_group,
		callback = function(event)
			local client = vim.lsp.get_client_by_id(event.data.client_id)
			local bufnr = event.buf

			local function map(key, operation, description)
				vim.keymap.set("n", key, operation, {
					buffer = bufnr,
					desc = description or "",
					noremap = true,
					silent = true,
				})
			end

			map("gD", vim.lsp.buf.declaration, "Go to declaration")
			map("gd", vim.lsp.buf.definition, "Go to definition")
			map("K", vim.lsp.buf.hover, "Hover documentation")
			map("gi", vim.lsp.buf.implementation, "Go to implementation")
			map("<space>wl", function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, "List workspace folders")
			map("<space>D", vim.lsp.buf.type_definition, "Go to type definition")
			map("<space>rn", vim.lsp.buf.rename, "Rename symbol")
			map("<space>ca", vim.lsp.buf.code_action, "Code action")
			map("gr", vim.lsp.buf.references, "List references to symbol")
			map("[d", function()
				vim.diagnostic.jump({ count = -1, float = true })
			end, "Previous diagnostic")
			map("]d", function()
				vim.diagnostic.jump({ count = 1, float = true })
			end, "Next diagnostic")
			map("<space>f", function()
				vim.lsp.buf.format({ async = true })
			end, "Format buffer")

			local ok, navic = pcall(require, "nvim-navic")
			if ok and client ~= nil and client.server_capabilities.documentSymbolProvider then
				navic.attach(client, bufnr)
			end
		end,
	})
end

local function initialize_lsp_policy()
	configure_diagnostics()
	register_lsp_status()
	register_lsp_attach()
end

return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		init = initialize_lsp_policy,
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
		},
		config = function()
			local mason_lspconfig = require("mason-lspconfig")

			-- TODO: replace
			mason_lspconfig.setup({
				ensure_installed = {
					"astro",
					"bashls",
					"clangd",
					"lua_ls",
					"ruff",
					"rust_analyzer",
					"ts_ls",
					"ty",
					"zls",
				},
				automatic_enable = true,
			})
		end,
	},
	{
		"SmiteshP/nvim-navic",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
	},
}
