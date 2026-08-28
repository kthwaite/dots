local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(source, ":p:h:h")
vim.opt.runtimepath:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	package.path,
}, ";")

local tests = {}
local function test(name, callback)
	tests[#tests + 1] = { name = name, callback = callback }
end

local function equal(actual, expected, message)
	if not vim.deep_equal(actual, expected) then
		error(string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
	end
end

local function truthy(value, message)
	if not value then
		error(message)
	end
end

local function find_spec(specs, name)
	for _, spec in ipairs(specs) do
		if spec[1] == name then
			return spec
		end
	end
	error("missing plugin specification: " .. name)
end

local specs = require("plugins.core.lsp")
local lsp_spec = find_spec(specs, "neovim/nvim-lspconfig")

test("initializes diagnostic policy", function()
	truthy(type(lsp_spec.init) == "function", "nvim-lspconfig specification must expose eager init")
	lsp_spec.init()

	local config = vim.diagnostic.config()
	equal(config.virtual_text.prefix, "●", "diagnostic prefix changed")
	equal(config.virtual_text.spacing, 5, "diagnostic spacing changed")
	equal(config.virtual_text.source, "if_many", "diagnostic source policy changed")
	equal(
		config.virtual_text.format({ source = "lua_ls", severity = 2, message = "bad" }),
		"[lua_ls] 2: bad",
		"diagnostic formatter changed"
	)
	equal(config.signs, false, "diagnostic signs policy changed")
	equal(config.update_in_insert, true, "insert-mode diagnostic policy changed")
	equal(config.severity_sort, true, "diagnostic severity sorting changed")
	equal(config.float, {
		border = "rounded",
		source = "if_many",
		header = "",
		prefix = "",
	}, "diagnostic float policy changed")
end)

test("preserves LspStatus reporting", function()
	local commands = vim.api.nvim_get_commands({ builtin = false })
	truthy(commands.LspStatus ~= nil, ":LspStatus was not registered")

	local original_get_clients = vim.lsp.get_clients
	local original_notify = vim.notify
	local notifications = {}
	vim.notify = function(message, level)
		notifications[#notifications + 1] = { message = message, level = level }
	end

	vim.lsp.get_clients = function()
		return {}
	end
	vim.cmd.LspStatus()
	equal(notifications[1], {
		message = "No LSP clients running",
		level = vim.log.levels.WARN,
	}, "no-client status changed")

	notifications = {}
	vim.lsp.get_clients = function()
		return {
			{ id = 7, name = "lua_ls" },
			{ id = 9, name = "rust_analyzer" },
		}
	end
	vim.cmd.LspStatus()
	equal(notifications[1], {
		message = "Active Language Servers:\n- lua_ls (id: 7)\n- rust_analyzer (id: 9)",
		level = vim.log.levels.INFO,
	}, "active-client status changed")

	vim.lsp.get_clients = original_get_clients
	vim.notify = original_notify
end)

local function mapping_for(bufnr, lhs)
	for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
		if mapping.lhs == lhs then
			return mapping
		end
	end
end

local expected_mappings = {
	{ lhs = "gD", desc = "Go to declaration", operation = vim.lsp.buf.declaration },
	{ lhs = "gd", desc = "Go to definition", operation = vim.lsp.buf.definition },
	{ lhs = "K", desc = "Hover documentation", operation = vim.lsp.buf.hover },
	{ lhs = "gi", desc = "Go to implementation", operation = vim.lsp.buf.implementation },
	{ lhs = " wl", desc = "List workspace folders" },
	{ lhs = " D", desc = "Go to type definition", operation = vim.lsp.buf.type_definition },
	{ lhs = " rn", desc = "Rename symbol", operation = vim.lsp.buf.rename },
	{ lhs = " ca", desc = "Code action", operation = vim.lsp.buf.code_action },
	{ lhs = "gr", desc = "List references to symbol", operation = vim.lsp.buf.references },
	{ lhs = "[d", desc = "Previous diagnostic" },
	{ lhs = "]d", desc = "Next diagnostic" },
	{ lhs = " f", desc = "Format buffer" },
}

test("registers one LspAttach event", function()
	local autocmds = vim.api.nvim_get_autocmds({ group = "k6e_lsp", event = "LspAttach" })
	equal(#autocmds, 1, "LSP attachment must have one owner")
end)

test("preserves buffer-local mappings and navigation context", function()
	local bufnr = vim.api.nvim_create_buf(false, true)
	local original_get_client = vim.lsp.get_client_by_id
	local attached

	vim.lsp.get_client_by_id = function(client_id)
		equal(client_id, 41, "attachment client id changed")
		return {
			id = client_id,
			name = "test_lsp",
			server_capabilities = { documentSymbolProvider = true },
		}
	end
	package.loaded["nvim-navic"] = {
		attach = function(client, attached_bufnr)
			attached = { client = client, bufnr = attached_bufnr }
		end,
	}

	vim.api.nvim_exec_autocmds("LspAttach", {
		buffer = bufnr,
		data = { client_id = 41 },
	})

	for _, expected in ipairs(expected_mappings) do
		local mapping = mapping_for(bufnr, expected.lhs)
		truthy(mapping, "missing mapping: " .. expected.lhs)
		equal(mapping.desc, expected.desc, "mapping description changed: " .. expected.lhs)
		truthy(mapping.noremap, "mapping became recursive: " .. expected.lhs)
		truthy(mapping.silent, "mapping became noisy: " .. expected.lhs)
		if expected.operation then
			equal(mapping.callback, expected.operation, "mapping operation changed: " .. expected.lhs)
		end
	end

	local original_jump = vim.diagnostic.jump
	local original_format = vim.lsp.buf.format
	local jumps = {}
	local format_options
	vim.diagnostic.jump = function(options)
		jumps[#jumps + 1] = options
	end
	vim.lsp.buf.format = function(options)
		format_options = options
	end
	mapping_for(bufnr, "[d").callback()
	mapping_for(bufnr, "]d").callback()
	mapping_for(bufnr, " f").callback()
	equal(jumps, {
		{ count = -1, float = true },
		{ count = 1, float = true },
	}, "diagnostic navigation changed")
	equal(format_options, { async = true }, "formatting policy changed")
	vim.diagnostic.jump = original_jump
	vim.lsp.buf.format = original_format
	equal(attached.bufnr, bufnr, "nvim-navic attached to the wrong buffer")
	equal(attached.client.id, 41, "nvim-navic attached to the wrong client")

	package.loaded["nvim-navic"] = nil
	vim.lsp.get_client_by_id = original_get_client
	vim.api.nvim_buf_delete(bufnr, { force = true })
end)

test("skips navigation context without a capable client", function()
	local bufnr = vim.api.nvim_create_buf(false, true)
	local original_get_client = vim.lsp.get_client_by_id
	local attach_count = 0

	package.loaded["nvim-navic"] = {
		attach = function()
			attach_count = attach_count + 1
		end,
	}
	vim.lsp.get_client_by_id = function()
		return { server_capabilities = { documentSymbolProvider = false } }
	end
	vim.api.nvim_exec_autocmds("LspAttach", { buffer = bufnr, data = { client_id = 42 } })

	vim.lsp.get_client_by_id = function()
		return nil
	end
	vim.api.nvim_exec_autocmds("LspAttach", { buffer = bufnr, data = { client_id = 43 } })

	equal(attach_count, 0, "nvim-navic attached without document symbols")
	for _, expected in ipairs(expected_mappings) do
		truthy(mapping_for(bufnr, expected.lhs), "missing mapping without client: " .. expected.lhs)
	end

	package.loaded["nvim-navic"] = nil
	vim.lsp.get_client_by_id = original_get_client
	vim.api.nvim_buf_delete(bufnr, { force = true })
end)

test("continues attachment when nvim-navic is unavailable", function()
	local bufnr = vim.api.nvim_create_buf(false, true)
	local original_get_client = vim.lsp.get_client_by_id
	local original_preload = package.preload["nvim-navic"]

	package.loaded["nvim-navic"] = nil
	package.preload["nvim-navic"] = function()
		error("nvim-navic unavailable")
	end
	vim.lsp.get_client_by_id = function()
		return { server_capabilities = { documentSymbolProvider = true } }
	end

	local ok, err = pcall(vim.api.nvim_exec_autocmds, "LspAttach", {
		buffer = bufnr,
		data = { client_id = 44 },
	})
	truthy(ok, "missing nvim-navic failed attachment: " .. tostring(err))
	for _, expected in ipairs(expected_mappings) do
		truthy(mapping_for(bufnr, expected.lhs), "missing mapping without nvim-navic: " .. expected.lhs)
	end

	package.preload["nvim-navic"] = original_preload
	package.loaded["nvim-navic"] = nil
	vim.lsp.get_client_by_id = original_get_client
	vim.api.nvim_buf_delete(bufnr, { force = true })
end)

test("preserves Mason installation policy", function()
	local captured
	local original_mason = package.loaded["mason-lspconfig"]
	package.loaded["mason-lspconfig"] = {
		setup = function(options)
			captured = options
		end,
	}

	lsp_spec.config()

	equal(captured, {
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
	}, "Mason installation policy changed")

	package.loaded["mason-lspconfig"] = original_mason
end)

local failures = {}
for _, case in ipairs(tests) do
	local ok, err = pcall(case.callback)
	if not ok then
		failures[#failures + 1] = case.name .. ": " .. err
	end
end

if #failures > 0 then
	error(table.concat(failures, "\n"))
end
