local dap_setup = {
	["python"] = function(mason_registry, dap)
		local ok, debugpy = pcall(mason_registry.get_package, "debugpy")
		if not ok then
			vim.notify("Failed to locate package 'debugpy'", vim.log.levels.WARN)
			return
		end
		local debugpy_path = debugpy:get_install_path()
		dap.adapters.python = {
			type = "executable",
			command = debugpy_path .. "/debugpy-adapter",
		}
		dap.configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "Launch file",

				program = "${file}",
				pythonPath = function()
					local cwd = vim.fn.getcwd()
					if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
						return cwd .. "/.venv/bin/python"
					else
						return "python"
					end
				end,
			},
		}
	end,
	["typescriptreact"] = function(mason_registry, dap)
		dap.adapters.typescriptreact = {
			type = "server",
			host = "::1",
			port = "${port}",
			executable = {
				command = "js-debug-adapter",
				args = {
					"${port}",
				},
			},
		}
		dap.configurations.typescriptreact = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				cwd = "${workspaceFolder}",
			},
		}
	end,
}
return {
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "williamboman/mason.nvim", "nvim-neotest/nvim-nio" },
		lazy = true,
		config = function()
			local dap = require("dap")
			local mason_registry = require("mason-registry")
			for _, setup in pairs(dap_setup) do
				setup(mason_registry, dap)
			end
		end,
	},
}
