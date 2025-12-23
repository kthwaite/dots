local au = require("core.utility").au

-- # helm filetype
vim.filetype.add({
	filename = {

		["helmfile*.yaml"] = "helm",
	},
	extension = {
		gotmpl = "helm",
	},
	pattern = {
		["*/templates/*.yaml"] = "helm",
		["*/templates/*.tpl"] = "helm",
	},
})
-- Use {{/* */}} as comments
au("FileType", "helm", "setlocal commentstring={{/* %s */}}")

-- # falls filetype
vim.filetype.add({ extension = { fall = "falls" } })
-- # age filetype
vim.filetype.add({ pattern = { ["*.age"] = "age" } })
