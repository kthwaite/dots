-- FIXME: pull from config
local vault = vim.fn.expand("~/Documents/vault")

return {
	root_dir = function(bufnr, on_dir)
		local name = vim.api.nvim_buf_get_name(bufnr)
		if name == vault or name:sub(1, #vault + 1) == vault .. "/" then
			on_dir(vault)
		end
	end,
}
