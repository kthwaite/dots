require("core.external_tools").capture()

-- ==== Prelims
local keymaps = require("core.keymaps")
local editing = keymaps.owner("editing")
local insert = keymaps.owner("insert")
local search = keymaps.owner("search")
local window = keymaps.owner("window")

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
search.eager("/", "/\\v", "Search with very magic", { silent = false })
-- search magic by default
search.eager("%s/", "%s/\\v", "Substitute with very magic", { mode = "c", silent = false })
-- yank
editing.eager("Y", "y$", "Yank to end of line", { silent = false })
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
insert.eager("jk", "<esc>", "Leave insert mode", { mode = "i", silent = false })
insert.eager("<esc>", "<nop>", "Disable Escape in insert mode", { mode = "i", silent = false })
-- # splits
-- remap split navigation
window.eager("<C-h>", "<C-w>h", "Move to left split.", { mode = { "n", "v", "o" }, silent = false })
window.eager("<C-j>", "<C-w>j", "Move to down split.", { mode = { "n", "v", "o" }, silent = false })
window.eager("<C-k>", "<C-w>k", "Move to up split.", { mode = { "n", "v", "o" }, silent = false })
window.eager("<C-l>", "<C-w>l", "Move to right split.", { mode = { "n", "v", "o" }, silent = false })
-- horizontal split to vertical split
window.eager("<leader>hv", "<C-w>t<C-w>H", "Horizontal split to vertical split.", { silent = false })
-- vertical split to horizontal split
window.eager("<leader>vh", "<C-w>t<C-w>K", "Vertical split to horizontal split.", { silent = false })
