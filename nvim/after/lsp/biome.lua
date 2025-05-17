--- Appends `new_names` to `root_files` if `field` is found in any such file in any ancestor of `fname`.
---
--- NOTE: this does a "breadth-first" search, so is broken for multi-project workspaces:
--- https://github.com/neovim/nvim-lspconfig/issues/3818#issuecomment-2848836794
---
--- @param root_files string[] List of root-marker files to append to.
--- @param new_names string[] Potential root-marker filenames (e.g. `{ 'package.json', 'package.json5' }`) to inspect for the given `field`.
--- @param field string Field to search for in the given `new_names` files.
--- @param fname string Full path of the current buffer name to start searching upwards from.
local root_markers_with_field = function(root_files, new_names, field, fname)
	local path = vim.fn.fnamemodify(fname, ":h")
	local found = vim.fs.find(new_names, { path = path, upward = true })

	for _, f in ipairs(found or {}) do
		-- Match the given `field`.
		for line in io.lines(f) do
			if line:find(field) then
				root_files[#root_files + 1] = vim.fs.basename(f)
				break
			end
		end
	end

	return root_files
end

local insert_package_json = function(root_files, field, fname)
	return root_markers_with_field(root_files, { "package.json", "package.json5" }, field, fname)
end
return {
	cmd = { "bun", "--bunx", "biome", "lsp-proxy" },
	filetypes = {
		"astro",
		"css",
		"graphql",
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"json",
		"jsonc",
		"svelte",
		"typescript",
		"typescript.tsx",
		"typescriptreact",
		"vue",
	},
	root_dir = function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		local root_files = { "biome.json", "biome.jsonc" }
		root_files = insert_package_json(root_files, "biome", fname)
		local root_dir = vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1])
		on_dir(root_dir)
	end,
}
