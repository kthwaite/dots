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

local function fails_with(callback, expected, message)
	local ok, err = pcall(callback)
	if ok or not tostring(err):find(expected, 1, true) then
		error(string.format("%s\nexpected error containing: %s\nactual: %s", message, expected, tostring(err)))
	end
end

local function capture_error(callback, message)
	local ok, err = pcall(callback)
	if ok then
		error(message)
	end
	return tostring(err)
end

local modes = { "n", "v", "x", "s", "o", "i", "l", "c", "t" }
local original_get_clients = vim.lsp.get_clients
local original_snacks = _G.Snacks
local function reset_scenario()
	package.loaded["core.keymaps"] = nil
	package.loaded["plugins.core.completion"] = nil
	vim.g.mapleader = nil
	vim.g.maplocalleader = nil
	vim.g.has_lazygit = nil
	vim.lsp.get_clients = original_get_clients
	_G.Snacks = original_snacks

	for name in pairs(vim.api.nvim_get_commands({ builtin = false })) do
		pcall(vim.api.nvim_del_user_command, name)
	end

	for _, mode in ipairs(modes) do
		for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
			pcall(vim.keymap.del, mode, mapping.lhs)
		end
	end
end

local function isolated(name, callback)
	test(name, function()
		reset_scenario()
		local ok, err = xpcall(callback, debug.traceback)
		reset_scenario()
		if not ok then
			error(err)
		end
	end)
end

local function buffer_mapping(bufnr, mode, lhs)
	for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
		if mapping.lhs == lhs then
			return mapping
		end
	end
end

local function buffer_mapping_count(bufnr, mode, lhs)
	local count = 0
	for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
		if mapping.lhs == lhs then
			count = count + 1
		end
	end
	return count
end
isolated("queues eager mappings with normal global silent defaults", function()
	vim.g.mapleader = " "
	local keymaps = require("core.keymaps")
	local editing = keymaps.owner("editing")

	editing.eager("<leader>x", "<cmd>echo 'x'<cr>", "Example")
	equal(vim.fn.maparg("<leader>x", "n"), "", "eager mapping must remain queued before activation")

	keymaps.activate()
	local mapping = vim.fn.maparg("<leader>x", "n", false, true)
	truthy(mapping.lhs ~= nil, "activation must install the eager mapping")
	equal(mapping.buffer, 0, "eager mapping must default to global scope")
	equal(mapping.silent, 1, "eager mapping must default to silent")
	equal(mapping.noremap, 1, "eager mapping must default to non-remapping")
end)

isolated("expands eager mappings across modes", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("editing").eager("gq", "<nop>", "Example", { mode = { "n", "x" } })

	keymaps.activate()
	truthy(vim.fn.maparg("gq", "n") ~= "", "normal mode claim must be installed")
	truthy(vim.fn.maparg("gq", "x") ~= "", "visual mode claim must be installed")
end)

isolated("requires nonblank owners chords and descriptions", function()
	local keymaps = require("core.keymaps")
	fails_with(function()
		keymaps.owner("  ")
	end, "KEYMAP_INVALID_OWNER", "blank owner must be rejected")

	local editing = keymaps.owner("editing")
	fails_with(function()
		editing.eager("", "<nop>", "Example")
	end, "KEYMAP_INVALID_CHORD", "blank chord must be rejected")
	fails_with(function()
		editing.eager("x", "<nop>", " \t")
	end, "KEYMAP_INVALID_DESCRIPTION", "blank description must be rejected")
end)

isolated("rejects unknown options", function()
	local editing = require("core.keymaps").owner("editing")
	fails_with(function()
		editing.eager("x", "<nop>", "Example", { unexpected = true })
	end, "KEYMAP_UNKNOWN_OPTION", "options must be a closed record")
end)

isolated("returns a native Lazy key specification", function()
	local action = function()
		return "lazy"
	end
	local lazy_spec = require("core.keymaps").owner("editing").lazy("<leader>l", action, "Lazy example", {
		mode = { "n", "v" },
		expr = true,
		nowait = true,
		remap = true,
		silent = false,
	})

	equal(lazy_spec, {
		"<leader>l",
		action,
		mode = { "n", "v" },
		desc = "Lazy example",
		silent = false,
		remap = true,
		expr = true,
		nowait = true,
	}, "lazy adapter must return exactly a native Lazy key specification")
end)

isolated("rejects eager claims that collide and reports both owners sources and scopes", function()
	local keymaps = require("core.keymaps")
	local first = assert(loadstring(
		[[return function(registry)
			registry.owner("first").eager("<leader>x", "a", "First")
		end]],
		"@first-source.lua"
	))()
	local second = assert(loadstring(
		[[return function(registry)
			registry.owner("second").eager("<leader>x", "b", "Second")
		end]],
		"@second-source.lua"
	))()

	first(keymaps)
	local err = capture_error(function()
		second(keymaps)
	end, "eager/eager collision must fail")

	truthy(err:find("KEYMAP_COLLISION", 1, true), "collision must have a stable error code")
	truthy(err:find("first", 1, true) and err:find("second", 1, true), "collision must name both owners")
	truthy(
		err:find("first-source.lua", 1, true) and err:find("second-source.lua", 1, true),
		"collision must name both source paths"
	)
	local _, scope_count = err:gsub("scope=global", "")
	equal(scope_count, 2, "collision must render both scopes")
end)

