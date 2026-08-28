local util = require("core.utility")
local au = util.au
local keymaps = require("core.keymaps")
local buffers = keymaps.owner("buffers")
local editing = keymaps.owner("editing")
local lazy = keymaps.owner("lazy")
local mason = keymaps.owner("mason")
local python = keymaps.owner("python")
local rust = keymaps.owner("rust")
local search = keymaps.owner("search")
local tabs = keymaps.owner("tabs")
local terminal = keymaps.owner("terminal")

-- ## autocommands ##

-- highlight text on yank
local util_group = vim.api.nvim_create_augroup("k6e_util", { clear = true })
au("TextYankPost", "*", function()
	vim.highlight.on_yank({ higroup = "IncSearch", timeout = 350 })
end, { group = util_group })

-- vertical help
local help_group = vim.api.nvim_create_augroup("k6e_help", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	pattern = "help",
	callback = function()
		vim.bo.bufhidden = "unload"
		vim.cmd.wincmd("L")
		vim.cmd.wincmd("=")
	end,
	group = help_group,
})

-- ## Keybinds ##

-- # general
-- paste over currently selected text without yanking it
editing.eager("<leader>p", [["_dP]], "Paste over currently selected text without yanking it.", {
	mode = "x",
	silent = false,
})
-- delete text without copying it to the clipboard
editing.eager("<leader>d", [["_d]], "Delete text without copying it to the clipboard.", {
	mode = { "n", "v" },
	silent = false,
})

-- clear highlighting
search.eager("<C-c>", ":nohlsearch<CR>", "Clear search highlighting.", { silent = false })

-- move selected lines up and down in visual mode
editing.eager("J", ":m '>+1<CR>gv=gv", "moves lines down in visual selection", {
	mode = "v",
	silent = false,
})
editing.eager("K", ":m '<-2<CR>gv=gv", "moves lines up in visual selection", {
	mode = "v",
	silent = false,
})

-- keep cursor in place when indenting in visual mode
editing.eager("<", "<gv", "Unindent and keep selection", { mode = "v", silent = false })
editing.eager(">", ">gv", "Indent and keep selection", { mode = "v", silent = false })

-- keep cursor in place when joining lines
editing.eager("J", "mzJ`z", "Join lines without moving cursor", { silent = false })

-- center cursor when moving half a page up or down
editing.eager("<C-d>", "<C-d>zz", "move down in buffer with cursor centered", { silent = false })
editing.eager("<C-u>", "<C-u>zz", "move up in buffer with cursor centered", { silent = false })

-- # terminal
-- Open a terminal at the bottom of the screen with a fixed height.
terminal.eager("<leader>st", function()
	vim.cmd.new()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 12)
	vim.wo.winfixheight = true
	vim.cmd.term()
	vim.cmd.startinsert()
end, "Open a terminal at the bottom of the screen.", { silent = false })
-- Open a terminal in a vertical split.
terminal.eager("<leader>vt", function()
	vim.cmd.vsplit()
	vim.cmd.terminal()
	vim.cmd.startinsert()
end, "Open terminal in a vertical split", { silent = false })

-- # tabs
tabs.eager("<leader>tn", ":tabnext<CR>", "Go to next tab.", { silent = false })
tabs.eager("<leader>tp", ":tabprevious<CR>", "Go to previous tab.", { silent = false })
tabs.eager("<leader>tc", ":tabnew<CR>", "Create a new tab.", { silent = false })
tabs.eager("<leader>tx", ":tabclose<CR>", "Close current tab.", { silent = false })

-- # buffers
-- close hidden buffers
buffers.eager("<leader>Bd", function()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_get_option_value("buflisted", { buf = buf }) and not vim.api.nvim_buf_is_loaded(buf) then
			vim.api.nvim_buf_delete(buf, { force = false })
		end
	end
end, "Close all hidden buffers.", { silent = false })

-- # section headers
editing.eager("<leader>ih", util.insert_section_header, "Insert section header comment", { silent = false })

-- ## Plugins ##

-- # lazy
lazy.eager("<leader>lu", ":Lazy update<CR>", "Update all plugins.", { silent = false })
lazy.eager("<leader>ls", ":Lazy sync<CR>", "Sync all plugins.", { silent = false })

-- # mason
mason.eager("<leader>mo", ":Mason<CR>", "Open Mason.", { silent = false })
mason.eager("<leader>mu", ":MasonUpdate<CR>", "Update all Mason packages.", { silent = false })

-- # filetype scoped
rust.eager("<leader>a", function()
	vim.cmd.RustLsp("codeAction")
end, "Rust code action", { scope = { filetypes = "rust" } })
python.eager("<leader>pi", ":w<cr>:term uv run python -i % <cr>", "Start IPython REPL", {
	scope = { filetypes = "python" },
	silent = false,
})
