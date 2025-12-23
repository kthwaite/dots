return {
	settings = {
		cargo = {
			sysroot = vim.fn.trim(vim.fn.system("rustc --print sysroot")),
		},
	},
}