isolated("rejects eager and Lazy claims that collide", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("first").eager("x", "a", "First")

	fails_with(function()
		keymaps.owner("second").lazy("x", "b", "Second")
	end, "KEYMAP_COLLISION", "eager/Lazy collision must fail")
end)

isolated("rejects two Lazy claims that collide", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("first").lazy("x", "a", "First")

	fails_with(function()
		keymaps.owner("second").lazy("x", "b", "Second")
	end, "KEYMAP_COLLISION", "Lazy/Lazy collision must fail")
end)

isolated("rejects duplicate claims from the same owner", function()
	local editing = require("core.keymaps").owner("editing")
	editing.eager("x", "a", "First")

	fails_with(function()
		editing.eager("x", "b", "Second")
	end, "KEYMAP_COLLISION", "owner identity must not permit duplicate claims")
end)

isolated("detects collisions after expanding mode arrays", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("first").eager("x", "a", "First", { mode = { "n", "x" } })

	fails_with(function()
		keymaps.owner("second").eager("x", "b", "Second", { mode = { "i", "x" } })
	end, "KEYMAP_COLLISION", "shared atomic modes must collide")
end)

isolated("detects collisions between v and x modes", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("visual").eager("x", "a", "Visual", { mode = "v" })

	fails_with(function()
		keymaps.owner("visual-only").eager("x", "b", "Visual only", { mode = "x" })
	end, "KEYMAP_COLLISION", "v and x claims must share a collision atom")
end)

isolated("reports the atomic select-mode collision for v and s aliases", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("select-only").eager("x", "a", "Select only", { mode = "s" })

	local err = capture_error(function()
		keymaps.owner("visual").eager("x", "b", "Visual", { mode = "v" })
	end, "v and s claims must collide")
	truthy(err:find('mode="s"', 1, true), "collision must report the shared select-mode atom")
	truthy(err:find('chord="x"', 1, true), "collision must report the canonical chord")
end)

isolated("rejects overlapping visual modes within one batch atomically", function()
	local keymaps = require("core.keymaps")
	fails_with(function()
		keymaps.owner("visual").eager("x", "a", "Visual", { mode = { "v", "x" } })
	end, "KEYMAP_COLLISION", "v and x in one batch must collide")

	keymaps.owner("after").eager("x", "b", "After failed batch", { mode = "x" })
end)

isolated("reports the canonical chord for leader aliases", function()
	vim.g.mapleader = " "
	local keymaps = require("core.keymaps")
	keymaps.owner("first").eager("<leader>x", "a", "First")

	local err = capture_error(function()
		keymaps.owner("second").eager("<Space>x", "b", "Second")
	end, "equivalent leader chords must collide")
	truthy(err:find('mode="n"', 1, true), "collision must report the shared normal-mode atom")
	truthy(err:find('chord="<Space>x"', 1, true), "collision must report the printable canonical leader chord")
end)

isolated("allows global and scoped claims to coexist", function()
	local keymaps = require("core.keymaps")
	local global = keymaps.owner("global")
	global.eager("x", "a", "Global filetype chord")
	keymaps.owner("filetype").eager("x", "b", "Lua", { scope = { filetypes = "lua" } })
	global.eager("y", "c", "Global LSP chord")
	keymaps.owner("lsp").eager("y", "d", "LSP", { scope = { lsp = { methods = "textDocument/definition" } } })
end)

isolated("allows claims with disjoint filetype sets to coexist", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("lua").eager("x", "a", "Lua", { scope = { filetypes = { "lua", "vim" } } })
	keymaps.owner("rust").eager("x", "b", "Rust", { scope = { filetypes = { "rust", "go" } } })
end)

isolated("rejects claims with equal filetypes", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("first").eager("x", "a", "First", { scope = { filetypes = "lua" } })

	fails_with(function()
		keymaps.owner("second").eager("x", "b", "Second", { scope = { filetypes = { "lua" } } })
	end, "KEYMAP_COLLISION", "equal filetype scopes must collide")
end)

isolated("rejects claims with intersecting filetype sets", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("first").eager("x", "a", "First", { scope = { filetypes = { "lua", "vim" } } })

	fails_with(function()
		keymaps.owner("second").eager("x", "b", "Second", { scope = { filetypes = { "rust", "vim" } } })
	end, "KEYMAP_COLLISION", "intersecting filetype scopes must collide")
end)

isolated("does not use LSP clients or methods as disjointness proof", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("definition").eager("x", "a", "Definition", {
		scope = { lsp = { clients = "lua_ls", methods = "textDocument/definition" } },
	})

	fails_with(function()
		keymaps.owner("hover").eager("x", "b", "Hover", {
			scope = { lsp = { clients = "rust_analyzer", methods = "textDocument/hover" } },
		})
	end, "KEYMAP_COLLISION", "two LSP scopes must conservatively collide")
end)

isolated("rejects overlapping plugin attachment claims", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("first").buffer({ { "x", "a", "First" } })

	fails_with(function()
		keymaps.owner("second").buffer({ { "x", "b", "Second" } })
	end, "KEYMAP_COLLISION", "two plugin attachment scopes must collide")
end)

