local M = {}

local WIDTH = 80
local namespace = vim.api.nvim_create_namespace("core.section_header")

local function split_template(template, padding)
	if type(template) ~= "string" or template == "" or template:find("[\r\n]") then
		return nil
	end

	local placeholder_start, placeholder_end = template:find("%s", 1, true)
	if not placeholder_start or template:find("%s", placeholder_end + 1, true) then
		return nil
	end

	local prefix = template:sub(1, placeholder_start - 1)
	local suffix = template:sub(placeholder_end + 1)
	if padding then
		if prefix:find("%S$") then
			prefix = prefix .. " "
		end
		if suffix:find("^%S") then
			suffix = " " .. suffix
		end
	end
	local wrapper_width = vim.fn.strdisplaywidth(prefix) + vim.fn.strdisplaywidth(suffix)
	if wrapper_width >= WIDTH then
		return nil
	end

	return prefix, suffix, WIDTH - wrapper_width
end

local function split_comment_value(value)
	if type(value) == "string" then
		return split_template(value, true)
	end
	if type(value) ~= "table" then
		return nil
	end

	local prefix, suffix, fill_width = split_template(value.line, true)
	if prefix then
		return prefix, suffix, fill_width
	end

	prefix, suffix, fill_width = split_template(value[1], true)
	if prefix then
		return prefix, suffix, fill_width
	end

	prefix, suffix, fill_width = split_template(value.block, true)
	if prefix then
		return prefix, suffix, fill_width
	end

	return split_template(value[2], true)
end

local function resolve_comment(bufnr)
	local ok, ft = pcall(require, "Comment.ft")
	if ok and type(ft) == "table" and type(ft.get) == "function" then
		local got_comment, comment = pcall(ft.get, vim.bo[bufnr].filetype)
		if got_comment then
			local prefix, suffix, fill_width = split_comment_value(comment)
			if prefix then
				return prefix, suffix, fill_width
			end
		end
	end

	return split_template(vim.bo[bufnr].commentstring)
end

local function notify_error(message)
	vim.notify(message, vim.log.levels.ERROR)
end

function M.insert()
	local bufnr = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local prefix, suffix, fill_width = resolve_comment(bufnr)
	if not prefix then
		notify_error("Cannot insert section header: no valid comment template")
		return
	end

	local mark_ok, mark_id = pcall(vim.api.nvim_buf_set_extmark, bufnr, namespace, row, 0, {
		right_gravity = true,
	})
	if not mark_ok then
		notify_error("Cannot insert section header: failed to track the target location")
		return
	end

	local completed = false
	local function delete_mark()
		if vim.api.nvim_buf_is_valid(bufnr) then
			pcall(vim.api.nvim_buf_del_extmark, bufnr, namespace, mark_id)
		end
	end

	local function complete(title)
		if completed then
			return
		end
		completed = true

		if title == nil then
			delete_mark()
			return
		end
		if type(title) ~= "string" then
			delete_mark()
			notify_error("Cannot insert section header: title must be text")
			return
		end
		if title:find("[\r\n]") then
			delete_mark()
			notify_error("Cannot insert section header: title cannot contain newlines")
			return
		end

		title = title:match("^%s*(.-)%s*$")
		if title == "" then
			delete_mark()
			return
		end

		if not vim.api.nvim_buf_is_valid(bufnr) then
			delete_mark()
			notify_error("Cannot insert section header: target buffer was deleted")
			return
		end
		if not vim.api.nvim_buf_is_loaded(bufnr) then
			delete_mark()
			notify_error("Cannot insert section header: target buffer is unloaded")
			return
		end
		if not vim.bo[bufnr].modifiable then
			delete_mark()
			notify_error("Cannot insert section header: target buffer is not modifiable")
			return
		end

		local position_ok, position = pcall(vim.api.nvim_buf_get_extmark_by_id, bufnr, namespace, mark_id, {})
		if not position_ok or #position == 0 then
			delete_mark()
			notify_error("Cannot insert section header: target location is unavailable")
			return
		end

		local separator = prefix .. string.rep("=", fill_width) .. suffix
		local title_line = prefix .. title .. suffix
		local write_ok = pcall(vim.api.nvim_buf_set_lines, bufnr, position[1], position[1], false, {
			separator,
			title_line,
			separator,
		})
		delete_mark()
		if not write_ok then
			notify_error("Cannot insert section header: buffer write failed")
		end
	end

	local input_ok = pcall(vim.ui.input, { prompt = "Section title: " }, complete)
	if not input_ok and not completed then
		completed = true
		delete_mark()
		notify_error("Cannot insert section header: input failed")
	end
end

return M
