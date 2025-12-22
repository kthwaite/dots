local util = require("core.utility")
local au = util.au
local n = util.nnoremap

-- ## autocommands ##

-- # format on save
-- targets for autoformat on write
local format_patterns = {
	"*.c",
	"*.cpp",
	"*.h",
	"*.hpp",
	"*.js",
	"*.json",
	"*.jsx",
	"*.lua",
	"*.py",
	"*.rs",
	"*.sql",
	"*.ts",
	"*.tsx",
}
-- autoformat buffer on write
local fmt_group = vim.api.nvim_create_augroup("k6e_fmt", { clear = true })
au("BufWritePre", table.concat(format_patterns, ","), function(args)
	require("conform").format({ bufnr = args.buf })
end, { group = fmt_group })

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

-- # terminal
-- Open a terminal at the bottom of the screen with a fixed height.
n("<leader>st", function()
	vim.cmd.new()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 12)
	vim.wo.winfixheight = true
	vim.cmd.term()
end, { desc = "Open a terminal at the bottom of the screen." })
-- terminal
n("<leader>vt", function()
	vim.cmd.vsplit()
	vim.cmd.terminal()
	vim.cmd.startinsert()
end, { desc = "Open terminal in a vertical split" })

-- # split navigation
n("<leader>sl", "<C-w>l", { desc = "Move to the left split." })
n("<leader>sh", "<C-w>r", { desc = "Move to the right split." })
n("<leader>sj", "<C-w>j", { desc = "Move to the bottom split." })
n("<leader>sk", "<C-w>k", { desc = "Move to the top split." })

-- # tabs
n("<leader>tn", ":tabnext<CR>", { desc = "Go to next tab." })
n("<leader>tp", ":tabprevious<CR>", { desc = "Go to previous tab." })
n("<leader>tc", ":tabnew<CR>", { desc = "Create a new tab." })
n("<leader>tx", ":tabclose<CR>", { desc = "Close current tab." })

-- # buffers
-- close hidden buffers
n("<leader>Bd", function()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_get_option_value("buflisted", { buf = buf }) and not vim.api.nvim_buf_is_loaded(buf) then
			vim.api.nvim_buf_delete(buf, { force = false })
		end
	end
end, { desc = "Close all hidden buffers." })

-- ## Plugins ##

-- # lazy
n("<leader>lu", ":Lazy update<CR>", { desc = "Update all plugins." })
n("<leader>ls", ":Lazy sync<CR>", { desc = "Sync all plugins." })

-- # mason
n("<leader>mo", ":Mason<CR>", { desc = "Open Mason." })
n("<leader>mu", ":MasonUpdate<CR>", { desc = "Update all Mason packages." })

-- # neotree
-- toggle neotree
n("<leader>ft", ":Neotree toggle<CR>", { desc = "Toggle Neotree." })

-- # telescope
n("<leader>to", ":Telescope<cr>", { desc = "Open Telescope." })
n("<leader>tg", ":Telescope live_grep<cr>", { desc = "Telescope live_grep." })
n("<leader>tf", ":Telescope find_files<cr>", { desc = "Telescope find_files." })
n("<leader>tb", ":Telescope buffers<cr>", { desc = "Telescope buffers." })
n("<leader>tr", ":Telescope registers<cr>", { desc = "Telescope registers." })

-- ## LSP ##

local lsp_group = vim.api.nvim_create_augroup("k6e_lsp", {})

vim.api.nvim_create_autocmd("LspAttach", {
	---Set up LSP keybinds on attach
	---@param ev vim.api.keyset.create_autocmd.callback_args
	callback = function(ev)
		-- local client = vim.lsp.get_client_by_id(ev.data.client_id)
		local bufnr = ev.buf
		---Helper function to create a keymap
		---@param key string
		---@param func function
		---@param desc string
		local function _n(key, func, desc)
			local opts = { silent = true, buffer = bufnr, desc = desc or "" }
			n(key, func, opts)
		end
		_n("gD", vim.lsp.buf.declaration, "Go to declaration")
		_n("gd", vim.lsp.buf.definition, "Go to definition")
		_n("K", vim.lsp.buf.hover, "Hover documentation")
		_n("gi", vim.lsp.buf.implementation, "Go to implementation")
		_n("<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, "List workspace folders")
		_n("<space>D", vim.lsp.buf.type_definition, "Go to type definition")
		_n("<space>rn", vim.lsp.buf.rename, "Rename symbol")
		_n("<space>ca", vim.lsp.buf.code_action, "Code action")
		_n("gr", vim.lsp.buf.references, "List references to symbol")
		_n("[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, "Previous diagnostic")
		_n("]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, "Next diagnostic")
		_n("<space>f", function()
			vim.lsp.buf.format({ async = true })
		end, "Format buffer")
	end,
	group = lsp_group,
})
