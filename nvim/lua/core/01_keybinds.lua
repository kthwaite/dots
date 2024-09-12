local util  = require("core.utility")
local au = util.au
local n = util.nnoremap

-- ## autocommands ##

-- # format on save
-- targets for autoformat on write
local format_patterns = {
	"*.py",
	"*.lua",
	"*.rs",
	"*.sql",
	"*.js",
	"*.jsx",
	"*.ts",
	"*.tsx",
	"*.c",
	"*.cpp",
	"*.h",
	"*.hpp",
	"*.json",
}
-- autoformat buffer on write
local fmt_group = vim.api.nvim_create_augroup("kt_fmt", { clear = true })
au("BufWritePre", table.concat(format_patterns, ","), function()
	vim.lsp.buf.format({ async = true })
end, { group = fmt_group })

-- highlight text on yank
local util_group = vim.api.nvim_create_augroup("kt_util", { clear = true })
au("TextYankPost", "*", function()
	vim.highlight.on_yank({ higroup = "IncSearch", timeout = 350 })
end, { group = util_group })

-- ## Plugins ##
-- # lazy
n("<leader>lu", ":Lazy update<CR>")
n("<leader>ls", ":Lazy sync<CR>")

-- # mason
n("<leader>mo", ":Mason<CR>")
n("<leader>mu", ":MasonUpdate<CR>")

-- close hidden buffers
n("<leader>Bd", ":up | %bd | e#<cr>")

-- # neotree
-- toggle neotree
n("<leader>ft", ":Neotree toggle<CR>")

-- # telescope
n("<leader>to", ":Telescope<cr>")
n("<leader>tg", ":Telescope live_grep<cr>")
n("<leader>tf", ":Telescope find_files<cr>")
n("<leader>tb", ":Telescope buffers<cr>")
n("<leader>tr", ":Telescope registers<cr>")
