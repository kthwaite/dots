local M = {}

local uv = vim.uv

---@param path string
---@return string
local function real(path)
	return uv.fs_realpath(path) or path
end

---@type table<string, string|false>
local resolved = {}

--- True when `root` is the nvim config or lives under the lazy plugin root.
---@param root string?
---@return boolean
function M.is_active(root)
	if not root or root == "" then
		return false
	end
	local path = real(root)
	if path == real(vim.fn.stdpath("config")) then
		return true
	end
	local lazy_root = require("lazy.core.config").options.root
	return vim.startswith(path, real(lazy_root) .. "/")
end

---@param mod string
---@return boolean
local function is_local(mod)
	local base = vim.fn.stdpath("config") .. "/lua/" .. mod
	return uv.fs_stat(base .. ".lua") ~= nil or uv.fs_stat(base) ~= nil
end

--- Unique top-level module names required or declared in `lines`, sorted.
---@param lines string[]
---@return string[]
function M.scan(lines)
	local seen = {}
	local function add(name)
		local top = name:match("^[^.]+")
		if top and top ~= "vim" and not seen[top] and not is_local(top) then
			seen[top] = true
		end
	end
	for _, line in ipairs(lines) do
		for name in line:gmatch("require%s*%(?%s*[\"']([%w_%-%.]+)[\"']") do
			add(name)
		end
		local name = line:match("^%s*%-%-%-@module%s+[\"']([%w_%-%.]+)[\"']")
		if name then
			add(name)
		end
	end
	local out = vim.tbl_keys(seen)
	table.sort(out)
	return out
end

--- The `lua/` dir of the plugin that provides `mod`.
---@param mod string
---@return string?
function M.resolve(mod)
	local cached = resolved[mod]
	if cached ~= nil then
		return cached or nil
	end
	local found = false
	for _, plugin in pairs(require("lazy.core.config").plugins) do
		local lua_dir = plugin.dir .. "/lua"
		local dir = uv.fs_stat(lua_dir .. "/" .. mod)
		local file = uv.fs_stat(lua_dir .. "/" .. mod .. ".lua")
		if (dir and dir.type == "directory") or (file and file.type == "file") then
			found = lua_dir
			break
		end
	end
	resolved[mod] = found
	return found or nil
end

--- Workspace library for the given buffers.
---@param bufs integer[]
---@return string[]
function M.library(bufs)
	local dirs, seen = {}, {}
	for _, buf in ipairs(bufs) do
		if vim.api.nvim_buf_is_valid(buf) then
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			for _, mod in ipairs(M.scan(lines)) do
				local dir = M.resolve(mod)
				if dir and not seen[dir] then
					seen[dir] = true
					dirs[#dirs + 1] = dir
				end
			end
		end
	end
	table.sort(dirs)
	local lib = { vim.env.VIMRUNTIME, "${3rd}/luv/library" }
	vim.list_extend(lib, dirs)
	return lib
end

--- Recompute the library for `client`; notify the server only on change.
---@param client vim.lsp.Client
---@param bufs integer[]
function M._refresh(client, bufs)
	if not M.is_active(client.root_dir) then
		return
	end
	local lib = M.library(bufs)
	client.settings = client.settings or {}
	client.settings.Lua = client.settings.Lua or {}
	client.settings.Lua.workspace = client.settings.Lua.workspace or {}
	local workspace = client.settings.Lua.workspace
	if vim.deep_equal(workspace.library, lib) then
		return
	end
	workspace.library = lib
	client:notify("workspace/didChangeConfiguration", { settings = client.settings })
end

---@param client vim.lsp.Client
---@return integer[]
local function lua_buffers(client)
	return vim.tbl_filter(function(buf)
		return vim.bo[buf].filetype == "lua"
	end, vim.lsp.get_buffers_by_client_id(client.id))
end

---@type table<integer, uv.uv_timer_t>
local timers = {}

---@param client vim.lsp.Client
local function debounce(client)
	local timer = timers[client.id]
	if not timer then
		timer = assert(uv.new_timer())
		timers[client.id] = timer
	end
	timer:stop()
	timer:start(
		500,
		0,
		vim.schedule_wrap(function()
			if client:is_stopped() then
				timer:close()
				timers[client.id] = nil
				return
			end
			M._refresh(client, lua_buffers(client))
		end)
	)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("k6e.luadev", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client and client.name == "lua_ls" then
				M._refresh(client, lua_buffers(client))
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "*.lua",
		callback = function()
			for _, client in ipairs(vim.lsp.get_clients({ name = "lua_ls" })) do
				if M.is_active(client.root_dir) then
					debounce(client)
				end
			end
		end,
	})
end

return M
