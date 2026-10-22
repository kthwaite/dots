local M = {}

---@class k6e.todo.Kind
---@field kind string
---@field words string[]
---@field link string

---@type k6e.todo.Kind[]
M.keywords = {
	{ kind = "Fix", words = { "FIX", "FIXME", "BUG", "FIXIT", "ISSUE" }, link = "DiagnosticError" },
	{ kind = "Todo", words = { "TODO" }, link = "DiagnosticInfo" },
	{ kind = "Hack", words = { "HACK" }, link = "DiagnosticWarn" },
	{ kind = "Warn", words = { "WARN", "WARNING", "XXX" }, link = "DiagnosticWarn" },
	{ kind = "Perf", words = { "PERF", "OPTIM", "PERFORMANCE", "OPTIMIZE" }, link = "Identifier" },
	{ kind = "Note", words = { "NOTE", "INFO" }, link = "DiagnosticHint" },
	{ kind = "Test", words = { "TEST", "TESTING", "PASSED", "FAILED" }, link = "Identifier" },
}

---@type table<string, string>
local kind_of = {}
for _, entry in ipairs(M.keywords) do
	for _, word in ipairs(entry.words) do
		kind_of[word] = entry.kind
	end
end

local ns = vim.api.nvim_create_namespace("k6e.todo")

--- Debug table: marks the provider set during the last window draw.
---@type { row: integer, col: integer, hl: string }[]
M._last_marks = {}

---@class k6e.todo.Match
---@field kind string
---@field kw_start integer 0-based byte column
---@field kw_end integer 0-based, exclusive

--- Find the first keyword in a line. Keyword, optional `(author)`, then `:`.
---@param line string
---@return k6e.todo.Match?
function M.match(line)
	local init = 1
	while true do
		local start, finish = line:find("[%w_]+", init)
		if not start then
			return nil
		end
		local kind = kind_of[line:sub(start, finish)]
		if kind then
			local rest = finish + 1
			local author = line:match("^%b()", rest)
			if author then
				rest = rest + #author
			end
			if line:sub(rest, rest) == ":" then
				return { kind = kind, kw_start = start - 1, kw_end = rest }
			end
		end
		init = finish + 1
	end
end

---@return string
function M.rg_pattern()
	local words = {}
	for _, entry in ipairs(M.keywords) do
		vim.list_extend(words, entry.words)
	end
	return "\\b(" .. table.concat(words, "|") .. ")(\\([^)]*\\))?:"
end

function M.quickfix()
	local tools = require("core.external_tools")
	for _, status in ipairs(tools.statuses()) do
		if status.name == "rg" and not status.available then
			vim.notify("k6e.todo: rg not found", vim.log.levels.ERROR)
			return
		end
	end
	local result = vim.system(
		{ "rg", "--vimgrep", "--no-messages", "-e", M.rg_pattern() },
		{ text = true, cwd = vim.fn.getcwd() }
	):wait()
	local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
	vim.fn.setqflist({}, " ", { title = "Todo", lines = lines })
	vim.cmd.copen()
end

function M.pick()
	Snacks.picker.grep({ search = M.rg_pattern(), regex = true, live = false, title = "Todo" })
end

local function define_highlights()
	for _, entry in ipairs(M.keywords) do
		local target = vim.api.nvim_get_hl(0, { name = entry.link, link = false })
		local kw = vim.tbl_extend("force", {}, target, { reverse = true, default = true })
		vim.api.nvim_set_hl(0, "K6eTodoKw" .. entry.kind, kw)
		vim.api.nvim_set_hl(0, "K6eTodoText" .. entry.kind, { link = entry.link, default = true })
	end
end

local function in_comment(buf, row, col)
	local ok, captures = pcall(vim.treesitter.get_captures_at_pos, buf, row, col)
	if not ok then
		return false
	end
	for _, capture in ipairs(captures) do
		if vim.startswith(capture.capture, "comment") then
			return true
		end
	end
	return false
end

local enabled_bufs = {}

local function on_win(_, _, buf)
	M._last_marks = {}
	local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
	enabled_bufs[buf] = ok and parser ~= nil and parser ~= false
	return enabled_bufs[buf]
end

local function on_line(_, _, buf, row)
	if not enabled_bufs[buf] then
		return
	end
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
	if not line then
		return
	end
	local m = M.match(line)
	if not m or not in_comment(buf, row, m.kw_start) then
		return
	end
	local kw_hl = "K6eTodoKw" .. m.kind
	local text_hl = "K6eTodoText" .. m.kind
	vim.api.nvim_buf_set_extmark(buf, ns, row, m.kw_start, { end_col = m.kw_end, hl_group = kw_hl, ephemeral = true })
	M._last_marks[#M._last_marks + 1] = { row = row, col = m.kw_start, hl = kw_hl }
	if m.kw_end < #line then
		vim.api.nvim_buf_set_extmark(buf, ns, row, m.kw_end, { end_col = #line, hl_group = text_hl, ephemeral = true })
		M._last_marks[#M._last_marks + 1] = { row = row, col = m.kw_end, hl = text_hl }
	end
end

function M.setup()
	define_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("k6e.todo", { clear = true }),
		callback = define_highlights,
	})
	vim.api.nvim_set_decoration_provider(ns, { on_win = on_win, on_line = on_line })
	local todo = require("core.keymaps").owner("todo")
	todo.eager("<leader>tt", M.pick, "Todo list (Picker)")
	todo.eager("<leader>tq", M.quickfix, "Todo list (Quickfix)")
end

return M
