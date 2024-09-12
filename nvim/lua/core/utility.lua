local M = {}

---@param event string # event name
---@param pattern string # pattern to match
---@param callback function # callback function
---@param opts table # options passed to nvim_create_autocmd
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

---Convenience function to create a keymap
M.map = vim.keymap.set

---Convenience function to create a normal mode keymap
---@param capt string # keymap capture
---@param repl string # keymap replacement
---@param opts table # options passed to nvim_set_keymap
M.nnoremap = function(capt, repl, opts)
	opts = opts or {}
	opts["noremap"] = true
	vim.keymap.set("n", capt, repl, opts)
end

---Convenience function to create an insert mode keymap
---@param capt string # keymap capture
---@param repl string # keymap replacement
---@param opts table # options passed to nvim_set_keymap
M.inoremap = function(capt, repl, opts)
	opts = opts or {}
	opts["noremap"] = true
	vim.keymap.set("i", capt, repl, opts)
end

M.noremap = function(capt, repl, opts)
	opts = opts or {}
	opts["noremap"] = true
	vim.keymap.set("", capt, repl, opts)
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

return M
