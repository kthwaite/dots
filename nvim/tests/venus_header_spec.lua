local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(source, ":p:h:h")
vim.opt.runtimepath:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	package.path,
}, ";")

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

local function raises_exact(callback, expected)
	local ok, err = pcall(callback)
	equal(ok, false, ("expected error %q"):format(expected))
	equal(err:match("Venus row .*$"), expected, "unexpected Venus decoder error")
end

local venus = require("plugins.headers.venus")
local header = venus.render()

equal(header.type, "text", "Venus element type changed")
equal(header.opts.position, "center", "Venus position changed")
equal(#header.val, 44, "Venus row count changed")
equal(#header.opts.hl, 44, "Venus highlight row count changed")
for row_number, text in ipairs(header.val) do
	equal(#text, 84, ("Venus row %d width changed"):format(row_number))
end

equal(
	vim.fn.sha256(table.concat(header.val, "\n")),
	"432712b708d0f30e8e72e9b2cc6c6b062abe6c2c7392d8cdac705336a28419cb",
	"Venus text changed"
)

local color_rows = {}
for row_number, spans in ipairs(header.opts.hl) do
	local cells = {}
	local next_column = 0
	local previous_group
	for _, span in ipairs(spans) do
		equal(span[2], next_column, ("Venus row %d spans have a gap or overlap"):format(row_number))
		truthy(span[3] > span[2], ("Venus row %d contains an empty span"):format(row_number))
		truthy(span[1] ~= previous_group, ("Venus row %d contains adjacent equal spans"):format(row_number))

		local highlight = vim.api.nvim_get_hl(0, { name = span[1] })
		local color = string.format("#%06x", highlight.fg)
		for column = span[2] + 1, span[3] do
			cells[column] = color
		end
		next_column = span[3]
		previous_group = span[1]
	end
	equal(next_column, 84, ("Venus row %d spans do not cover all columns"):format(row_number))
	color_rows[row_number] = table.concat(cells)
end

equal(
	vim.fn.sha256(table.concat(color_rows, "\n")),
	"d6d80627d3b47e976b606bf6727a3eedeb3e04e9128da676b6f4642fba85b159",
	"Venus colors changed"
)

raises_exact(function()
	venus.compile({ { text = "ab", colors = "x" } }, { x = "#000000" })
end, "Venus row 1 has 2 glyphs but 1 colors")

raises_exact(function()
	venus.compile({ { text = "a", colors = "x" } }, {})
end, 'Venus row 1 column 1 uses unknown palette key "x"')
