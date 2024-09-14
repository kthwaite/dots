-- save and enter ipython repl
vim.api.nvim_buf_set_keymap(0, "n", "<leader>pi", ":w<cr>:term ipython % -i<cr>", { noremap = true })
