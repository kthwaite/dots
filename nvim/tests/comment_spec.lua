local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(source, ":p:h:h")
vim.opt.runtimepath:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	package.path,
}, ";")

local tests = {}
local function test(name, callback)
	tests[#tests + 1] = { name = name, callback = callback }
end

local function equal(actual, expected, message)
	if not vim.deep_equal(actual, expected) then
		error(string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
	end
end

local function truthy(value, message)
	if not value then
		error(message)
	end
end

local function new_buffer(lines, filetype, commentstring)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(bufnr)
	vim.bo[bufnr].filetype = filetype
	if commentstring then
		vim.bo[bufnr].commentstring = commentstring
	end
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	return bufnr
end

local function lines(bufnr)
	return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function fresh_comment()
	package.loaded["k6e.comment"] = nil
	package.loaded["core.keymaps"] = nil
	return require("k6e.comment")
end

local function activated()
	local comment = fresh_comment()
	comment.setup()
	require("core.keymaps").activate()
	return comment
end

local function feed(keys)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

test("get returns rust overrides", function()
	local comment = fresh_comment()
	equal(comment.get("rust"), { line = "// %s", block = "/* %s */" }, "rust templates")
end)

test("get returns lua block override", function()
	local comment = fresh_comment()
	equal(comment.get("lua").block, "--[[ %s ]]", "lua block")
	equal(comment.get("lua").line, "-- %s", "lua line")
end)

test("get covers css and html special cases", function()
	local comment = fresh_comment()
	equal(comment.get("css"), { line = "/* %s */", block = "/* %s */" }, "css")
	equal(comment.get("html"), { line = "<!-- %s -->", block = "<!-- %s -->" }, "html")
end)

test("get falls back to a line commentstring", function()
	local comment = fresh_comment()
	new_buffer({ "x" }, "k6etestline", "# %s")
	equal(comment.get("k6etestline"), { line = "# %s" }, "line fallback")
end)

test("get treats a suffixed commentstring as block and line, padded", function()
	local comment = fresh_comment()
	new_buffer({ "x" }, "k6etestblock", "/*%s*/")
	equal(comment.get("k6etestblock"), { line = "/* %s */", block = "/* %s */" }, "block fallback")
end)

test("toggle_block wraps and unwraps", function()
	local comment = fresh_comment()
	local bufnr = new_buffer({ "int a;", "int b;" }, "c")
	comment.toggle_block(1, 2)
	equal(lines(bufnr), { "/* int a;", "int b; */" }, "wrap")
	comment.toggle_block(1, 2)
	equal(lines(bufnr), { "int a;", "int b;" }, "unwrap")
end)

test("toggle_block keeps indentation", function()
	local comment = fresh_comment()
	local bufnr = new_buffer({ "\tint a;" }, "c")
	comment.toggle_block(1, 1)
	equal(lines(bufnr), { "\t/* int a; */" }, "wrap indented")
	comment.toggle_block(1, 1)
	equal(lines(bufnr), { "\tint a;" }, "unwrap indented")
end)

test("toggle_block falls back to native line comment without block", function()
	local comment = fresh_comment()
	local bufnr = new_buffer({ "x" }, "python", "# %s")
	comment.toggle_block(1, 1)
	equal(lines(bufnr), { "# x" }, "native fallback")
end)

test("gbc keeps the cursor in place", function()
	activated()
	local bufnr = new_buffer({ "int a;", "int b;" }, "c")
	vim.api.nvim_win_set_cursor(0, { 1, 4 })
	feed("gbc")
	equal(lines(bufnr), { "/* int a; */", "int b;" }, "gbc wrapped")
	equal(vim.api.nvim_win_get_cursor(0), { 1, 4 }, "cursor restored")
end)

test("gbc honours a count", function()
	activated()
	local bufnr = new_buffer({ "int a;", "int b;", "int c;", "int d;" }, "c")
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	feed("3gbc")
	equal(lines(bufnr), { "int a;", "/* int b;", "int c;", "int d; */" }, "3gbc wraps three lines")
	equal(vim.api.nvim_win_get_cursor(0), { 2, 0 }, "cursor restored")
	feed("9gbc")
	equal(lines(bufnr), { "int a;", "int b;", "int c;", "int d;" }, "count past the end stops at the last line")
end)

test("gb operator wraps a motion", function()
	activated()
	local bufnr = new_buffer({ "int a;", "int b;", "int c;" }, "c")
	feed("gbj")
	equal(lines(bufnr), { "/* int a;", "int b; */", "int c;" }, "gbj wrapped two lines")
	equal(vim.api.nvim_win_get_cursor(0), { 1, 0 }, "cursor restored")
end)

test("gb in visual mode wraps the selection lines", function()
	activated()
	local bufnr = new_buffer({ "int a;", "int b;", "int c;" }, "c")
	feed("Vjgb")
	equal(lines(bufnr), { "/* int a;", "int b; */", "int c;" }, "visual gb")
end)

test("gco opens a commented line below", function()
	activated()
	local bufnr = new_buffer({ "\tint a;" }, "c")
	feed("gcox<Esc>")
	equal(lines(bufnr)[2], "\t// x", "gco line with indent")
end)

test("gcO opens a commented line above", function()
	activated()
	local bufnr = new_buffer({ "\tint a;" }, "c")
	feed("gcOx<Esc>")
	equal(lines(bufnr), { "\t// x", "\tint a;" }, "gcO line")
end)

test("gcA appends a comment at end of line", function()
	activated()
	local bufnr = new_buffer({ "int a;" }, "c")
	feed("gcAx<Esc>")
	equal(lines(bufnr), { "int a; // x" }, "gcA line")
end)

test("gco with a suffixed template puts the cursor inside", function()
	activated()
	local bufnr = new_buffer({ "<p>" }, "html")
	feed("gcox<Esc>")
	equal(lines(bufnr)[2], "<!-- x -->", "html gco")
end)

test("setup maps gb in normal and visual mode", function()
	activated()
	truthy(vim.fn.maparg("gb", "n", false, true).desc ~= nil, "gb normal mapped")
	truthy(vim.fn.maparg("gb", "x", false, true).desc ~= nil, "gb visual mapped")
end)

local failures = {}
for _, case in ipairs(tests) do
	local ok, err = pcall(case.callback)
	if not ok then
		failures[#failures + 1] = case.name .. ": " .. err
	end
end

if #failures > 0 then
	error(table.concat(failures, "\n"))
end
