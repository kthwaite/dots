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
local fmt_group = vim.api.nvim_create_augroup("kt_fmt", { clear = true })
au("BufWritePre", table.concat(format_patterns, ","), function(args)
	-- vim.lsp.buf.format({ async = true })
	-- require("conform").format({ bufnr = args.buf })
end, { group = fmt_group })

-- highlight text on yank
local util_group = vim.api.nvim_create_augroup("kt_util", { clear = true })
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
