# Plugin purge: design

Date: 2026-10-22. Agreed in a grilling session (Q1–Q22).

## Goal

Remove or replace unmaintained plugins. Rewrites are local `k6e.*` modules with no copied upstream code.

## Shape

- Branch `nvim/plugin-purge` in a worktree. One commit per plugin. Fast-forward into `main`.
- The dirty files on `main` (`lazy-lock.json`, zellij) are not touched.
- Rewrites live in `lua/k6e/<name>.lua`, with tests in `tests/<name>_spec.lua` run by `nvim -l`.
- Each rewrite claims keys through `core.keymaps.owner("<name>")`.
- Each rewrite has a `setup()`. `core/02_lazy.lua` calls it before `keymaps.activate()`.
- First, fix the red baseline suites (`keymaps_spec`, `lsp_policy_spec`).

## Per plugin

| plugin | action |
|---|---|
| numToStr/Comment.nvim | Remove it. `k6e.comment` adds `gb` (op) / `gbc` (block toggle), `gco`/`gcO`/`gcA`, sticky cursor, and a per-filetype `{ line, block }` table. `core.section_header` reads that table instead of `Comment.ft`. Native `gc`/`gcc` stays. |
| sindrets/diffview.nvim | Swap for `dlyongemallo/diffview-plus.nvim`. The module is still `diffview`, so neogit needs no change. |
| akinsho/bufferline.nvim | Rewrite as `k6e.tabline`. Each buffer shows icon, name (dedup), modified marker, error/warn diagnostic counts, and a current-buffer highlight. The tabline scrolls to keep the current buffer visible. A tabpage indicator sits on the right. Custom order, move left/right, letter-label pick. Mouse: left-click switches, middle-click deletes, a `×` on each buffer deletes, tabpages are clickable. Deletion uses `Snacks.bufdelete`. `]b`/`[b` follow tabline order. |
| folke/noice.nvim + MunifTanjim/nui.nvim | Rewrite as `k6e.ui`, attached with `ext_cmdline` only; messages stay native. Centred command-palette popup: min 60 cols, row `floor(lines * 0.25)`, rounded border, title per type. Sets `vim.g.ui_cmdline_pos` for blink. `<S-Enter>` in the cmdline opens the command's output in a split. If a handler throws, the layer detaches and falls back to the native cmdline. `vim.notify` goes to `Snacks.notifier`. LSP hover has a rounded border. |
| folke/trouble.nvim | Remove it. `<leader>te` runs `Snacks.picker.diagnostics()`. |
| folke/todo-comments.nvim | Rewrite as `k6e.todo`. Matches only in treesitter comments and only in the drawn range. Highlights the keyword plus the trailing text. No signs. `<leader>tq` sends rg results to quickfix. `<leader>tt` opens a Snacks grep picker. |
| folke/which-key.nvim | Vendor it, unmodified, into `vendor/which-key.nvim` at commit `HEAD of main on 2026-10-22`. Keep its LICENSE and add `VENDORED.md`. Load it with lazy `dir=`. Smoke test only. |
| folke/lazydev.nvim | Rewrite as `k6e.luadev` (dynamic). Active when the `lua_ls` root is the nvim config dir or a dir under the lazy plugin root. Library is `$VIMRUNTIME` and luv, plus plugin `lua/` dirs found by scanning `require("x")` / `---@module 'x'`. Rescans on attach and on BufWritePost (debounced), then pushes `workspace/didChangeConfiguration`. |
| greggh/claude-code.nvim | Replace with `coder/claudecode.nvim`: snacks provider, `<C-,>` toggle (n, t), owner `claudecode`. |

## Out of scope

- Lockfile pinning.
- Message rendering (`ext_messages`).
- Cmdline syntax beyond treesitter highlighting of the popup buffer.

## Gates

- `stylua --check lua tests after init.lua filetype.lua`
- `lua-language-server --check` on changed files
- every `tests/*_spec.lua` through `nvim -l`
