-- ==== Prelims
local util = require("core.utility")
local map = util.map
local nnoremap = util.nnoremap
local inoremap = util.inoremap
local noremap = util.noremap

-- ==== Setup ===================================================================
vim.g.loaded_ruby_provider = 0 -- disable ruby provider
vim.g.loaded_node_provider = 0 -- disable node provider
vim.g.loaded_perl_provider = 0 -- disable perl provider
vim.g.have_nerd_font = true -- enable nerd font by default
vim.g.mapleader = " " -- map leader to space
vim.g.localleader = " " -- map localleader to space
vim.opt.shell = "zsh -l" -- use zsh as default shell
vim.opt.termguicolors = true -- enable true color
vim.opt.encoding = "utf-8" -- default encoding is utf-8
vim.opt.fileformats = "unix,dos,mac" -- prefer Unix over Windows over OS 9 formats
vim.opt.history = 1000 -- 1000 lines of history
vim.o.shortmess = "filmnorstxwFOTW" -- [noeol], 00L/00C, [+], [New], [RO], [unix]
-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

vim.opt.autoread = true -- auto-reload modified files
vim.opt.swapfile = false -- no swapfile
vim.opt.backup = false -- no backup files
vim.opt.bs = "indent,eol,start" -- backspace over everything!
vim.opt.ruler = true -- display cursor position
vim.opt.lazyredraw = false -- faster macro invocation
vim.opt.title = true -- set window title
vim.opt.titlestring = "%t" -- ibid
-- current directory is always window-local
--[[
au("BufEnter", "*", function(ev)
	local buf = vim.bo[ev.buf]
	if buf.buftype ~= "terminal" and not vim.tbl_contains(ignore_filetypes, buf.filetype) then
		vim.cmd("lcd %:p:h")
	end
end)
]]

-- ==== Search ==================================================================
vim.opt.incsearch = true -- show matches while you type
vim.opt.inccommand = "split" -- split window for search
vim.opt.hlsearch = true -- highlight matches
vim.opt.ignorecase = true -- search case insensitive
vim.opt.smartcase = true -- search case-sensitive when uppercase characters appear in search
vim.opt.grepprg = "rg --vimgrep"
-- search magic by default
nnoremap("/", "/\\v")
-- search magic by default
map("c", "%s/", "%s/\\v")
-- yank
nnoremap("Y", "y$")
vim.opt.clipboard = "unnamedplus"

-- enable mouse
-- hide mouse cursor while typing
vim.opt.mouse = "a"
vim.opt.mousehide = true

-- ==== Formatting ==============================================================
vim.opt.wrap = true -- wrap lines
vim.opt.autoindent = true -- keep prev indent
vim.opt.smartindent = true -- smart autoindenting
vim.opt.smarttab = true -- insert shiftwidth blanks
vim.opt.shiftwidth = 4 -- width of shift, spaces
vim.opt.softtabstop = 4 -- number of tab-spaces while editing
vim.opt.expandtab = true -- tabs are spaces
vim.opt.tabstop = 4 -- tabs are worth 4 spaces
vim.opt.list = false -- don't display tabs
vim.opt.formatoptions:remove("o") -- remove comment insertion

-- ==== Filetype-specific indentation ==========================================
-- 2-space with tabs (Lua convention for neovim configs)
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "lua" },
	callback = function()
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.tabstop = 2
		vim.opt_local.expandtab = false
	end,
})
-- 2-space with spaces (JS/TS ecosystem convention)
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	callback = function()
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.tabstop = 2
	end,
})

-- ==== UI ======================================================================
vim.opt.cursorline = true -- highlight current line
vim.opt.showmode = true -- show current mode
vim.api.nvim_set_hl(0, "LineNr", {})
vim.api.nvim_set_hl(0, "SignColumn", {})
vim.opt.number = true -- line numbers on
vim.opt.relativenumber = true -- for fast vertical movement
vim.opt.linespace = 0 -- no extra spaces between rows
-- mkview preserves EVERYTHING
vim.opt.vop = "cursor,folds,options,slash,unix"
vim.opt.virtualedit = "onemore" -- cursor after EOL
vim.opt.showmatch = true -- show search matches
vim.opt.wildmenu = true -- show list for autocomplete
vim.opt.wildmode = "list:longest,full" -- list all matches and complete
vim.opt.colorcolumn = "88,161" -- indicate col80, col161
vim.opt.foldenable = false -- automatic code folding is the devil's work

-- ==== Remaps ==================================================================
-- remap esc to jk
inoremap("jk", "<esc>")
inoremap("<esc>", "<nop>")
-- # splits
-- remap split navigation
noremap("<C-h>", "<C-w>h", { desc = "Move to left split." })
noremap("<C-j>", "<C-w>j", { desc = "Move to down split." })
noremap("<C-k>", "<C-w>k", { desc = "Move to up split." })
noremap("<C-l>", "<C-w>l", { desc = "Move to right split." })
-- horizontal split to vertical split
nnoremap("<leader>hv", "<C-w>t<C-w>H", { desc = "Horizontal split to vertical split." })
-- vertical split to horizontal split
nnoremap("<leader>vh", "<C-w>t<C-w>K", { desc = "Vertical split to horizontal split." })

-- ==== LSP ====================================================================
-- # diagnostics
vim.diagnostic.config({
	virtual_text = {
		prefix = "●", -- Character to show before the diagnostic message
		spacing = 5, -- Add some space
		source = "if_many", -- Show a prefix like "eslint" only if there are multiple sources
		format = function(diagnostic)
			-- Custom function to format the diagnostic message
			return string.format("[%s] %s: %s", diagnostic.source, diagnostic.severity, diagnostic.message)
		end,
	},
	-- rely on highlight styles instead, don't want to clobber signcolumn
	signs = false,
	-- General options
	update_in_insert = true,
	severity_sort = true,
	float = {
		border = "rounded", -- Border style for floating window
		source = "if_many", -- Show diagnostic source only if there are multiple sources
		header = "",
		prefix = "",
	},
})
vim.api.nvim_create_user_command("LspStatus", function()
	local clients = vim.lsp.get_clients()
	if #clients == 0 then
		vim.notify("No LSP clients running", vim.log.levels.WARN)
		return
	end

	-- Display all active clients
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
