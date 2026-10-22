local M = {}

---@class k6e.comment.Templates
---@field line string?
---@field block string?

local C_LIKE = {
	"c",
	"cpp",
	"cs",
	"javascript",
	"javascriptreact",
	"typescript",
	"typescriptreact",
	"rust",
	"go",
	"java",
	"zig",
	"swift",
}

---@type table<string, k6e.comment.Templates>
local overrides = {
	css = { line = "/* %s */", block = "/* %s */" },
	scss = { line = "/* %s */", block = "/* %s */" },
	lua = { line = "-- %s", block = "--[[ %s ]]" },
}
for _, ft in ipairs(C_LIKE) do
	overrides[ft] = { line = "// %s", block = "/* %s */" }
end
for _, ft in ipairs({ "html", "xml", "markdown", "vue", "svelte", "astro" }) do
	overrides[ft] = { line = "<!-- %s -->", block = "<!-- %s -->" }
end

local sticky_cursor = nil

--- Split a template with exactly one `%s` into trimmed prefix and suffix.
---@param template string?
---@return string? prefix
---@return string? suffix
local function split(template)
	if type(template) ~= "string" then
		return nil
	end
	local start, finish = template:find("%s", 1, true)
	if not start or template:find("%s", finish + 1, true) then
		return nil
	end
	local prefix = vim.trim(template:sub(1, start - 1))
	local suffix = vim.trim(template:sub(finish + 1))
	return prefix, suffix
end

--- Normalise to one space around `%s`.
---@param template string?
---@return string?
local function pad(template)
	local prefix, suffix = split(template)
	if not prefix then
		return nil
	end
	local text = prefix == "" and "%s" or (prefix .. " %s")
	if suffix ~= "" then
		text = text .. " " .. suffix
	end
	return text
end

---@param filetype string?
---@return string?
local function find_commentstring(filetype)
	local current = vim.api.nvim_get_current_buf()
	local candidates = { current }
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if bufnr ~= current then
			candidates[#candidates + 1] = bufnr
		end
	end
	for _, bufnr in ipairs(candidates) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == filetype then
			return vim.bo[bufnr].commentstring
		end
	end
end

---@param filetype string
---@return k6e.comment.Templates
function M.get(filetype)
	local override = overrides[filetype]
	if override then
		return { line = override.line, block = override.block }
	end

	local template = pad(find_commentstring(filetype))
	if not template then
		return {}
	end
	local _, suffix = split(template)
	if suffix ~= "" then
		return { line = template, block = template }
	end
	return { line = template }
end

---@param bufnr integer
---@return k6e.comment.Templates
local function templates_for(bufnr)
	local filetype = vim.bo[bufnr].filetype
	local templates = M.get(filetype)
	if templates.line or templates.block then
		return templates
	end
	local template = pad(vim.bo[bufnr].commentstring)
	if not template then
		return {}
	end
	local _, suffix = split(template)
	if suffix ~= "" then
		return { line = template, block = template }
	end
	return { line = template }
end

--- Toggle a block comment over rows (1-based, inclusive).
---@param start_row integer
---@param end_row integer
function M.toggle_block(start_row, end_row)
	local bufnr = vim.api.nvim_get_current_buf()
	if start_row > end_row then
		start_row, end_row = end_row, start_row
	end

	local block = templates_for(bufnr).block
	local prefix, suffix = split(block)
	if not prefix or prefix == "" or suffix == "" then
		require("vim._comment").toggle_lines(start_row, end_row)
		return
	end

	local first = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, start_row, false)[1]
	local last = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, false)[1]
	local first_start = first:find("%S") or (#first + 1)
	local last_end = #last:gsub("%s+$", "")
	local same = start_row == end_row
	local has_prefix = first:sub(first_start, first_start + #prefix - 1) == prefix
	local has_suffix = last_end >= #suffix and last:sub(last_end - #suffix + 1, last_end) == suffix
	if same and has_prefix and has_suffix and last_end - first_start + 1 < #prefix + #suffix then
		has_prefix = false
	end

	-- Edit the last line first so the first-line edit cannot shift its columns.
	if has_prefix and has_suffix then
		local suffix_start = last_end - #suffix + 1
		if last:sub(suffix_start - 1, suffix_start - 1) == " " then
			suffix_start = suffix_start - 1
		end
		vim.api.nvim_buf_set_text(bufnr, end_row - 1, suffix_start - 1, end_row - 1, last_end, {})
		local prefix_end = first_start + #prefix - 1
		if first:sub(prefix_end + 1, prefix_end + 1) == " " then
			prefix_end = prefix_end + 1
		end
		vim.api.nvim_buf_set_text(bufnr, start_row - 1, first_start - 1, start_row - 1, prefix_end, {})
	else
		vim.api.nvim_buf_set_text(bufnr, end_row - 1, last_end, end_row - 1, last_end, { " " .. suffix })
		vim.api.nvim_buf_set_text(
			bufnr,
			start_row - 1,
			first_start - 1,
			start_row - 1,
			first_start - 1,
			{ prefix .. " " }
		)
	end
end

--- Open a commented line and enter insert mode.
---@param where "below"|"above"|"eol"
function M.open_line(where)
	local bufnr = vim.api.nvim_get_current_buf()
	local prefix, suffix = split(templates_for(bufnr).line)
	if not prefix then
		vim.notify("k6e.comment: no comment syntax for this buffer", vim.log.levels.WARN)
		return
	end
	local lead = prefix == "" and "" or (prefix .. " ")
	local tail = suffix ~= "" and (" " .. suffix) or ""
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local current = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]

	local new_row, col
	if where == "eol" then
		local joiner = current:find("%S") and " " or ""
		local text = current .. joiner .. lead
		vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { text .. tail })
		new_row, col = row, #text
	else
		local indent = current:match("^%s*")
		local text = indent .. lead
		local at = where == "below" and row or row - 1
		vim.api.nvim_buf_set_lines(bufnr, at, at, false, { text .. tail })
		new_row, col = at + 1, #text
	end

	vim.api.nvim_win_set_cursor(0, { new_row, col })
	if tail == "" then
		vim.cmd("startinsert!")
	else
		vim.cmd("startinsert")
	end
end

local function restore_cursor()
	if sticky_cursor then
		pcall(vim.api.nvim_win_set_cursor, 0, sticky_cursor)
	end
	sticky_cursor = nil
end

--- operatorfunc target for `gb`.
function M.operator()
	local start_row = vim.api.nvim_buf_get_mark(0, "[")[1]
	local end_row = vim.api.nvim_buf_get_mark(0, "]")[1]
	M.toggle_block(start_row, end_row)
	restore_cursor()
end

function M.setup()
	local owner = require("core.keymaps").owner("comment")

	owner.eager("gb", function()
		sticky_cursor = vim.api.nvim_win_get_cursor(0)
		vim.o.operatorfunc = "v:lua.require'k6e.comment'.operator"
		return "g@"
	end, "Block comment (operator)", { mode = { "n", "x" }, expr = true })

	owner.eager("gbc", function()
		local cursor = vim.api.nvim_win_get_cursor(0)
		M.toggle_block(cursor[1], cursor[1])
		pcall(vim.api.nvim_win_set_cursor, 0, cursor)
	end, "Toggle block comment", { mode = "n" })

	owner.eager("gco", function()
		M.open_line("below")
	end, "Comment below", { mode = "n" })
	owner.eager("gcO", function()
		M.open_line("above")
	end, "Comment above", { mode = "n" })
	owner.eager("gcA", function()
		M.open_line("eol")
	end, "Comment at end of line", { mode = "n" })
end

return M
