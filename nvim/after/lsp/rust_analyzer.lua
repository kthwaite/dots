local _sysroot_cache = nil
local function get_sysroot()
	if _sysroot_cache == nil then
		_sysroot_cache = vim.fn.trim(vim.fn.system("rustc --print sysroot"))
	end
	return _sysroot_cache
end

return {
	settings = {
		cargo = {
			sysroot = get_sysroot(),
		},
	},
}
