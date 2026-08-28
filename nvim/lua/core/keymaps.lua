local M = {}

local allowed_options = {
	expr = true,
	mode = true,
	nowait = true,
	remap = true,
	scope = true,
	silent = true,
}

local allowed_buffer_fields = {
	[1] = true,
	[2] = true,
	[3] = true,
	expr = true,
	mode = true,
	nowait = true,
	remap = true,
}

local allowed_scope_fields = {
	filetypes = true,
	lsp = true,
}

local allowed_lsp_fields = {
	clients = true,
	methods = true,
}

local collision_atoms_by_mode = {
	c = { "c" },
	i = { "i" },
	l = { "l" },
	n = { "n" },
	o = { "o" },
	s = { "s" },
	t = { "t" },
	v = { "x", "s" },
	x = { "x" },
}

local claims = {}
local active = false
local claim_index = {}
local installed_by_buffer = {}
local plugin_rows_by_buffer = {}
local global_scope = { kind = "global" }
local plugin_attachment_scope = { kind = "plugin-attachment" }

local function fail(code, message, level)
	error(string.format("%s: %s", code, message), level or 2)
end

local function require_nonblank(value, code, label, level)
	if type(value) ~= "string" or value:match("^%s*$") then
		fail(code, label .. " must be a nonblank string", level or 3)
	end
end

local function require_action(action, level)
	local action_type = type(action)
	if action_type ~= "string" and action_type ~= "function" then
		fail("KEYMAP_INVALID_ACTION", "action must be a string or function", level or 3)
	end
end