isolated("rejects unknown scope and LSP fields", function()
	local editing = require("core.keymaps").owner("editing")
	fails_with(function()
		editing.eager("x", "a", "Unknown scope", { scope = { unexpected = true } })
	end, "KEYMAP_UNKNOWN_SCOPE_FIELD", "scope must be a closed record")
	fails_with(function()
		editing.eager("x", "a", "Unknown LSP", { scope = { lsp = { unexpected = true } } })
	end, "KEYMAP_UNKNOWN_SCOPE_FIELD", "LSP scope must be a closed record")
end)

isolated("reconciles filetype mappings only in eligible buffers", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("filetype").eager("x", "module-action", "Lua action", {
		scope = { filetypes = { "lua", "vim" } },
	})
	keymaps.activate()

	equal(vim.fn.maparg("x", "n"), "", "filetype claim must not create a global mapping")
	local lua_buffer = vim.api.nvim_create_buf(false, true)
	local rust_buffer = vim.api.nvim_create_buf(false, true)
	vim.bo[lua_buffer].filetype = "lua"
	vim.bo[rust_buffer].filetype = "rust"
	vim.api.nvim_exec_autocmds("FileType", { buffer = lua_buffer })
	vim.api.nvim_exec_autocmds("FileType", { buffer = rust_buffer })

	local lua_mapping = buffer_mapping(lua_buffer, "n", "x")
	truthy(lua_mapping ~= nil, "eligible filetype buffer must receive the mapping")
	equal(lua_mapping.rhs, "module-action", "filetype mapping must preserve its action")
	equal(buffer_mapping(rust_buffer, "n", "x"), nil, "ineligible filetype buffer must not receive the mapping")

	vim.api.nvim_exec_autocmds("FileType", { buffer = lua_buffer })
	equal(buffer_mapping_count(lua_buffer, "n", "x"), 1, "repeated FileType events must be idempotent")

	vim.keymap.set("n", "z", "external-action", { buffer = lua_buffer, desc = "External unrelated" })
	vim.bo[lua_buffer].filetype = "rust"
	vim.api.nvim_exec_autocmds("FileType", { buffer = lua_buffer })
	equal(buffer_mapping(lua_buffer, "n", "x"), nil, "mapping must be removed when the filetype stops matching")
	truthy(buffer_mapping(lua_buffer, "n", "z") ~= nil, "reconciliation must preserve unrelated mappings")

	vim.bo[lua_buffer].filetype = "lua"
	vim.api.nvim_exec_autocmds("FileType", { buffer = lua_buffer })
	vim.keymap.set("n", "x", "external-replacement", { buffer = lua_buffer, desc = "External replacement" })
	vim.bo[lua_buffer].filetype = "rust"
	vim.api.nvim_exec_autocmds("FileType", { buffer = lua_buffer })
	local replacement = buffer_mapping(lua_buffer, "n", "x")
	truthy(replacement ~= nil, "reconciliation must not delete a replacement it does not own")
	equal(replacement.desc, "External replacement", "reconciliation must preserve the replacement mapping")

	vim.api.nvim_buf_delete(lua_buffer, { force = true })
	vim.api.nvim_buf_delete(rust_buffer, { force = true })
end)

isolated("removes the owned select-mode half of a scoped v claim after an external x replacement", function()
	local keymaps = require("core.keymaps")
	keymaps.owner("filetype").eager("<Tab>", "module-action", "Lua visual action", {
		mode = "v",
		scope = { filetypes = "lua" },
	})
	keymaps.activate()

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.bo[bufnr].filetype = "lua"
	vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
	truthy(buffer_mapping(bufnr, "x", "<Tab>") ~= nil, "eligible buffer must receive the x realization")
	truthy(buffer_mapping(bufnr, "s", "<Tab>") ~= nil, "eligible buffer must receive the s realization")

	vim.keymap.set("x", "<Tab>", "external-replacement", {
		buffer = bufnr,
		desc = "External visual replacement",
	})
	vim.bo[bufnr].filetype = "rust"
	vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })

	local replacement = buffer_mapping(bufnr, "x", "<Tab>")
	truthy(replacement ~= nil, "reconciliation must preserve the external x replacement")
	equal(replacement.desc, "External visual replacement", "external x replacement changed")
	equal(buffer_mapping(bufnr, "s", "<Tab>"), nil, "reconciliation must remove the owned s realization")
	vim.api.nvim_buf_delete(bufnr, { force = true })
end)

