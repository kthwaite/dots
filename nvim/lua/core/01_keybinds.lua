---@type Elle
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
	--vim.lsp.buf.format({ async = true })
	require("conform").format({ bufnr = args.buf })
end, { group = fmt_group })

-- highlight text on yank
local util_group = vim.api.nvim_create_augroup("k6e_util", { clear = true })
au("TextYankPost", "*", function()
	vim.highlight.on_yank({ higroup = "IncSearch", timeout = 350 })
end, { group = util_group })

-- Open a terminal at the bottom of the screen with a fixed height.
n("<leader>st", function()
	vim.cmd.new()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 12)
	vim.wo.winfixheight = true
	vim.cmd.term()
end, { desc = "Open a terminal at the bottom of the screen." })

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

-- ## Plugins ##
-- # lazy
n("<leader>lu", ":Lazy update<CR>", { desc = "Update all plugins." })
n("<leader>ls", ":Lazy sync<CR>", { desc = "Sync all plugins." })

-- # mason
n("<leader>mo", ":Mason<CR>", { desc = "Open Mason." })
n("<leader>mu", ":MasonUpdate<CR>", { desc = "Update all Mason packages." })

-- close hidden buffers
n("<leader>Bd", ":up | %bd | e#<cr>", { desc = "Close all hidden buffers." })

-- # neotree
-- toggle neotree
n("<leader>ft", ":Neotree toggle<CR>", { desc = "Toggle Neotree." })

-- # telescope
n("<leader>to", ":Telescope<cr>", { desc = "Open Telescope." })
n("<leader>tg", ":Telescope live_grep<cr>", { desc = "Telescope live_grep." })
n("<leader>tf", ":Telescope find_files<cr>", { desc = "Telescope find_files." })
n("<leader>tb", ":Telescope buffers<cr>", { desc = "Telescope buffers." })
n("<leader>tr", ":Telescope registers<cr>", { desc = "Telescope registers." })

--- # lsp
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("k6e_lsp", {}),
	---Set up LSP keybinds on attach
	---@param ev vim.api.keyset.create_autocmd.callback_args
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		local bufnr = ev.buf
		---Helper function to create a keymap
		---@param key string
		---@param func function
		---@param desc string
		local function n(key, func, desc)
			local opts = { noremap = true, silent = true, buffer = bufnr }
			opts["desc"] = desc or ""
			vim.keymap.set("n", key, func, opts)
		end
		n("gD", vim.lsp.buf.declaration, "Go to declaration")
		n("gd", vim.lsp.buf.definition, "Go to definition")
		n("K", vim.lsp.buf.hover, "Hover documentation")
		n("gi", vim.lsp.buf.implementation, "Go to implementation")
		n("<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, "List workspace folders")
		n("<space>D", vim.lsp.buf.type_definition, "Go to type definition")
		n("<space>rn", vim.lsp.buf.rename, "Rename symbol")
		n("<space>ca", vim.lsp.buf.code_action, "Code action")
		n("gr", vim.lsp.buf.references, "List references to symbol")
		n("[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, "Previous diagnostic")
		n("]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, "Next diagnostic")
		n("<space>f", function()
			vim.lsp.buf.format({ async = true })
		end, "Format buffer")
	end,
})
