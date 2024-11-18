local M = {}

local terminals = {}

function M.open(cmd, opts)
	opts = vim.tbl_extend("force", {
		ft = "k6e_term",
		size = { width = 0.9, height = 0.9 },
	}, opts or {}, { persistent = true })
	local termkey = vim.inspect({ cmd = cmd or "shell", cwd = opts.cwd, env = opts.env, count = vim.v.count1 })
	if terminals[termkey] then
		terminals[termkey]:toggle()
	else
		terminals[termkey] = require("lazy.util").float_term(cmd, opts)
		local buf = terminals[termkey].buf
		vim.b[buf].lazyterm_cmd = cmd
		if opts.esc_esc == false then
			vim.keymap.set("t", "<esc>", "<esc>", { buffer = buf, nowait = true })
		end
		if opts.ctrl_hjkl == false then
			vim.keymap.set("t", "<c-h>", "<c-h>", { buffer = buf, nowait = true })
			vim.keymap.set("t", "<c-j>", "<c-j>", { buffer = buf, nowait = true })
			vim.keymap.set("t", "<c-k>", "<c-k>", { buffer = buf, nowait = true })
			vim.keymap.set("t", "<c-l>", "<c-l>", { buffer = buf, nowait = true })
		end

		vim.keymap.set("n", "gf", function()
			local f = vim.fn.findfile(vim.fn.expand("<cfile>"))
			if f ~= "" then
				vim.cmd("close")
				vim.cmd("e " .. f)
			end
		end, { buffer = buf })

		vim.api.nvim_create_autocmd("BufEnter", {
			buffer = buf,
			callback = function()
				vim.cmd.startinsert()
			end,
		})

		vim.cmd("noh")
	end
	return terminals[termkey]
end

return M
