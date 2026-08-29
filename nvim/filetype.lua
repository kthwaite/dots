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
vim.api.nvim_create_autocmd("FileType", {
	pattern = "helm",
	callback = function()
		vim.opt_local.commentstring = "{{/* %s */}}"
	end,
})

-- # falls filetype
vim.filetype.add({ extension = { fall = "falls" } })
-- # age filetype
vim.filetype.add({ pattern = { ["*.age"] = "age" } })