isolated("reconciles LSP mappings across attach and detach events", function()
	local clients_by_buffer = {}
	vim.lsp.get_clients = function(options)
		return clients_by_buffer[options.bufnr] or {}
	end

	local function client(id, name, methods)
		local supported = {}
		for _, method in ipairs(methods) do
			supported[method] = true
		end
		return {
			id = id,
			name = name,
			supports_method = function(_, method)
				return supported[method] == true
			end,
		}
	end

	local keymaps = require("core.keymaps")
	keymaps.owner("lsp").eager("gd", "definition-action", "Definition", {
		scope = {
			filetypes = "lua",
			lsp = {
				clients = { "lua_ls", "other_ls" },
				methods = { "textDocument/definition" },
			},
		},
	})
	keymaps.activate()

	equal(vim.fn.maparg("gd", "n"), "", "LSP claim must not create a global mapping")
	local eligible = vim.api.nvim_create_buf(false, true)
	local wrong_client = vim.api.nvim_create_buf(false, true)
	local wrong_method = vim.api.nvim_create_buf(false, true)
	local wrong_filetype = vim.api.nvim_create_buf(false, true)
	clients_by_buffer[eligible] = { client(1, "lua_ls", { "textDocument/definition" }) }
	clients_by_buffer[wrong_client] = { client(2, "rust_analyzer", { "textDocument/definition" }) }
	clients_by_buffer[wrong_method] = { client(3, "lua_ls", { "textDocument/hover" }) }
	clients_by_buffer[wrong_filetype] = { client(4, "lua_ls", { "textDocument/definition" }) }

	vim.bo[eligible].filetype = "lua"
	vim.bo[wrong_client].filetype = "lua"
	vim.bo[wrong_method].filetype = "lua"
	vim.bo[wrong_filetype].filetype = "rust"
	for _, bufnr in ipairs({ eligible, wrong_client, wrong_method, wrong_filetype }) do
		vim.api.nvim_exec_autocmds("LspAttach", { buffer = bufnr, data = { client_id = bufnr } })
	end

	truthy(buffer_mapping(eligible, "n", "gd") ~= nil, "matching LSP client and method must activate mapping")
	equal(buffer_mapping(wrong_client, "n", "gd"), nil, "client filter must exclude other clients")
	equal(buffer_mapping(wrong_method, "n", "gd"), nil, "method filter must exclude unsupported methods")
	equal(buffer_mapping(wrong_filetype, "n", "gd"), nil, "filetype filter must still apply to LSP claims")

	vim.api.nvim_exec_autocmds("LspAttach", { buffer = eligible, data = { client_id = 1 } })
	equal(buffer_mapping_count(eligible, "n", "gd"), 1, "repeated LspAttach events must be idempotent")

	clients_by_buffer[eligible] = {}
	vim.api.nvim_exec_autocmds("LspDetach", { buffer = eligible, data = { client_id = 1 } })
	equal(buffer_mapping(eligible, "n", "gd"), nil, "LspDetach must remove an ineligible mapping")
	vim.api.nvim_exec_autocmds("LspDetach", { buffer = eligible, data = { client_id = 1 } })
	equal(buffer_mapping(eligible, "n", "gd"), nil, "repeated LspDetach events must be idempotent")

	vim.api.nvim_buf_delete(eligible, { force = true })
	vim.api.nvim_buf_delete(wrong_client, { force = true })
	vim.api.nvim_buf_delete(wrong_method, { force = true })
	vim.api.nvim_buf_delete(wrong_filetype, { force = true })
end)

isolated("projects ownership claims into a deterministic Snacks picker", function()
	local keymaps = require("core.keymaps")
	local action_executed = false

	local lazy_line = debug.getinfo(1, "l").currentline + 1
	keymaps.owner("zeta").lazy("z", function()
		action_executed = true
	end, "Lazy action")
	local scoped_line = debug.getinfo(1, "l").currentline + 1
	keymaps.owner("beta").eager("b", "scoped-action", "Scoped action", {
		scope = { filetypes = { "lua", "vim" } },
	})
	local eager_line = debug.getinfo(1, "l").currentline + 1
	keymaps.owner("alpha").eager("a", "eager-action", "Eager action")
	keymaps.activate()

	local picker_options
	_G.Snacks = {
		picker = {
			pick = function(options)
				picker_options = options
			end,
		},
	}
	vim.cmd.Keymaps()

	equal(picker_options.title, "Keymap ownership", "inspection must use the ownership title")
	equal(picker_options.format, "text", "inspection must render claim text instead of the file formatter")
	equal(picker_options.items, {
		{
			active = true,
			chord = "a",
			description = "Eager action",
			file = source,
			source_line = eager_line,
			mode = "n",
			owner = "alpha",
			realization = "eager",
			pos = { eager_line, 0 },
			preview = "file",
			scope = "global",
			source = source,
			text = string.format(
				"n  a  Scope=global  Owner=alpha  Eager action  eager  active  %s:%d",
				source,
				eager_line
			),
		},
		{
			active = false,
			chord = "b",
			description = "Scoped action",
			file = source,
			source_line = scoped_line,
			mode = "n",
			owner = "beta",
			realization = "eager",
			pos = { scoped_line, 0 },
			preview = "file",
			scope = "filetypes=[lua,vim]",
			source = source,
			text = string.format(
				"n  b  Scope=filetypes=[lua,vim]  Owner=beta  Scoped action  eager  inactive  %s:%d",
				source,
				scoped_line
			),
		},
		{
			active = false,
			chord = "z",
			description = "Lazy action",
			file = source,
			source_line = lazy_line,
			mode = "n",
			owner = "zeta",
			realization = "lazy",
			pos = { lazy_line, 0 },
			preview = "file",
			scope = "global",
			source = source,
			text = string.format(
				"n  z  Scope=global  Owner=zeta  Lazy action  lazy  inactive  %s:%d",
				source,
				lazy_line
			),
		},
	}, "inspection must project complete claims in deterministic order")
	equal(action_executed, false, "inspection must not execute mapping actions")
end)

