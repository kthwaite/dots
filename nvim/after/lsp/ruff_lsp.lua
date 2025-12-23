-- Ruff LSP handles linting and formatting for Python.
-- Pyright handles type checking and hover documentation.
-- We disable hover here to avoid duplicate hover popups (pyright's are more detailed).
return {
	cmd = { "ruff-lsp" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "ruff.toml", ".git" },
	on_attach = function(client, bufnr)
		client.server_capabilities.hoverProvider = false
	end,
}
