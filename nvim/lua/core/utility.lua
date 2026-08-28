local M = {}

---@param event string # event name
---@param pattern string # pattern to match
---@param callback string|function # callback command or function
---@param opts? table # options passed to nvim_create_autocmd
M.au = function(event, pattern, callback, opts)
	local cbtype = "command"
	if type(callback) == "function" then
		cbtype = "callback"
	end
	opts = opts or {}
	opts["pattern"] = pattern
	opts[cbtype] = callback
	vim.api.nvim_create_autocmd(event, opts)
end

---Get the current version of Neovim as a string in the form "v0.0.0"
M.version_string = function()
	local version = vim.version()
	local version_line = "UNKNOWN"
	if version ~= nil then
		version_line = " v" .. version.major .. "." .. version.minor .. "." .. version.patch
	end
	return version_line
end

--- Insert a section header comment at the cursor position
--- Uses Comment.nvim to get the appropriate comment string for the filetype
---@param width? number # total width of the header (default 80)
M.insert_section_header = function(width)
	width = width or 80

	-- Get the comment string from Comment.nvim
	local ok, ft = pcall(require, "Comment.ft")
	local comment_str = "//"
	if ok then
		local cs = ft.get(vim.bo.filetype)
		if cs then
			-- ft.get returns line comment string or a table with line/block strings
			if type(cs) == "table" then
				if cs.line then
					comment_str = cs.line
				elseif cs.block then
					comment_str = cs.block[1] or cs.block
				else
					comment_str = cs[1] or "//"
				end
			else
				comment_str = cs
			end
		end
	else
		-- Fallback to commentstring
		local cs = vim.bo.commentstring
		if cs and cs ~= "" then
			-- commentstring is like "// %s" or "/* %s */"
			comment_str = cs
		end
	end

	-- Normalize comment string to a prefix
	if type(comment_str) == "string" and comment_str:find("%%s") then
		comment_str = (comment_str:match("^(.-)%%s") or comment_str):gsub("%s*$", "")
	end

	-- Prompt for the section title
	vim.ui.input({ prompt = "Section title: " }, function(title)
		if not title or title == "" then
			return
		end

		-- Calculate padding width (accounting for comment prefix + space)
		local prefix = comment_str .. " "
		local fill_width = width - #prefix
		local separator = prefix .. string.rep("=", fill_width)
		local title_line = prefix .. title

		-- Insert the header at current cursor position
		local row = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, {
			separator,
			title_line,
			separator,
		})
	end)
end

M.default_ignore_filetypes = {
	"",
	"TelescopePrompt",
	"alpha",
	"cmp_menu",
	"health",
	"mason",
	"mason-lspconfig",
	"noice",
	"none",
	"terminal",
}

return M
