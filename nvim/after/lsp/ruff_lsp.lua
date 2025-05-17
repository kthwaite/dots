return {
	cmd = { "ruff-lsp" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "ruff.toml", ".git" },
	on_attach = function(client, bufnr)
		client.server_capabilities.hoverProvider = false
	end,
}