local function normalize_string_set(value, label, level)
	if type(value) == "string" then
		require_nonblank(value, "KEYMAP_INVALID_SCOPE", label, (level or 3) + 1)
		return { value }
	end
	if type(value) ~= "table" then
		fail("KEYMAP_INVALID_SCOPE", label .. " must be a string or nonempty list", level or 3)
	end

	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			fail("KEYMAP_INVALID_SCOPE", label .. " must be a string or nonempty list", level or 3)
		end
		count = count + 1
	end
	if count == 0 or count ~= #value then
		fail("KEYMAP_INVALID_SCOPE", label .. " must be a string or nonempty list", level or 3)
	end

	local normalized = {}
	local seen = {}
	for index, item in ipairs(value) do
		require_nonblank(item, "KEYMAP_INVALID_SCOPE", string.format("%s item %d", label, index), (level or 3) + 1)
		if not seen[item] then
			seen[item] = true
			normalized[#normalized + 1] = item
		end
	end
	table.sort(normalized)
	return normalized
end

local function normalize_lsp_scope(lsp, level)
	if type(lsp) ~= "table" then
		fail("KEYMAP_INVALID_SCOPE", "lsp must be a table", level or 3)
	end
	for key in pairs(lsp) do
		if not allowed_lsp_fields[key] then
			fail("KEYMAP_UNKNOWN_SCOPE_FIELD", "unknown LSP scope field " .. vim.inspect(key), level or 3)
		end
	end

	return {
		clients = lsp.clients ~= nil and normalize_string_set(lsp.clients, "lsp.clients", (level or 3) + 1) or nil,
		methods = lsp.methods ~= nil and normalize_string_set(lsp.methods, "lsp.methods", (level or 3) + 1) or nil,
	}
end

local function normalize_scope(scope, allow_scoped, level)
	if scope == nil or scope == "global" then
		return global_scope
	end
	if not allow_scoped or type(scope) ~= "table" then
		fail("KEYMAP_INVALID_SCOPE", "scope must be global or a supported Scope record", level or 3)
	end
	for key in pairs(scope) do
		if not allowed_scope_fields[key] then
			fail("KEYMAP_UNKNOWN_SCOPE_FIELD", "unknown scope field " .. vim.inspect(key), level or 3)
		end
	end

	local filetypes = scope.filetypes ~= nil
			and normalize_string_set(scope.filetypes, "scope.filetypes", (level or 3) + 1)
		or nil
	if scope.lsp == nil then
		if filetypes == nil then
			fail("KEYMAP_INVALID_SCOPE", "Scope record must contain filetypes or lsp", level or 3)
		end
		return {
			filetypes = filetypes,
			kind = "filetype",
		}
	end

	local lsp = normalize_lsp_scope(scope.lsp, (level or 3) + 1)
	return {
		clients = lsp.clients,
		filetypes = filetypes,
		kind = "lsp",
		methods = lsp.methods,
	}
end

local function copy_modes(mode, level)
	if mode == nil then
		return { "n" }, "n"
	end

	if type(mode) == "string" then
		if not collision_atoms_by_mode[mode] then
			fail("KEYMAP_INVALID_MODE", "unsupported mode " .. vim.inspect(mode), level or 3)
		end
		return { mode }, mode
	end

	if type(mode) ~= "table" or #mode == 0 then
		fail("KEYMAP_INVALID_MODE", "mode must be a mode string or nonempty list", level or 3)
	end

	local realizations = {}
	local native = {}
	local seen = {}
	for index, item in ipairs(mode) do
		if type(item) ~= "string" or not collision_atoms_by_mode[item] then
			fail(
				"KEYMAP_INVALID_MODE",
				string.format("unsupported mode at index %d: %s", index, vim.inspect(item)),
				level or 3
			)
		end
		if seen[item] then
			fail("KEYMAP_INVALID_MODE", "duplicate mode " .. vim.inspect(item), level or 3)
		end
		seen[item] = true
		realizations[#realizations + 1] = item
		native[#native + 1] = item
	end

	return realizations, native
end

local function normalize_options(options, allow_scoped, level)
	if options == nil then
		options = {}
	elseif type(options) ~= "table" then
		fail("KEYMAP_INVALID_OPTIONS", "options must be a table", level or 3)
	end

	for key in pairs(options) do
		if not allowed_options[key] then
			fail("KEYMAP_UNKNOWN_OPTION", "unknown option " .. vim.inspect(key), level or 3)
		end
	end

	local modes, native_mode = copy_modes(options.mode, (level or 3) + 1)
	return {
		expr = options.expr == true,
		modes = modes,
		native_mode = native_mode,
		nowait = options.nowait == true,
		remap = options.remap == true,
		scope = normalize_scope(options.scope, allow_scoped, (level or 3) + 1),
		silent = options.silent ~= false,
	}
end

local function source_location(info)
	local path = info.source
	if path:sub(1, 1) == "@" then
		path = path:sub(2)
	end
	return path, info.currentline
end

local function canonical_chord(chord)
	return vim.api.nvim_replace_termcodes(chord, true, true, true)
end

local function sets_are_disjoint(first, second)
	if first == nil or second == nil then
		return false
	end

	local second_set = {}
	for _, value in ipairs(second) do
		second_set[value] = true
	end
	for _, value in ipairs(first) do
		if second_set[value] then
			return false
		end
	end
	return true
end

local function scopes_overlap(first, second)
	if first.kind == "global" or second.kind == "global" then
		return first.kind == "global" and second.kind == "global"
	end
	if first.kind == "buffer" and second.kind == "buffer" then
		return first.buffer == second.buffer
	end
	if sets_are_disjoint(first.filetypes, second.filetypes) then
		return false
	end
	return true
end

local function render_set(values)
	return "[" .. table.concat(values, ",") .. "]"
end

local function render_scope(scope)
	if scope.kind == "global" or scope.kind == "plugin-attachment" then
		return scope.kind
	end
	if scope.kind == "buffer" then
		return string.format("buffer(%d)", scope.buffer)
	end
	if scope.kind == "filetype" then
		return "filetypes=" .. render_set(scope.filetypes)
	end

	local fields = {}
	if scope.filetypes then
		fields[#fields + 1] = "filetypes=" .. render_set(scope.filetypes)
	end
	if scope.clients then
		fields[#fields + 1] = "clients=" .. render_set(scope.clients)
	end
	if scope.methods then
		fields[#fields + 1] = "methods=" .. render_set(scope.methods)
	end
	return "lsp{" .. table.concat(fields, ",") .. "}"
end

local function render_claim(row)
	return string.format(
		"owner=%s source=%s:%d scope=%s",
		vim.inspect(row.owner),
		row.source,
		row.line,
		render_scope(row.scope)
	)
end
local inspection_sort_fields = {
	"mode",
	"chord",
	"scope",
	"owner",
	"description",
	"realization",
	"source",
	"line",
}

local function claim_is_active(row)
	if row.kind == "eager" and row.scope.kind == "global" then
		return active
	end

	for _, mappings in pairs(installed_by_buffer) do
		for _, mapping in pairs(mappings) do
			if mapping.row == row then
				return true
			end
		end
	end
	return false
end

local function inspection_items()
	local items = {}
	for _, row in ipairs(claims) do
		local scope = render_scope(row.scope)
		local is_active = claim_is_active(row)
		items[#items + 1] = {
			active = is_active,
			chord = row.chord,
			description = row.description,
			file = row.source,
			source_line = row.line,
			mode = row.mode,
			owner = row.owner,
			pos = { row.line, 0 },
			preview = "file",
			realization = row.kind,
			scope = scope,
			source = row.source,
			text = string.format(
				"%s  %s  Scope=%s  Owner=%s  %s  %s  %s  %s:%d",
				row.mode,
				row.chord,
				scope,
				row.owner,
				row.description,
				row.kind,
				is_active and "active" or "inactive",
				row.source,
				row.line
			),
		}
	end

	table.sort(items, function(first, second)
		for _, field in ipairs(inspection_sort_fields) do
			if first[field] ~= second[field] then
				return first[field] < second[field]
			end
		end
		return false
	end)
	return items
end

local function create_inspection_command()
	vim.api.nvim_create_user_command("Keymaps", function()
		local items = inspection_items()
		local snacks = rawget(_G, "Snacks")
		if type(snacks) ~= "table" or type(snacks.picker) ~= "table" or type(snacks.picker.pick) ~= "function" then
			local annotations = {}
			for _, item in ipairs(items) do
				annotations[#annotations + 1] =
					string.format("owner=%s source=%s:%d", vim.inspect(item.owner), item.source, item.source_line)
			end
			fail(
				"KEYMAP_INSPECTION_UNAVAILABLE",
				"Snacks picker is unavailable; " .. table.concat(annotations, "; "),
				2
			)
		end

		snacks.picker.pick({
			format = "text",
			title = "Keymap ownership",
			items = items,
			confirm = function(picker, item)
				picker:close()
				if item then
					vim.cmd.edit(vim.fn.fnameescape(item.source))
					vim.api.nvim_win_set_cursor(0, { item.source_line, 0 })
				end
			end,
		})
	end, { desc = "Inspect keymap ownership" })
end

local function add_to_index(index, row)
	for _, collision_mode in ipairs(row.collision_modes) do
		local mode_claims = index[collision_mode]
		if mode_claims == nil then
			mode_claims = {}
			index[collision_mode] = mode_claims
		end
		local chord_claims = mode_claims[row.canonical_chord]
		if chord_claims == nil then
			chord_claims = {}
			mode_claims[row.canonical_chord] = chord_claims
		end
		chord_claims[#chord_claims + 1] = row
	end
end

local function find_collision(index, row)
	for _, collision_mode in ipairs(row.collision_modes) do
		local mode_claims = index[collision_mode]
		local chord_claims = mode_claims and mode_claims[row.canonical_chord] or nil
		for _, existing in ipairs(chord_claims or {}) do
			if scopes_overlap(existing.scope, row.scope) then
				return existing, collision_mode
			end
		end
	end
end

local function build_rows(kind, owner, chord, action, description, options, source, line)
	local rows = {}
	local normalized_chord = canonical_chord(chord)
	for _, mode in ipairs(options.modes) do
		rows[#rows + 1] = {
			action = action,
			canonical_chord = normalized_chord,
			collision_modes = collision_atoms_by_mode[mode],
			chord = chord,
			description = description,
			expr = options.expr,
			kind = kind,
			line = line,
			mode = mode,
			nowait = options.nowait,
			owner = owner,
			remap = options.remap,
			scope = options.scope,
			silent = options.silent,
			source = source,
		}
	end
	return rows
end

local function publish(rows)
	local pending_index = {}
	for _, row in ipairs(rows) do
		local existing, collision_mode = find_collision(claim_index, row)
		if existing == nil then
			existing, collision_mode = find_collision(pending_index, row)
		end
		if existing then
			fail(
				"KEYMAP_COLLISION",
				string.format(
					"%s collides with %s for mode=%s chord=%s",
					render_claim(row),
					render_claim(existing),
					vim.inspect(collision_mode),
					vim.inspect(vim.fn.keytrans(row.canonical_chord))
				),
				4
			)
		end
		add_to_index(pending_index, row)
	end

	for _, row in ipairs(rows) do
		claims[#claims + 1] = row
		add_to_index(claim_index, row)
	end
end

local function ensure_claims_open(level)
	if active then
		fail("KEYMAP_LATE_CLAIM", "claims cannot be registered after activation", level or 3)
	end
end

local function validate_claim(chord, action, description, level)
	require_nonblank(chord, "KEYMAP_INVALID_CHORD", "chord", (level or 3) + 1)
	require_action(action, (level or 3) + 1)
	require_nonblank(description, "KEYMAP_INVALID_DESCRIPTION", "description", (level or 3) + 1)
end

local function mapping_options(row, buffer)
	return {
		buffer = buffer,
		desc = row.description,
		expr = row.expr,
		nowait = row.nowait,
		remap = row.remap,
		silent = row.silent,
	}
end

local function contains(values, wanted)
	if values == nil then
		return true
	end
	for _, value in ipairs(values) do
		if value == wanted then
			return true
		end
	end
	return false
end

local function current_buffer_mapping(bufnr, mode, row)
	for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
		if canonical_chord(mapping.lhs) == row.canonical_chord then
			return mapping
		end
	end
end

local function mapping_signature(mapping)
	return {
		callback = mapping.callback,
		desc = mapping.desc,
		expr = mapping.expr,
		noremap = mapping.noremap,
		nowait = mapping.nowait,
		rhs = mapping.rhs,
		silent = mapping.silent,
	}
end

local function same_mapping_signature(first, second)
	return first.callback == second.callback
		and first.desc == second.desc
		and first.expr == second.expr
		and first.noremap == second.noremap
		and first.nowait == second.nowait
		and first.rhs == second.rhs
		and first.silent == second.silent
end

local function client_matches(scope, client, bufnr)
	if not contains(scope.clients, client.name) then
		return false
	end
	if scope.methods == nil then
		return true
	end
	for _, method in ipairs(scope.methods) do
		if client:supports_method(method, bufnr) then
			return true
		end
	end
	return false
end

local function row_is_eligible(row, bufnr, detached_client_id)
	local scope = row.scope
	if scope.filetypes and not contains(scope.filetypes, vim.bo[bufnr].filetype) then
		return false
	end
	if scope.kind == "filetype" then
		return true
	end
	if scope.kind == "lsp" then
		for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
			if client.id ~= detached_client_id and client_matches(scope, client, bufnr) then
				return true
			end
		end
		return false
	end
	if scope.kind == "plugin-attachment" then
		local active_rows = plugin_rows_by_buffer[bufnr]
		return active_rows ~= nil and active_rows[row] == true
	end
	return false
end

local function reconcile_buffer(bufnr, detached_client_id)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end

	local desired = {}
	local desired_modes = {}
	for _, row in ipairs(claims) do
		if row.scope.kind ~= "global" and row_is_eligible(row, bufnr, detached_client_id) then
			for _, mode in ipairs(row.collision_modes) do
				local key = mode .. "\0" .. row.canonical_chord
				desired[key] = row
				desired_modes[key] = mode
			end
		end
	end

	local installed = installed_by_buffer[bufnr] or {}
	local blocked = {}
	for key, record in pairs(installed) do
		local current = current_buffer_mapping(bufnr, record.mode, record.row)
		local owned = current ~= nil and same_mapping_signature(mapping_signature(current), record.signature)
		if desired[key] ~= record.row then
			if owned then
				vim.keymap.del(record.mode, current.lhs, { buffer = bufnr })
			elseif current ~= nil and desired[key] ~= nil then
				blocked[key] = true
			end
			installed[key] = nil
		elseif current == nil then
			installed[key] = nil
		elseif not owned then
			blocked[key] = true
			installed[key] = nil
		end
	end

	for key, row in pairs(desired) do
		if installed[key] == nil and not blocked[key] then
			local mode = desired_modes[key]
			local current = current_buffer_mapping(bufnr, mode, row)
			if current == nil then
				vim.keymap.set(mode, row.chord, row.action, mapping_options(row, bufnr))
				current = current_buffer_mapping(bufnr, mode, row)
				installed[key] = {
					mode = mode,
					row = row,
					signature = mapping_signature(current),
				}
			end
		end
	end

	installed_by_buffer[bufnr] = next(installed) and installed or nil
end

local function create_scoped_autocommands()
	local group = vim.api.nvim_create_augroup("core.keymaps", { clear = true })
	vim.api.nvim_create_autocmd({ "FileType", "LspAttach", "LspDetach" }, {
		group = group,
		callback = function(args)
			local detached_client_id = args.event == "LspDetach" and args.data and args.data.client_id or nil
			reconcile_buffer(args.buf, detached_client_id)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			installed_by_buffer[args.buf] = nil
			plugin_rows_by_buffer[args.buf] = nil
		end,
	})
end

function M.owner(name)
	require_nonblank(name, "KEYMAP_INVALID_OWNER", "owner", 3)

	local function eager(chord, action, description, options)
		local info = debug.getinfo(2, "Sl")
		ensure_claims_open(3)
		validate_claim(chord, action, description, 3)
		local normalized = normalize_options(options, true, 3)
		local source, line = source_location(info)
		publish(build_rows("eager", name, chord, action, description, normalized, source, line))
	end

	local function lazy(chord, action, description, options)
		local info = debug.getinfo(2, "Sl")
		ensure_claims_open(3)
		validate_claim(chord, action, description, 3)
		local normalized = normalize_options(options, false, 3)
		local source, line = source_location(info)
		publish(build_rows("lazy", name, chord, action, description, normalized, source, line))

		return {
			chord,
			action,
			mode = normalized.native_mode,
			desc = description,
			silent = normalized.silent,
			remap = normalized.remap,
			expr = normalized.expr,
			nowait = normalized.nowait,
		}
	end

	local function buffer(buffer_claims)
		local info = debug.getinfo(2, "Sl")
		ensure_claims_open(3)
		if type(buffer_claims) ~= "table" or #buffer_claims == 0 then
			fail("KEYMAP_INVALID_BUFFER_CLAIMS", "buffer claims must be a nonempty list", 3)
		end

		local rows = {}
		local source, line = source_location(info)
		for index, claim in ipairs(buffer_claims) do
			if type(claim) ~= "table" then
				fail("KEYMAP_INVALID_BUFFER_CLAIM", string.format("claim %d must be a table", index), 3)
			end
			for key in pairs(claim) do
				if not allowed_buffer_fields[key] then
					fail(
						"KEYMAP_UNKNOWN_OPTION",
						string.format("unknown field %s in buffer claim %d", vim.inspect(key), index),
						3
					)
				end
			end

			local chord, action, description = claim[1], claim[2], claim[3]
			validate_claim(chord, action, description, 3)
			local modes = copy_modes(claim.mode, 4)
			local normalized = {
				expr = claim.expr == true,
				modes = modes,
				nowait = claim.nowait == true,
				remap = claim.remap == true,
				scope = plugin_attachment_scope,
				silent = true,
			}
			local expanded = build_rows("buffer", name, chord, action, description, normalized, source, line)
			for _, row in ipairs(expanded) do
				rows[#rows + 1] = row
			end
		end
		publish(rows)

		return function(bufnr)
			if not active then
				fail("KEYMAP_NOT_ACTIVE", "buffer mappings cannot attach before activation", 2)
			end
			if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
				fail("KEYMAP_INVALID_BUFFER", "attachment requires a valid buffer", 2)
			end

			local active_rows = plugin_rows_by_buffer[bufnr]
			if active_rows == nil then
				active_rows = {}
				plugin_rows_by_buffer[bufnr] = active_rows
			end
			local changed = false
			for _, row in ipairs(rows) do
				if not active_rows[row] then
					active_rows[row] = true
					changed = true
				end
			end
			if changed then
				reconcile_buffer(bufnr)
			end
		end
	end

	return {
		buffer = buffer,
		eager = eager,
		lazy = lazy,
	}
end

function M.activate()
	if active then
		fail("KEYMAP_ALREADY_ACTIVE", "keymap registry is already active", 2)
	end

	create_scoped_autocommands()
	for _, row in ipairs(claims) do
		if row.kind == "eager" and row.scope.kind == "global" then
			vim.keymap.set(row.mode, row.chord, row.action, mapping_options(row))
		end
	end
	active = true

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		reconcile_buffer(bufnr)
	end
	create_inspection_command()
end

return M