isolated("confirms ownership rows by navigating without executing actions", function()
	local keymaps = require("core.keymaps")
	local action_executed = false
	local claim_line = debug.getinfo(1, "l").currentline + 1
	keymaps.owner("navigation").lazy("gk", function()
		action_executed = true
	end, "Navigate to claim")
	keymaps.activate()

	local picker_options
	_G.Snacks = {
		picker = {
			pick = function(options)
				picker_options = options
			end,
		},
	}
	vim.cmd.Keymaps()

	local closed = false
	picker_options.confirm({
		close = function()
			closed = true
		end,
	}, picker_options.items[1])

	equal(closed, true, "confirm must close the picker")
	equal(vim.api.nvim_buf_get_name(0), vim.fn.fnamemodify(source, ":p"), "confirm must edit the captured source")
	equal(vim.api.nvim_win_get_cursor(0), { claim_line, 0 }, "confirm must position the cursor at the captured line")
	equal(action_executed, false, "confirm must not execute the mapping action")
end)

isolated("annotates unavailable Snacks inspection with owner and source", function()
	local keymaps = require("core.keymaps")
	local claim_line = debug.getinfo(1, "l").currentline + 1
	keymaps.owner("missing-snacks").lazy("x", "<nop>", "Unavailable picker")
	keymaps.activate()
	_G.Snacks = nil

	local err = capture_error(function()
		vim.cmd.Keymaps()
	end, "inspection without Snacks must fail")
	truthy(
		err:find("KEYMAP_INSPECTION_UNAVAILABLE", 1, true) ~= nil,
		"unavailable inspection must use a stable error code"
	)
	truthy(err:find('owner="missing-snacks"', 1, true) ~= nil, "unavailable inspection must name the Owner")
	truthy(
		err:find(string.format("source=%s:%d", source, claim_line), 1, true) ~= nil,
		"unavailable inspection must include the captured source"
	)
end)

isolated("includes the conditional Neogit fallback in the default Lazy graph", function()
	local original_lazy = package.loaded.lazy
	local original_lazy_config = package.loaded["core.02_lazy"]
	local captured
	package.loaded.lazy = {
		setup = function(config)
			captured = config
		end,
	}
	package.loaded["core.02_lazy"] = nil

	local ok, err = xpcall(function()
		require("core.02_lazy")
	end, debug.traceback)
	package.loaded.lazy = original_lazy
	package.loaded["core.02_lazy"] = original_lazy_config
	if not ok then
		error(err)
	end

	local found = false
	for _, spec in ipairs(captured.spec) do
		if spec.import == "plugins.neogit" then
			found = true
			break
		end
	end
	truthy(found, "default Lazy graph must import the conditional Neogit fallback")
end)

