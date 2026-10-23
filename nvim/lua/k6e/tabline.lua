local M = {}

local PICK_ALPHABET = "asdfjklghqwertyuiopzxcvbnm"

---@type integer[]
local order = {}

--- bufnr -> pick label, only while a pick is in progress.
---@type table<integer, string>?
local pick_labels = nil

local group = vim.api.nvim_create_augroup("k6e.tabline", { clear = false })

---@param buf integer
---@return integer?
local function index_of(buf)
	for i, b in ipairs(order) do
		if b == buf then
			return i
		end
	end
end

---@param buf integer
local function add(buf)
	if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and not index_of(buf) then
		order[#order + 1] = buf
	end
end

---@param buf integer
local function remove(buf)
	local i = index_of(buf)
	if i then
		table.remove(order, i)
	end
end

--- Redraw the tabline. Without a UI (nvim -l, --headless) :redrawtabline
--- crashes nvim 0.12.6 intermittently, and there is nothing to draw anyway.
function M.redraw()
	if #vim.api.nvim_list_uis() > 0 then
		vim.cmd.redrawtabline()
	end
end

---@return integer[]
function M.order()
	return vim.list_slice(order)
end

local function define_highlights()
	local function link(name, target)
		vim.api.nvim_set_hl(0, name, { link = target, default = true })
	end
	link("K6eTablineCurrent", "TabLineSel")
	link("K6eTablineBuffer", "TabLine")
	link("K6eTablineFill", "TabLineFill")
	link("K6eTablineModified", "DiagnosticWarn")
	link("K6eTablineError", "DiagnosticError")
	link("K6eTablineWarn", "DiagnosticWarn")
	local search = vim.api.nvim_get_hl(0, { name = "Search", link = false })
	search.bold = true
	search.default = true
	vim.api.nvim_set_hl(0, "K6eTablinePick", search)
end

--- Display name per buffer. Parent directories are prepended until tails are unique.
---@param bufs integer[]
---@return table<integer, string>
function M.names(bufs)
	---@type table<integer, string[]>
	local parts = {}
	---@type table<integer, integer>
	local depth = {}
	for _, buf in ipairs(bufs) do
		local name = vim.api.nvim_buf_get_name(buf)
		parts[buf] = name == "" and {} or vim.split(name, "/", { plain = true, trimempty = true })
		depth[buf] = 1
	end
	local function label(buf)
		local p = parts[buf]
		if #p == 0 then
			return "[No Name]"
		end
		return table.concat(p, "/", math.max(1, #p - depth[buf] + 1))
	end
	local labels = {}
	for _ = 1, 64 do
		local seen = {}
		for _, buf in ipairs(bufs) do
			labels[buf] = label(buf)
			seen[labels[buf]] = seen[labels[buf]] or {}
			table.insert(seen[labels[buf]], buf)
		end
		local changed = false
		for _, group_bufs in pairs(seen) do
			if #group_bufs > 1 then
				for _, buf in ipairs(group_bufs) do
					if depth[buf] < #parts[buf] then
						depth[buf] = depth[buf] + 1
						changed = true
					end
				end
			end
		end
		if not changed then
			break
		end
	end
	for _, buf in ipairs(bufs) do
		labels[buf] = label(buf)
	end
	return labels
end

---@param buf integer
---@return string
local function icon_for(buf)
	local ok, devicons = pcall(require, "nvim-web-devicons")
	if not ok then
		return ""
	end
	local path = vim.api.nvim_buf_get_name(buf)
	local icon = devicons.get_icon(vim.fn.fnamemodify(path, ":t"), vim.fn.fnamemodify(path, ":e"), { default = true })
	return icon or ""
end

---@param text string
---@param max integer
---@return string
local function truncate(text, max)
	if vim.api.nvim_strwidth(text) <= max then
		return text
	end
	max = math.max(max, 1)
	local chars = vim.fn.strchars(text)
	while chars > 0 and vim.api.nvim_strwidth(vim.fn.strcharpart(text, 0, chars)) + 1 > max do
		chars = chars - 1
	end
	return vim.fn.strcharpart(text, 0, chars) .. "…"
end

---@param s string
---@return string
local function escape(s)
	return (s:gsub("%%", "%%%%"))
end

---@param buf integer
---@param name string
---@param current boolean
---@param max_name integer? maximum display width for the name
---@return string rendered
---@return integer width
local function cell(buf, name, current, max_name)
	local base = current and "K6eTablineCurrent" or "K6eTablineBuffer"
	local pick = pick_labels and pick_labels[buf]
	local icon = icon_for(buf)
	local plain_parts = { " " }
	local out = { "%#" .. base .. "#", "%" .. buf .. "@v:lua.K6eTablineClick@", " " }
	if pick then
		out[#out + 1] = "%#K6eTablinePick#" .. escape(pick) .. "%#" .. base .. "# "
		plain_parts[#plain_parts + 1] = pick .. " "
	elseif icon ~= "" then
		out[#out + 1] = escape(icon) .. " "
		plain_parts[#plain_parts + 1] = icon .. " "
	end
	local extra = {}
	local extra_plain = {}
	if vim.bo[buf].modified then
		extra[#extra + 1] = "%#K6eTablineModified# ●%#" .. base .. "#"
		extra_plain[#extra_plain + 1] = " ●"
	end
	local count = vim.diagnostic.count(buf)
	local errors = count[vim.diagnostic.severity.ERROR] or 0
	local warns = count[vim.diagnostic.severity.WARN] or 0
	if errors > 0 then
		extra[#extra + 1] = "%#K6eTablineError# E" .. errors .. "%#" .. base .. "#"
		extra_plain[#extra_plain + 1] = " E" .. errors
	elseif warns > 0 then
		extra[#extra + 1] = "%#K6eTablineWarn# W" .. warns .. "%#" .. base .. "#"
		extra_plain[#extra_plain + 1] = " W" .. warns
	end
	local tail = " %X%" .. buf .. "@v:lua.K6eTablineClose@×%X "
	local tail_plain = " × "
	local fixed = vim.api.nvim_strwidth(table.concat(plain_parts) .. table.concat(extra_plain) .. tail_plain)
	if max_name then
		name = truncate(name, math.max(1, max_name - fixed))
	end
	out[#out + 1] = escape(name)
	out[#out + 1] = table.concat(extra)
	out[#out + 1] = tail
	local width = fixed + vim.api.nvim_strwidth(name)
	return table.concat(out), width
end

---@return string section
---@return integer width
local function tabpage_section()
	local tabs = vim.api.nvim_list_tabpages()
	if #tabs < 2 then
		return "", 0
	end
	local current = vim.api.nvim_get_current_tabpage()
	local out = { "%=" }
	local width = 0
	for i, tab in ipairs(tabs) do
		local hl = tab == current and "K6eTablineCurrent" or "K6eTablineBuffer"
		out[#out + 1] = "%#" .. hl .. "#%" .. i .. "T " .. i .. " "
		width = width + #tostring(i) + 2
	end
	out[#out + 1] = "%T"
	return table.concat(out), width
end

---@return string
function M.render()
	local section, section_width = tabpage_section()
	local avail = vim.o.columns - section_width
	local n = #order
	local names = M.names(order)
	local current_buf = vim.api.nvim_get_current_buf()
	local c = index_of(current_buf)

	local cells, widths = {}, {}
	for i, buf in ipairs(order) do
		cells[i], widths[i] = cell(buf, names[buf], i == c)
	end

	local first, last = 1, 0
	if c then
		local right = (c < n) and 1 or 0
		local total = widths[c]
		first = c
		if total + right + (c > 1 and 1 or 0) > avail then
			-- Current cell alone does not fit: truncate its name.
			local marks = right + (c > 1 and 1 or 0)
			cells[c], widths[c] = cell(current_buf, names[current_buf], true, math.max(1, avail - marks))
			total = widths[c]
		else
			while first > 1 do
				local nf = first - 1
				if total + widths[nf] + right + (nf > 1 and 1 or 0) > avail then
					break
				end
				total = total + widths[nf]
				first = nf
			end
		end
		last = c
		while last < n do
			local left = first > 1 and 1 or 0
			local nl = last + 1
			if total + widths[nl] + left + (nl < n and 1 or 0) > avail then
				break
			end
			total = total + widths[nl]
			last = nl
		end
	else
		local total = 0
		while last < n do
			local nl = last + 1
			if total + widths[nl] + (nl < n and 1 or 0) > avail then
				break
			end
			total = total + widths[nl]
			last = nl
		end
	end

	local out = {}
	if first > 1 then
		out[#out + 1] = "%#K6eTablineFill#‹"
	end
	for i = first, last do
		out[#out + 1] = cells[i]
	end
	if last < n then
		out[#out + 1] = "%#K6eTablineFill#›"
	end
	out[#out + 1] = "%#K6eTablineFill#"
	out[#out + 1] = section
	return table.concat(out)
end

--- Swap the current buffer with its neighbour. Does not wrap.
---@param delta integer
function M.move(delta)
	local i = index_of(vim.api.nvim_get_current_buf())
	if not i then
		return
	end
	local j = i + delta
	if j < 1 or j > #order then
		return
	end
	order[i], order[j] = order[j], order[i]
	M.redraw()
end

--- Go to the next or previous buffer in the order. Wraps.
---@param delta integer
function M.cycle(delta)
	if #order == 0 then
		return
	end
	local i = index_of(vim.api.nvim_get_current_buf())
	local target = i and order[(i - 1 + delta) % #order + 1] or order[1]
	vim.api.nvim_set_current_buf(target)
end

function M.pick()
	local labels = {}
	local by_label = {}
	for i, buf in ipairs(order) do
		local label = PICK_ALPHABET:sub(i, i)
		if label == "" then
			break
		end
		labels[buf] = label
		by_label[label] = buf
	end
	pick_labels = labels
	M.redraw()
	local ok, char = pcall(vim.fn.getcharstr)
	pick_labels = nil
	M.redraw()
	local buf = ok and by_label[char] or nil
	if buf and vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_set_current_buf(buf)
	end
end

---@param buf integer
local function delete(buf)
	local snacks = rawget(_G, "Snacks")
	if snacks and snacks.bufdelete then
		snacks.bufdelete(buf)
	else
		local ok, err = pcall(vim.cmd.bdelete, buf)
		if not ok then
			vim.notify(tostring(err), vim.log.levels.WARN)
		end
	end
end

function _G.K6eTablineClick(minwid, _, button, _)
	if button == "l" then
		if vim.api.nvim_buf_is_valid(minwid) then
			vim.api.nvim_set_current_buf(minwid)
		end
	elseif button == "m" then
		delete(minwid)
	end
end

function _G.K6eTablineClose(minwid, _, _, _)
	delete(minwid)
end

function M.setup()
	order = {}
	pick_labels = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		add(buf)
	end
	define_highlights()

	vim.api.nvim_clear_autocmds({ group = group })
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
	vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
		group = group,
		callback = function(ev)
			add(ev.buf)
		end,
	})
	vim.api.nvim_create_autocmd("OptionSet", {
		group = group,
		pattern = "buflisted",
		callback = function(ev)
			if vim.bo[ev.buf].buflisted then
				add(ev.buf)
			else
				remove(ev.buf)
			end
		end,
	})
	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = group,
		callback = function()
			M.redraw()
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = group,
		callback = function(ev)
			remove(ev.buf)
		end,
	})

	vim.o.showtabline = 2
	vim.o.tabline = "%!v:lua.require'k6e.tabline'.render()"

	local owner = require("core.keymaps").owner("tabline")
	owner.eager("<leader>bb", function()
		M.move(-1)
	end, "Move buffer left")
	owner.eager("<leader>bn", function()
		M.move(1)
	end, "Move buffer right")
	owner.eager("<leader>bp", M.pick, "Pick buffer")
	owner.eager("]b", function()
		M.cycle(1)
	end, "Next buffer")
	owner.eager("[b", function()
		M.cycle(-1)
	end, "Previous buffer")
end

return M
