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

local function new_buffer(lines, commentstring)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or { "anchor" })
	vim.bo[bufnr].filetype = "lua"
	vim.bo[bufnr].commentstring = commentstring or "-- %s"
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	return bufnr
end

local function lines(bufnr)
	return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function delete_buffer(bufnr)
	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end
end

local function assert_no_extmarks(bufnr, message)
	local namespace = vim.api.nvim_get_namespaces()["core.section_header"]
	if namespace and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
		equal(vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {}), {}, message)
	end
end

local function unavailable_comment()
	error("Comment.nvim unavailable")
end

local function with_adapters(input, comment_loader, callback)
	local original_input = vim.ui.input
	local original_notify = vim.notify
	local original_loaded = package.loaded["Comment.ft"]
	local original_preload = package.preload["Comment.ft"]
	local original_buffer = vim.api.nvim_get_current_buf()
	local notifications = {}

	vim.ui.input = input
	vim.notify = function(message, level)
		notifications[#notifications + 1] = { message = message, level = level }
	end
	package.loaded["Comment.ft"] = nil
	package.preload["Comment.ft"] = comment_loader

	local ok, err = xpcall(function()
		callback(notifications)
	end, debug.traceback)

	vim.ui.input = original_input
	vim.notify = original_notify
	package.loaded["Comment.ft"] = original_loaded
	package.preload["Comment.ft"] = original_preload
	if vim.api.nvim_buf_is_valid(original_buffer) then
		vim.api.nvim_set_current_buf(original_buffer)
	end

	if not ok then
		error(err, 0)
	end
end

local function with_api_override(name, replacement, callback)
	local original = vim.api[name]
	vim.api[name] = replacement
	local ok, err = xpcall(callback, debug.traceback)
	vim.api[name] = original
	if not ok then
		error(err, 0)
	end
end

local section_header = require("core.section_header")

test("inserts an 80-column line-comment header", function()
	with_adapters(function(_, callback)
		callback("Parser")
	end, function()
		return {
			get = function()
				return { "--%s", "/*%s*/" }
			end,
		}
	end, function(notifications)
		local bufnr = new_buffer({ "anchor" }, "# %s")
		section_header.insert()
		local actual = lines(bufnr)
		equal(#actual, 4, "one insertion must add exactly three lines")
		equal(actual[2], "-- Parser", "title must use Comment.nvim line syntax")
		equal(vim.fn.strdisplaywidth(actual[1]), 80, "opening separator must be 80 display columns")
		equal(vim.fn.strdisplaywidth(actual[3]), 80, "closing separator must be 80 display columns")
		equal(actual[4], "anchor", "header must precede the cursor line")
		equal(notifications, {}, "successful insertion must not notify")
		assert_no_extmarks(bufnr, "success must delete its location extmark")
		delete_buffer(bufnr)
	end)
end)

test("pads raw Comment.nvim block-comment wrappers", function()
	with_adapters(function(_, callback)
		callback("Blocks")
	end, function()
		return {
			get = function()
				return { [2] = "/*%s*/" }
			end,
		}
	end, function(notifications)
		local bufnr = new_buffer({ "anchor" }, "# %s")
		section_header.insert()
		local actual = lines(bufnr)
		equal(actual[1]:sub(1, 3), "/* ", "raw block prefix must receive Comment.nvim padding")
		equal(actual[1]:sub(-3), " */", "raw block suffix must receive Comment.nvim padding")
		equal(actual[2], "/* Blocks */", "raw block title must retain its padded complete wrapper")
		equal(vim.fn.strdisplaywidth(actual[1]), 80, "raw block separator must be 80 display columns")
		equal(vim.fn.strdisplaywidth(actual[3]), 80, "closing raw block separator must be 80 display columns")
		equal(notifications, {}, "valid raw block syntax must not notify")
		assert_no_extmarks(bufnr, "raw block success must delete its location extmark")
		delete_buffer(bufnr)
	end)
end)

test("retains complete fallback block-comment wrappers", function()
	with_adapters(
		function(_, callback)
			callback("Blocks")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" }, "/*%s*/")
			section_header.insert()
			local actual = lines(bufnr)
			equal(#actual, 4, "block header must add exactly three lines")
			for index = 1, 3 do
				truthy(actual[index]:sub(1, 2) == "/*", "every fallback block header line must retain its prefix")
				truthy(actual[index]:sub(-2) == "*/", "every fallback block header line must retain its suffix")
			end
			equal(actual[2], "/*Blocks*/", "fallback syntax must remain unpadded")
			equal(vim.fn.strdisplaywidth(actual[1]), 80, "opening block separator must be 80 display columns")
			equal(vim.fn.strdisplaywidth(actual[3]), 80, "closing block separator must be 80 display columns")
			equal(notifications, {}, "valid fallback syntax must not notify")
			assert_no_extmarks(bufnr, "block success must delete its location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("follows the original logical anchor across buffer changes", function()
	local pending
	with_adapters(
		function(_, callback)
			pending = callback
		end,
		unavailable_comment,
		function(notifications)
			local target = new_buffer({ "anchor", "tail" })
			section_header.insert()
			vim.api.nvim_buf_set_lines(target, 0, 0, false, { "shift-one", "shift-two" })
			vim.api.nvim_win_set_cursor(0, { 4, 0 })
			local other = new_buffer({ "other" })
			pending("Stable")

			local target_lines = lines(target)
			equal(target_lines[1], "shift-one", "concurrent text must remain before the anchor")
			equal(target_lines[2], "shift-two", "concurrent text must remain before the anchor")
			equal(target_lines[4], "-- Stable", "header must follow the moved logical anchor")
			equal(target_lines[6], "anchor", "header must remain immediately before the original anchor")
			equal(lines(other), { "other" }, "current buffer at callback time must remain unchanged")
			equal(notifications, {}, "location-safe insertion must not notify")
			assert_no_extmarks(target, "asynchronous success must delete its location extmark")
			delete_buffer(target)
			delete_buffer(other)
		end
	)
end)

test("treats nil, empty, and blank titles as silent cancellation", function()
	for _, title in ipairs({ false, "", " \t " }) do
		with_adapters(
			function(_, callback)
				if title == false then
					callback(nil)
				else
					callback(title)
				end
			end,
			unavailable_comment,
			function(notifications)
				local bufnr = new_buffer({ "anchor" })
				section_header.insert()
				equal(lines(bufnr), { "anchor" }, "cancelled input must not mutate the buffer")
				equal(notifications, {}, "cancelled input must not notify")
				assert_no_extmarks(bufnr, "cancellation must delete its location extmark")
				delete_buffer(bufnr)
			end
		)
	end
end)

test("trims surrounding title whitespace", function()
	with_adapters(
		function(_, callback)
			callback("  Parser core \t")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" })
			section_header.insert()
			equal(lines(bufnr)[2], "-- Parser core", "title whitespace must be trimmed")
			equal(notifications, {}, "trimmed valid input must not notify")
			assert_no_extmarks(bufnr, "trimmed success must delete its location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("rejects newline input without writing", function()
	with_adapters(
		function(_, callback)
			callback("bad\nheader")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" })
			section_header.insert()
			equal(lines(bufnr), { "anchor" }, "newline input must not mutate the buffer")
			equal(#notifications, 1, "newline input must notify once")
			equal(notifications[1].level, vim.log.levels.ERROR, "newline input must be an error")
			assert_no_extmarks(bufnr, "validation failure must delete its location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("reports a throwing input interface without writing", function()
	with_adapters(
		function()
			error("input unavailable")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" })
			section_header.insert()
			equal(lines(bufnr), { "anchor" }, "throwing input must not mutate the buffer")
			equal(#notifications, 1, "throwing input must notify once")
			equal(notifications[1].level, vim.log.levels.ERROR, "throwing input must be an error")
			assert_no_extmarks(bufnr, "throwing input must delete its location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("rejects missing or malformed comment syntax before mutation", function()
	local malformed = {
		"",
		string.rep("界", 40) .. "%s",
	}
	for _, commentstring in ipairs(malformed) do
		with_adapters(
			function(_, callback)
				callback("Ignored")
			end,
			unavailable_comment,
			function(notifications)
				local bufnr = new_buffer({ "anchor" }, commentstring)
				section_header.insert()
				equal(lines(bufnr), { "anchor" }, "invalid comment syntax must not mutate the buffer")
				equal(#notifications, 1, "invalid comment syntax must notify once")
				equal(notifications[1].level, vim.log.levels.ERROR, "invalid comment syntax must be an error")
				assert_no_extmarks(bufnr, "syntax failure must leave no location extmark")
				delete_buffer(bufnr)
			end
		)
	end
end)

test("rejects deleted, unloaded, and non-modifiable target buffers", function()
	local cases = {
		{
			name = "deleted",
			invalidate = function(bufnr)
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end,
		},
		{
			name = "unloaded",
			invalidate = function(bufnr)
				vim.api.nvim_buf_delete(bufnr, { unload = true })
			end,
		},
		{
			name = "non-modifiable",
			invalidate = function(bufnr)
				vim.bo[bufnr].modifiable = false
			end,
		},
	}

	for _, case in ipairs(cases) do
		local pending
		with_adapters(
			function(_, callback)
				pending = callback
			end,
			unavailable_comment,
			function(notifications)
				local target = new_buffer({ "anchor" })
				section_header.insert()
				local other = new_buffer({ "other" })
				case.invalidate(target)
				pending("Late")
				equal(lines(other), { "other" }, case.name .. " target must not redirect insertion")
				equal(#notifications, 1, case.name .. " target must notify once")
				equal(notifications[1].level, vim.log.levels.ERROR, case.name .. " target must be an error")
				if case.name == "unloaded" then
					truthy(vim.api.nvim_buf_is_valid(target), "unloaded target must remain valid")
					vim.fn.bufload(target)
					truthy(vim.api.nvim_buf_is_loaded(target), "unloaded target must reload for extmark inspection")
					local namespace = vim.api.nvim_get_namespaces()["core.section_header"]
					truthy(namespace ~= nil, "section-header namespace must exist")
					equal(
						vim.api.nvim_buf_get_extmarks(target, namespace, 0, -1, {}),
						{},
						"unloaded failure must delete its location extmark"
					)
				else
					assert_no_extmarks(target, case.name .. " failure must delete its location extmark")
				end
				if vim.api.nvim_buf_is_valid(target) and vim.api.nvim_buf_is_loaded(target) then
					vim.bo[target].modifiable = true
				end
				delete_buffer(target)
				delete_buffer(other)
			end
		)
	end
end)

test("reports a missing target extmark without writing", function()
	local pending
	with_adapters(
		function(_, callback)
			pending = callback
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" })
			section_header.insert()
			local namespace = vim.api.nvim_get_namespaces()["core.section_header"]
			truthy(namespace ~= nil, "section-header namespace must exist")
			vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
			pending("Lost")
			equal(lines(bufnr), { "anchor" }, "missing target extmark must not mutate the buffer")
			equal(#notifications, 1, "missing target extmark must notify once")
			equal(notifications[1].level, vim.log.levels.ERROR, "missing target extmark must be an error")
			assert_no_extmarks(bufnr, "missing target extmark must leave no location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("reports a failing buffer write interface without mutation", function()
	with_adapters(
		function(_, callback)
			callback("Unwritten")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" })
			with_api_override("nvim_buf_set_lines", function()
				error("write unavailable")
			end, function()
				section_header.insert()
			end)
			equal(lines(bufnr), { "anchor" }, "failing buffer write must not mutate the buffer")
			equal(#notifications, 1, "failing buffer write must notify once")
			equal(notifications[1].level, vim.log.levels.ERROR, "failing buffer write must be an error")
			assert_no_extmarks(bufnr, "failing buffer write must delete its location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("uses display width for Unicode wrappers", function()
	with_adapters(
		function(_, callback)
			callback("Unicode")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" }, "界 %s 界")
			section_header.insert()
			local actual = lines(bufnr)
			equal(vim.fn.strdisplaywidth(actual[1]), 80, "Unicode opening separator must be 80 display columns")
			equal(vim.fn.strdisplaywidth(actual[3]), 80, "Unicode closing separator must be 80 display columns")
			equal(actual[2], "界 Unicode 界", "Unicode wrappers must remain complete")
			equal(notifications, {}, "valid Unicode wrappers must not notify")
			assert_no_extmarks(bufnr, "Unicode success must delete its location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("preserves a multibyte title", function()
	with_adapters(
		function(_, callback)
			callback("界面")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" }, "/* %s */")
			section_header.insert()
			local actual = lines(bufnr)
			equal(actual[2], "/* 界面 */", "multibyte title must remain intact")
			equal(vim.fn.strdisplaywidth(actual[1]), 80, "multibyte title header separator must remain 80 columns")
			equal(notifications, {}, "valid multibyte title must not notify")
			assert_no_extmarks(bufnr, "multibyte title success must delete its location extmark")
			delete_buffer(bufnr)
		end
	)
end)

test("uses one atomic three-line mutation and only the first input result", function()
	with_adapters(
		function(_, callback)
			callback("First")
			callback("Second")
		end,
		unavailable_comment,
		function(notifications)
			local bufnr = new_buffer({ "anchor" })
			local changes = {}
			vim.api.nvim_buf_attach(bufnr, false, {
				on_lines = function(_, _, _, firstline, lastline, new_lastline)
					changes[#changes + 1] = {
						firstline = firstline,
						lastline = lastline,
						new_lastline = new_lastline,
					}
				end,
			})
			section_header.insert()
			local actual = lines(bufnr)
			equal(#actual, 4, "one call must perform one three-line insertion")
			equal(actual[2], "-- First", "later callback results must be ignored")
			equal(changes, {
				{
					firstline = 0,
					lastline = 0,
					new_lastline = 3,
				},
			}, "successful insertion must use one atomic three-line text change")
			equal(notifications, {}, "ignored duplicate callbacks must not notify")
			assert_no_extmarks(bufnr, "duplicate callback must leave no location extmark")
			delete_buffer(bufnr)
		end
	)
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