isolated("uses one stable no-lazygit decision with a Lazy Neogit command trigger", function()
	vim.g.has_lazygit = false
	package.loaded["plugins.core.enhancements"] = nil
	package.loaded["plugins.neogit"] = nil

	local enhancements = require("plugins.core.enhancements")
	local neogit_specs = require("plugins.neogit")
	local snacks_spec
	for _, spec in ipairs(enhancements) do
		if spec[1] == "folke/snacks.nvim" then
			snacks_spec = spec
			break
		end
	end
	local neogit_spec = neogit_specs[1]
	local git_ui_key
	for _, key in ipairs(snacks_spec.keys) do
		if key[1] == "<leader>gg" then
			git_ui_key = key
			break
		end
	end

	truthy(neogit_spec.enabled(), "Neogit must be enabled when startup found no lazygit")
	equal(neogit_spec.cmd, "Neogit", "fallback must expose a Lazy Neogit command trigger")
	equal(#neogit_spec.keys, 1, "fallback Neogit must expose only its commit claim")
	equal(neogit_spec.keys[1][1], "<leader>gc", "fallback Neogit must own only <leader>gc")
	equal(git_ui_key[2], "<cmd>Neogit<cr>", "git-ui must use the Lazy Neogit command when lazygit is unavailable")

	vim.g.has_lazygit = true
	truthy(neogit_spec.enabled(), "Neogit enablement must not diverge after the startup decision")
	equal(git_ui_key[2], "<cmd>Neogit<cr>", "git-ui adapter must not diverge after the startup decision")
end)

isolated("routes completion Tab behavior through co-located owners", function()
	local saved_modules = {
		blink = package.loaded["blink.cmp"],
		blink_config = package.loaded["blink.cmp.config"],
		completion = package.loaded["plugins.core.completion"],
		copilot = package.loaded["copilot.suggestion"],
		loader = package.loaded["luasnip.loaders.from_snipmate"],
		luasnip = package.loaded.luasnip,
		select = package.loaded["luasnip.util.select"],
	}
	local ok, err = xpcall(function()
		local luasnip_options
		local loader_calls = 0
		package.loaded.luasnip = {
			setup = function(options)
				luasnip_options = options
			end,
		}
		package.loaded["luasnip.loaders.from_snipmate"] = {
			lazy_load = function()
				loader_calls = loader_calls + 1
			end,
		}
		package.loaded["luasnip.util.select"] = { cut_keys = "stored-selection" }

		local copilot_visible = false
		local copilot_checks = 0
		local copilot_accepts = 0
		package.loaded["copilot.suggestion"] = {
			is_visible = function()
				copilot_checks = copilot_checks + 1
				return copilot_visible
			end,
			accept = function()
				copilot_accepts = copilot_accepts + 1
			end,
		}

		local blink_state = {}
		local blink_calls = {}
		package.loaded["blink.cmp"] = {
			snippet_active = function()
				blink_calls[#blink_calls + 1] = "snippet_active"
				return blink_state.snippet_active
			end,
			accept = function()
				blink_calls[#blink_calls + 1] = "accept"
				return blink_state.accept
			end,
			select_and_accept = function()
				blink_calls[#blink_calls + 1] = "select_and_accept"
				return blink_state.select_and_accept
			end,
			snippet_forward = function()
				blink_calls[#blink_calls + 1] = "snippet_forward"
				return blink_state.snippet_forward
			end,
		}
		local blink_enabled = true
		package.loaded["blink.cmp.config"] = {
			enabled = function()
				return blink_enabled
			end,
		}

		package.loaded["plugins.core.completion"] = nil
		local specs = require("plugins.core.completion")
		local specs_by_name = {}
		for _, spec in ipairs(specs) do
			specs_by_name[spec[1]] = spec
		end
		specs_by_name["L3MON4D3/LuaSnip"].config()
		equal(loader_calls, 1, "LuaSnip loader behavior changed")
		equal(luasnip_options.store_selection_keys, nil, "LuaSnip must not realize the visual Tab mapping")
		equal(
			specs_by_name["Saghen/blink.cmp"].opts.keymap["<Tab>"],
			false,
			"Blink must not realize the custom insert Tab mapping"
		)

		local keymaps = require("core.keymaps")
		keymaps.activate()
		local visual_mapping = vim.fn.maparg("<Tab>", "x", false, true)
		equal(visual_mapping.callback(), "stored-selection", "LuaSnip Owner must preserve visual selection storage")

		local insert_mapping = vim.fn.maparg("<Tab>", "i", false, true)
		local function run_blink(state)
			blink_state = state
			blink_calls = {}
			return insert_mapping.callback(), vim.deepcopy(blink_calls)
		end

		blink_enabled = false
		copilot_visible = true
		local result, calls = run_blink({})
		equal(result, "<Tab>", "disabled Blink must preserve the built-in Tab")
		equal(copilot_checks, 0, "disabled Blink must not inspect Copilot")
		equal(copilot_accepts, 0, "disabled Blink must not accept Copilot")
		equal(calls, {}, "disabled Blink must not call Blink actions")

		blink_enabled = true
		copilot_visible = true
		result, calls = run_blink({})
		equal(result, "", "Copilot acceptance must consume Tab")
		equal(copilot_accepts, 1, "visible Copilot suggestion must be accepted")
		equal(calls, {}, "Blink must not run after accepting Copilot")

		copilot_visible = false
		result, calls = run_blink({ snippet_active = false, select_and_accept = true })
		equal(result, "", "Blink selection acceptance must consume Tab")
		equal(calls, { "snippet_active", "select_and_accept" }, "Blink selection acceptance order changed")

		result, calls = run_blink({ snippet_active = true, accept = true })
		equal(result, "", "Blink snippet completion acceptance must consume Tab")
		equal(calls, { "snippet_active", "accept" }, "Blink snippet completion acceptance order changed")

		result, calls = run_blink({
			snippet_active = false,
			select_and_accept = false,
			snippet_forward = true,
		})
		equal(result, "", "Blink snippet movement must consume Tab")
		equal(
			calls,
			{ "snippet_active", "select_and_accept", "snippet_forward" },
			"Blink snippet movement order changed"
		)

		result, calls = run_blink({
			snippet_active = false,
			select_and_accept = false,
			snippet_forward = false,
		})
		equal(result, "<Tab>", "unhandled completion Tab must preserve the built-in fallback")
		equal(calls, { "snippet_active", "select_and_accept", "snippet_forward" }, "Blink fallback order changed")

		local cmdline_mapping = vim.fn.maparg("<Tab>", "c", false, true)
		truthy(type(cmdline_mapping.callback) == "function", "Blink Owner must preserve inherited cmdline Tab")
		blink_state = { select_and_accept = true }
		blink_calls = {}
		equal(cmdline_mapping.callback(), "", "cmdline selection acceptance must consume Tab")
		equal(blink_calls, { "select_and_accept" }, "cmdline completion must preserve selection acceptance")

		blink_state = { select_and_accept = false }
		blink_calls = {}
		equal(cmdline_mapping.callback(), "<Tab>", "unhandled cmdline completion Tab must preserve fallback")
		equal(blink_calls, { "select_and_accept" }, "cmdline completion fallback order changed")
	end, debug.traceback)

	package.loaded["blink.cmp"] = saved_modules.blink
	package.loaded["blink.cmp.config"] = saved_modules.blink_config
	package.loaded["plugins.core.completion"] = saved_modules.completion
	package.loaded["copilot.suggestion"] = saved_modules.copilot
	package.loaded["luasnip.loaders.from_snipmate"] = saved_modules.loader
	package.loaded.luasnip = saved_modules.luasnip
	package.loaded["luasnip.util.select"] = saved_modules.select
	if not ok then
		error(err)
	end
end)

isolated("routes authored mappings through reviewed ownership claims", function()
	vim.g.mapleader = " "
	dofile(root .. "/lua/core/00_setup.lua")
	dofile(root .. "/lua/core/01_keybinds.lua")

	local module_names = {
		"plugins.core.enhancements",
		"plugins.core.completion",
		"plugins.core.git",
		"plugins.core.outlines",
		"plugins.core.treesitter",
		"plugins.core.ui",
		"plugins.neogit",
		"plugins.undotree",
	}
	local specs_by_name = {}
	for _, module_name in ipairs(module_names) do
		package.loaded[module_name] = nil
		for _, spec in ipairs(require(module_name)) do
			specs_by_name[spec[1]] = spec
		end
	end

	local keymaps = require("core.keymaps")
	keymaps.activate()

	local picker_options
	_G.Snacks = {
		picker = {
			pick = function(options)
				picker_options = options
			end,
		},
	}
	vim.cmd.Keymaps()

	local function matching_rows(chord, mode)
		local rows = {}
		for _, item in ipairs(picker_options.items) do
			if item.chord == chord and (mode == nil or item.mode == mode) then
				rows[#rows + 1] = item
			end
		end
		return rows
	end

	local expected_owners = {
		["folke/which-key.nvim"] = "which-key",
		["folke/snacks.nvim"] = "snacks",
		["folke/trouble.nvim"] = "trouble",
		["hedyhli/outline.nvim"] = "outline",
		["folke/todo-comments.nvim"] = "todo-comments",
		["danymat/neogen"] = "neogen",
		["folke/noice.nvim"] = "noice",
		["akinsho/bufferline.nvim"] = "bufferline",
		["NeogitOrg/neogit"] = "neogit",
		["mbbill/undotree"] = "undotree",
	}
	for plugin, owner in pairs(expected_owners) do
		local spec = specs_by_name[plugin]
		truthy(spec ~= nil, "missing representative plugin specification: " .. plugin)
		for _, key in ipairs(spec.keys or {}) do
			local expected_owner = key[1] == "<leader>gg" and "git-ui" or owner
			local key_modes = type(key.mode) == "table" and key.mode or { key.mode or "n" }
			for _, mode in ipairs(key_modes) do
				local rows = matching_rows(key[1], mode)
				equal(#rows, 1, string.format("%s %s must have one ownership claim", plugin, key[1]))
				equal(rows[1].owner, expected_owner, string.format("%s %s Owner changed", plugin, key[1]))
				equal(rows[1].description, key.desc, string.format("%s %s description changed", plugin, key[1]))
				equal(rows[1].realization, "lazy", string.format("%s %s must use the Lazy adapter", plugin, key[1]))
			end
		end
	end

	local help_rows = matching_rows("<leader>sh", "n")
	equal(#help_rows, 1, "<leader>sh must have exactly one claim")
	equal(help_rows[1].owner, "snacks", "<leader>sh must remain Snacks help")
	equal(help_rows[1].description, "Help pages", "<leader>sh help behaviour changed")

	local inspect_rows = matching_rows("<leader>sk", "n")
	equal(#inspect_rows, 1, "<leader>sk must have exactly one claim")
	equal(inspect_rows[1].owner, "snacks", "<leader>sk must remain co-located with Snacks")
	equal(inspect_rows[1].description, "Inspect keymap ownership", "<leader>sk inspection description changed")

	local completion_claims = {
		{ chord = "<Tab>", mode = "c", owner = "blink" },
		{ chord = "<Tab>", mode = "i", owner = "blink" },
		{ chord = "<Tab>", mode = "x", owner = "luasnip" },
	}
	for _, claim in ipairs(completion_claims) do
		local rows = matching_rows(claim.chord, claim.mode)
		equal(#rows, 1, claim.owner .. " Tab must have exactly one ownership claim")
		equal(rows[1].owner, claim.owner, claim.owner .. " Tab Owner changed")
		equal(rows[1].realization, "eager", claim.owner .. " Tab must use the eager adapter")
	end
	equal(#matching_rows("<leader>sl"), 0, "left leader split claim must be deleted")
	equal(#matching_rows("<leader>sj"), 0, "down leader split claim must be deleted")

	local window_navigation = {
		["<C-h>"] = "<C-w>h",
		["<C-j>"] = "<C-w>j",
		["<C-k>"] = "<C-w>k",
		["<C-l>"] = "<C-w>l",
	}
	for chord, action in pairs(window_navigation) do
		local rows = matching_rows(chord, "n")
		equal(#rows, 1, chord .. " must have one normal-mode claim")
		equal(rows[1].owner, "window", chord .. " must remain window-owned")
		local mapping = vim.fn.maparg(chord, "n", false, true)
		truthy(mapping.rhs:lower() == action:lower(), chord .. " window navigation changed")
	end

	local git_ui_rows = matching_rows("<leader>gg", "n")
	equal(#git_ui_rows, 1, "<leader>gg must have exactly one claim")
	equal(git_ui_rows[1].owner, "git-ui", "<leader>gg must have the stable git-ui Owner")

	local snacks_spec = specs_by_name["folke/snacks.nvim"]
	local inspect_key
	local git_ui_key
	for _, key in ipairs(snacks_spec.keys) do
		if key[1] == "<leader>sk" then
			inspect_key = key
		elseif key[1] == "<leader>gg" then
			git_ui_key = key
		end
	end
	equal(inspect_key[2], "<cmd>Keymaps<cr>", "<leader>sk must execute :Keymaps")

	local original_snacks_module = package.loaded.snacks
	if vim.g.has_lazygit then
		local lazygit_calls = 0
		package.loaded.snacks = {
			lazygit = function()
				lazygit_calls = lazygit_calls + 1
			end,
		}
		git_ui_key[2]()
		equal(lazygit_calls, 1, "git-ui must use the selected lazygit adapter")
	else
		equal(git_ui_key[2], "<cmd>Neogit<cr>", "git-ui must use the selected Neogit adapter")
	end
	package.loaded.snacks = original_snacks_module

	local neogit_spec = specs_by_name["NeogitOrg/neogit"]
	if neogit_spec.enabled() then
		equal(#neogit_spec.keys, 1, "enabled Neogit must expose only its commit claim")
		equal(neogit_spec.keys[1][1], "<leader>gc", "Neogit must not independently claim <leader>gg")
	else
		equal(neogit_spec.keys, nil, "disabled Neogit must not publish Lazy claims")
	end

	for _, claim in ipairs({
		{ chord = "]c", mode = "n", owner = "gitsigns" },
		{ chord = "[c", mode = "n", owner = "gitsigns" },
		{ chord = "<leader>hs", mode = "n", owner = "gitsigns" },
		{ chord = "<leader>hs", mode = "v", owner = "gitsigns" },
		{ chord = "<leader>hr", mode = "n", owner = "gitsigns" },
		{ chord = "<leader>hr", mode = "v", owner = "gitsigns" },
		{ chord = "<leader>a", mode = "n", owner = "rust" },
		{ chord = "<leader>pi", mode = "n", owner = "python" },
	}) do
		local rows = matching_rows(claim.chord, claim.mode)
		equal(#rows, 1, claim.chord .. " scoped claim missing")
		equal(rows[1].owner, claim.owner, claim.chord .. " scoped Owner changed")
		truthy(rows[1].scope ~= "global", claim.chord .. " must remain scoped")
	end
end)

isolated("activates exactly once", function()
	local keymaps = require("core.keymaps")
	keymaps.activate()
	fails_with(keymaps.activate, "KEYMAP_ALREADY_ACTIVE", "second activation must fail")
end)

isolated("rejects claims after activation", function()
	local keymaps = require("core.keymaps")
	local editing = keymaps.owner("editing")
	keymaps.activate()

	fails_with(function()
		editing.eager("x", "<nop>", "Example")
	end, "KEYMAP_LATE_CLAIM", "claims after activation must fail")
end)

isolated("attaches buffer mappings idempotently after activation", function()
	local keymaps = require("core.keymaps")
	local attach = keymaps.owner("lsp").buffer({
		{ "gd", vim.lsp.buf.definition, "Definition" },
		{ "K", vim.lsp.buf.hover, "Hover", mode = { "n", "x" }, nowait = true },
	})
	local bufnr = vim.api.nvim_create_buf(false, true)
	local unattached = vim.api.nvim_create_buf(false, true)

	keymaps.activate()
	equal(buffer_mapping(unattached, "n", "gd"), nil, "plugin claim must remain inactive before attachment")
	attach(bufnr)
	attach(bufnr)

	local normal = vim.api.nvim_buf_get_keymap(bufnr, "n")
	local visual = vim.api.nvim_buf_get_keymap(bufnr, "x")
	local normal_by_lhs = {}
	for _, mapping in ipairs(normal) do
		normal_by_lhs[mapping.lhs] = mapping
	end
	local visual_by_lhs = {}
	for _, mapping in ipairs(visual) do
		visual_by_lhs[mapping.lhs] = mapping
	end

	truthy(normal_by_lhs.gd ~= nil, "buffer callback must install the default normal mapping")
	truthy(normal_by_lhs.K ~= nil, "buffer callback must expand the normal mode mapping")
	truthy(visual_by_lhs.K ~= nil, "buffer callback must expand the visual mode mapping")
	equal(normal_by_lhs.gd.buffer, bufnr, "attached mapping must be buffer-local")
	equal(normal_by_lhs.gd.silent, 1, "buffer mapping must default to silent")
	equal(normal_by_lhs.K.nowait, 1, "buffer mapping must preserve nowait")
	equal(#normal, 2, "repeated attachment must not duplicate mappings")
	vim.keymap.set("n", "gd", "external-replacement", { buffer = bufnr, desc = "External replacement" })
	attach(bufnr)
	equal(
		buffer_mapping(bufnr, "n", "gd").desc,
		"External replacement",
		"repeated plugin attachment must remain a no-op"
	)

	vim.api.nvim_buf_delete(bufnr, { force = true })
	vim.api.nvim_buf_delete(unattached, { force = true })
end)

local failures = {}
for _, case in ipairs(tests) do
	local ok, err = pcall(case.callback)
	if not ok then
		failures[#failures + 1] = string.format("FAIL %s\n%s", case.name, err)
	end
end

if #failures > 0 then
	error(table.concat(failures, "\n"))
end
