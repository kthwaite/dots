local M = {}

---Get hostname.
---@return string?
function M.hostname()
	local hostname = os.getenv("HOSTNAME")
	if hostname == nil then
		hostname = os.getenv("HOST")
	end
	if hostname == nil then
		local fh = io.popen("hostname")
		if fh == nil then
			return nil
		end
		hostname = fh:read()
		fh:close()
	end
	-- if hostname ends with .local, remove it
	return hostname:gsub("%.local$", "")
end

return M
