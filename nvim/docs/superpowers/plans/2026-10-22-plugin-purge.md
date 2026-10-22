# Plugin Purge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove unmaintained nvim plugins. Replace each with a local `k6e.*` rewrite, a maintained fork, or a vendored copy.

**Architecture:** Each rewrite is one module in `lua/k6e/`. It has a `setup()` that registers keymap claims, autocmds and highlights. `core/02_lazy.lua` calls every `setup()` after `require("lazy").setup` and before `keymaps.activate()`. Plugin swaps only edit lazy specs in `lua/plugins/**`.

**Tech Stack:** Neovim 0.12.6 Lua API, lazy.nvim, snacks.nvim, treesitter. Tests are standalone scripts run with `nvim -l`.

**Spec:** `docs/superpowers/specs/2026-10-22-plugin-purge-design.md`

## Global Constraints

- Repo: `/Users/kit/.dots`. The nvim config lives in `nvim/`, and every path below is relative to `nvim/`.
- Worktree branch: `nvim/plugin-purge`. Make one commit per task. Use conventional messages with scope `nvim`, e.g. `feat(nvim): ...`. Add no attribution lines.
- Do not touch `lazy-lock.json` or anything outside `nvim/`.
- Rewrites copy no upstream code. Reading upstream for behaviour is fine.
- Test files follow the existing pattern. Each opens with the `root`/`package.path` preamble from `tests/keymaps_spec.lua:1-8`. Each has local `test`/`equal`/`truthy` helpers and a failure collector at the end. Run with `nvim -l tests/<name>_spec.lua`. Exit 0 means pass.
- Keymaps: claim keys only through `require("core.keymaps").owner(name)`. Use `.eager` in `k6e` setups and `.lazy` inside lazy `keys`. Claims must happen before `keymaps.activate()`.
- Formatting: tabs, as stylua formats it. `stylua --check lua tests after init.lua filetype.lua` must pass. `vendor/` is excluded via `.styluaignore`.
- Gates after every task: stylua check; `~/.local/share/nvim/mason/bin/lua-language-server --check <changed lua files> --checklevel=Warning` with no new diagnostics; all `tests/*_spec.lua` pass.
- Highlight groups: name them `K6e<Module><Role>` and define them with `default = true` links, so colourschemes can override them.

## Review Focus

1. **Tabline: the current buffer is unlisted or a special buffer** (help, terminal, snacks explorer). Expected: no crash. The tabline shows the listed buffers with none highlighted. `]b` from an unlisted buffer jumps to the first listed one. → Task 6 test `unlisted current buffer`.
2. **Cmdline popup: multi-line input** (`:lua <<EOF` blocks, `cmdline_block_*` events), and nested cmdline levels (`<C-r>=` inside `:`). Expected: the block lines render above the active line. The popup shows the innermost level and returns to the outer one on hide. → Task 7 tests `block lines` and `nested level`.
3. **todo-comments: buffer without a treesitter parser.** Expected: no highlights and no error, even when keywords appear. → Task 4 test `no parser`.
4. **luadev: config reached through the `~/.config/nvim` → `~/.dots/nvim` symlink.** Expected: the client counts as active from both paths. → Task 10 test `symlinked config root`.
5. **Tabline: very narrow terminal** (`columns` < one buffer's width). Expected: render returns a string that fits and keeps the current buffer's name, possibly truncated. No error. → Task 6 test `narrow columns`.

---

### Task 1: Green baseline

**Files:**
- Modify: `tests/keymaps_spec.lua` (module list ~L854-862; `expected_owners` ~L890-900; the failing "stable no-lazygit decision" test)
- Modify: `tests/lsp_policy_spec.lua` (Mason fixture)
- Create: `tests/external_tools_spec.lua`, `tests/section_header_spec.lua`. Copy these from the untracked files on the `main` checkout at `/Users/kit/.dots/nvim/tests/`, byte-for-byte.
- Create: `.styluaignore` containing `vendor/`

- [ ] **Step 1:** Run all suites. Expect `keymaps_spec` FAIL (`plugins.undotree` not found; `EXTERNAL_TOOLS_NOT_CAPTURED`) and `lsp_policy_spec` FAIL (Mason policy changed).
- [ ] **Step 2:** In `keymaps_spec`, remove `"plugins.undotree"` and `["mbbill/undotree"]`. In the no-lazygit test, call `require("core.external_tools").capture()` before requiring plugin specs. `capture()` is idempotent.
- [ ] **Step 3:** Set the `lsp_policy_spec` expected `ensure_installed` to `{ "astro", "bashls", "biome", "clangd", "cssls", "gdscript-formatter", "gdtoolkit", "lua_ls", "ruff", "rust_analyzer", "selene", "shellcheck", "stylua", "ts_ls", "ty", "wgsl_analyzer", "zls" }`.
- [ ] **Step 4:** Run all suites. Expect all PASS. Run the stylua check. Expect OK.
- [ ] **Step 5:** Commit `test(nvim): restore green baseline`.

### Task 2: `k6e.comment` replaces Comment.nvim

**Files:**
- Create: `lua/k6e/comment.lua`, `tests/comment_spec.lua`
- Modify: `lua/core/section_header.lua:60-75` (`resolve_comment`), `tests/section_header_spec.lua` (replace the `Comment.ft` stubs with `k6e.comment` stubs), `lua/plugins/core/enhancements.lua` (delete the Comment.nvim spec), `lua/core/02_lazy.lua` (call `require("k6e.comment").setup()`), `README.md` (keybindings table)

**Interfaces:**
- Produces: `M.get(filetype: string) -> { line: string?, block: string? }`. Templates contain exactly one `%s`, e.g. `{ line = "// %s", block = "/* %s */" }`.
- Produces: `M.toggle_block(start_row: integer, end_row: integer)`. Rows are 1-based and inclusive.
- Produces: `M.open_line(where: "below"|"above"|"eol")` and `M.setup()`.

**Comment table:**
- **Overrides:** c, cpp, cs, css, scss, javascript, javascriptreact, typescript, typescriptreact, rust, go, java, zig, swift = `// %s` + `/* %s */` (css/scss: line `/* %s */`). lua = `-- %s` + `--[[ %s ]]`. html, xml, markdown, vue, svelte, astro = block `<!-- %s -->`, with line equal to block.
- **Fallback:** derive from `commentstring`. If the template has a non-empty suffix after `%s`, it is the block (and also the line). Otherwise it is the line.
- **Padding:** normalise every template to one space around `%s`.

**Keys (owner `comment`, eager):**

| key | mode | action |
|---|---|---|
| `gb` | n, x | operator: block-comment the motion/selection (`g@`, `operatorfunc`) |
| `gbc` | n | block-toggle the current line |
| `gco` | n | open a commented line below and enter insert |
| `gcO` | n | open a commented line above and enter insert |
| `gcA` | n | append a comment at EOL and enter insert |

**Behaviour:**
- **Sticky:** `gb`/`gbc` restore the cursor's (row, col) after the edit.
- **Block toggle:** if the first line starts with the block prefix and the last line ends with the suffix (after trimming), remove both. Otherwise wrap: prefix at the first line's first non-blank, suffix at the end of the last line.
- **No block for the filetype:** fall back to native `gc` on the same range.

- [ ] **Step 1: Write `tests/comment_spec.lua`.** Tests:
  - `get("rust")` equals `{ line = "// %s", block = "/* %s */" }`
  - `get("lua").block == "--[[ %s ]]"`
  - unknown ft with `commentstring="# %s"` gives `{ line = "# %s" }`
  - unknown ft with `"/*%s*/"` gives `{ line = "/* %s */", block = "/* %s */" }`
  - `toggle_block(1,2)` on c buffer `{"int a;", "int b;"}` gives `{"/* int a;", "int b; */"}`; a second call restores the original
  - `toggle_block` on python (no block) equals native `gc`: `{"# x"}`
  - sticky: cursor `(1,4)` unchanged after `gbc` via `nvim_feedkeys("gbc","x",false)` (call `setup()` + `keymaps.activate()` in that test)
  - `gco` on `{"int a;"}` in c then typing `x<Esc>` gives line 2 == `"// x"`, indent preserved
  - `gcA` gives `"int a; // x"`
- [ ] **Step 2:** Run it. Expect FAIL (`module 'k6e.comment' not found`).
- [ ] **Step 3:** Implement `lua/k6e/comment.lua`.
- [ ] **Step 4:** Run it. Expect PASS.
- [ ] **Step 5:** Change `section_header.resolve_comment` to use `require("k6e.comment").get(vim.bo[bufnr].filetype)`. Keep the `split_comment_value` → `split_template(commentstring)` fallback. Rewrite the `section_header_spec` stubs to set `package.loaded["k6e.comment"] = { get = ... }`. Rename "Comment.nvim" in messages to "k6e.comment". Expected values stay the same.
- [ ] **Step 6:** Delete the Comment.nvim spec. Wire `setup()` in `02_lazy.lua`. In README, add `gb`/`gbc`/`gco`/`gcO`/`gcA` rows under General.
- [ ] **Step 7:** Run all suites and gates. Expect PASS. `grep -rn "Comment.nvim\|Comment.ft" lua tests` → no hits.
- [ ] **Step 8:** Commit `feat(nvim): replace Comment.nvim with k6e.comment`.

### Task 3: diffview → diffview-plus

**Files:** Modify `lua/plugins/neogit.lua` (`"sindrets/diffview.nvim"` → `"dlyongemallo/diffview-plus.nvim"`).

- [ ] **Step 1:** Add a test to `tests/keymaps_spec.lua`'s ownership test. Find the `NeogitOrg/neogit` spec, then assert `vim.tbl_contains(spec.dependencies, "dlyongemallo/diffview-plus.nvim")` and `not vim.tbl_contains(spec.dependencies, "sindrets/diffview.nvim")`. Run it. Expect FAIL.
- [ ] **Step 2:** Edit the dependency. Run it. Expect PASS.
- [ ] **Step 3:** Smoke-test: `nvim --headless "+Lazy! install" +qa`, then `nvim --headless "+lua require('diffview')" +qa`. Expect exit 0.
- [ ] **Step 4:** Gates. Commit `chore(nvim): swap diffview for diffview-plus`.

### Task 4: `k6e.todo` replaces todo-comments

**Files:**
- Create: `lua/k6e/todo.lua`, `tests/todo_spec.lua`
- Modify: `lua/plugins/core/outlines.lua` (delete the todo-comments spec), `lua/core/02_lazy.lua`, `tests/keymaps_spec.lua` (drop the `folke/todo-comments.nvim` owner row), `README.md`

**Interfaces:**
- Produces: `M.keywords`, `M.match(line: string) -> { kind: string, kw_start: integer, kw_end: integer }?` (0-based byte cols, end exclusive, covering `KW`, optional `(author)`, and `:`), `M.rg_pattern() -> string`, `M.quickfix()`, `M.pick()`, `M.setup()`.

**Keywords → kind → highlight link (keyword `K6eTodoKw<Kind>` = bg-ish via `reverse = true` on the link target; text `K6eTodoText<Kind>`):**

| kind | keywords | links to |
|---|---|---|
| Fix | FIX FIXME BUG FIXIT ISSUE | DiagnosticError |
| Todo | TODO | DiagnosticInfo |
| Hack | HACK | DiagnosticWarn |
| Warn | WARN WARNING XXX | DiagnosticWarn |
| Perf | PERF OPTIM PERFORMANCE OPTIMIZE | Identifier |
| Note | NOTE INFO | DiagnosticHint |
| Test | TEST TESTING PASSED FAILED | Identifier |

**Matching rule:**
- A match is a whole word, optionally followed by `(...)`, then `:`.
- The keyword highlight covers that span. The text highlight runs from `kw_end` to the end of the comment on that line.

**Rendering:**
- Use `nvim_set_decoration_provider(ns, { on_win, on_line })` with ephemeral extmarks.
- In `on_win`, skip the window if `vim.treesitter.get_parser(buf, nil, { error = false })` is nil.
- In `on_line`, highlight a match only if `vim.treesitter.get_captures_at_pos(buf, row, kw_start)` has a capture whose name starts with `comment`.

**Lists:**
- `rg_pattern()` → `\b(FIX|FIXME|...|FAILED)(\([^)]*\))?:` (all keywords, `|`-joined in table order).
- `quickfix()` runs `rg --vimgrep --no-messages -e <pattern>` via `vim.system` in `getcwd()`. It sets qflist titled `"Todo"`, then runs `:copen`. If `require("core.external_tools").statuses()` says rg is unavailable, it calls `vim.notify("k6e.todo: rg not found", ERROR)`.
- `pick()` → `Snacks.picker.grep({ search = M.rg_pattern(), regex = true, live = false, title = "Todo" })`.

**Keys (owner `todo`, eager):** `<leader>tt` "Todo list (Picker)"; `<leader>tq` "Todo list (Quickfix)".

- [ ] **Step 1: Write `tests/todo_spec.lua`.**
  - `match("-- TODO: x")` → kind `Todo`, kw_start 3, kw_end 8
  - `match("// FIXME(kit): y")` → kind `Fix`, span covers `FIXME(kit):`
  - `match("TODOS: z")` → nil
  - `match("todo: z")` → nil (case-sensitive)
  - `rg_pattern()` begins `\b(FIX|FIXME|BUG|FIXIT|ISSUE|TODO|`
  - **in a comment:** lua buffer `{"local a = 1 -- TODO: x", "local TODO = 1"}`. After `nvim__redraw({ flush = true })` in a window, `nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })` is empty (the marks are ephemeral). So assert via the `M._last_marks` debug table that the provider populates per draw: row 0 has a `K6eTodoKwTodo` mark at col 15, and row 1 has none.
  - **no parser:** buffer with filetype `k6e-none` containing `TODO: x` → no marks, no error.
  - **quickfix:** run in a temp dir holding `a.lua` with `-- NOTE: n`. The qflist has 1 item with text containing `NOTE: n`, and the title is `Todo`.
- [ ] **Step 2:** Run it. Expect FAIL.
- [ ] **Step 3:** Implement `lua/k6e/todo.lua`. `M._last_marks` is a table of `{ row, col, hl }` that the provider resets on every `on_win`.
- [ ] **Step 4:** Run it. Expect PASS.
- [ ] **Step 5:** Delete the spec. Wire `setup()`. Update `keymaps_spec` and the README rows.
- [ ] **Step 6:** Gates. Commit `feat(nvim): replace todo-comments with k6e.todo`.

### Task 5: trouble → Snacks picker

**Files:** Modify `lua/plugins/core/outlines.lua` (delete the trouble spec and the unused `trouble` owner), `lua/plugins/core/enhancements.lua` (add a snacks key), `tests/keymaps_spec.lua` (drop the `folke/trouble.nvim` owner row), `README.md`.

- [ ] **Step 1:** In `keymaps_spec`, assert `matching_rows("<leader>te","n")` has one row with owner `snacks`, description `"Diagnostics"`, and realization `lazy`. Run it. Expect FAIL.
- [ ] **Step 2:** Add `snacks.lazy("<leader>te", function() Snacks.picker.diagnostics() end, "Diagnostics")` to the snacks spec keys. Delete the trouble spec. Run it. Expect PASS.
- [ ] **Step 3:** `grep -rn "trouble\|Trouble" lua` → no hits. Gates. Commit `chore(nvim): replace trouble with snacks diagnostics picker`.

### Task 6: `k6e.tabline` replaces bufferline

**Files:**
- Create: `lua/k6e/tabline.lua`, `tests/tabline_spec.lua`
- Modify: `lua/plugins/core/ui.lua` (delete the bufferline spec and owner), `lua/core/02_lazy.lua`, `tests/keymaps_spec.lua` (drop the `akinsho/bufferline.nvim` row), `README.md` (fix the `<leader>bb`/`bn` descriptions)

**Interfaces:**
- Produces: `M.setup()`, `M.order() -> integer[]`, `M.render() -> string`, `M.move(delta: integer)`, `M.cycle(delta: integer)`, `M.pick()`, `M.names(bufs: integer[]) -> table<integer,string>`.
- Produces: globals `_G.K6eTablineClick(minwid, clicks, button, mods)` and `_G.K6eTablineClose(minwid, clicks, button, mods)`.

**Order state:**
- A module-local list of listed buffers.
- `BufAdd` appends when `buflisted`. `OptionSet buflisted` adds or removes. `BufDelete`/`BufWipeout` remove.
- On `setup()`, seed from `nvim_list_bufs()` filtered by `buflisted`.

**Each cell, in order:**
- `%<bufnr>@v:lua.K6eTablineClick@`
- a space
- devicon (`require("nvim-web-devicons").get_icon(name, ext, { default = true })`, guarded by pcall)
- a space
- the name, from `names()`
- if modified: ` ●`
- diagnostics: ` E<n>` if errors > 0 else ` W<n>` if warns > 0, using `vim.diagnostic.count(buf)`
- a space, then `%X%<bufnr>@v:lua.K6eTablineClose@×%X`, then a space

`[No Name]` names unnamed buffers.

**Highlights:**

| group | links to | used for |
|---|---|---|
| `K6eTablineCurrent` | `TabLineSel` | current buffer |
| `K6eTablineBuffer` | `TabLine` | other buffers |
| `K6eTablineFill` | `TabLineFill` | fill |
| `K6eTablineModified` | `DiagnosticWarn` | |
| `K6eTablineError` | `DiagnosticError` | |
| `K6eTablineWarn` | `DiagnosticWarn` | |
| `K6eTablinePick` | `Search`, bold | pick labels |

**Dedup (`names`):** for buffers sharing a tail name, prepend parent path components one at a time until the names are unique, e.g. `a/init.lua`, `b/init.lua`.

**Scroll:**
- Available width = `vim.o.columns` − the tabpage section width.
- Keep the current cell visible:
  - `first` = the smallest index such that the widths `first..current` fit (with markers).
  - Then extend right while cells fit.
- Show `‹` when cells are hidden on the left and `›` when hidden on the right, each 1 column.
- If the current cell alone exceeds the width, truncate its name to fit.

**Tabpage section:** only when `#nvim_list_tabpages() > 1`. Right-aligned, ` %<n>T<n> ` per tab, then `%T`. The current tab uses `K6eTablineCurrent`.

**Mouse:**
- `K6eTablineClick`: button `l` → `nvim_set_current_buf(minwid)`; button `m` → delete.
- `K6eTablineClose` → delete.
- Delete = `Snacks.bufdelete(minwid)`, or `vim.cmd.bdelete(minwid)` when `Snacks` is nil.

**Move and cycle:**
- `move(delta)` swaps the current buffer with its neighbour in the order, without wrapping, then redraws the tabline.
- `cycle(delta)` goes to the next/previous buffer in the order, with wrapping. If the current buffer is not in the order, it goes to `order()[1]`.

**Pick:**
- Assign labels from `"asdfjklghqwertyuiopzxcvbnm"` in order position.
- Set the pick state so `render()` shows the label (in `K6eTablinePick`) in place of the icon. `redrawtabline`.
- `vim.fn.getcharstr()`, then switch on a match. Clear the state and redraw in all cases, including `<Esc>`.

**Setup:** `showtabline=2`, `tabline=%!v:lua.require'k6e.tabline'.render()`.

**Keys (owner `tabline`, eager):**

| key | action | description |
|---|---|---|
| `<leader>bb` | `move(-1)` | "Move buffer left" |
| `<leader>bn` | `move(1)` | "Move buffer right" |
| `<leader>bp` | `pick()` | "Pick buffer" |
| `]b` | `cycle(1)` | "Next buffer" |
| `[b` | `cycle(-1)` | "Previous buffer" |

- [ ] **Step 1: Write `tests/tabline_spec.lua`.** Strip `%...@`, `%X`, `%T` and `%#..#` codes with a helper `plain(s)` before text assertions.
  - **order:** 3 named buffers → `order()` equals their bufnrs in creation order
  - **move:** current = 2nd, `move(-1)` → order is [2nd, 1st, 3rd]; `move(-1)` again → unchanged
  - **cycle:** `cycle(1)` from the last → the first (wraps); `cycle(-1)` from the first → the last
  - **unlisted current buffer:** current = a `nofile` unlisted scratch; `render()` has no error and no `K6eTablineCurrent` cell before the tab section; `cycle(1)` → `order()[1]`
  - **dedup:** `names` for `/x/a/init.lua`, `/x/b/init.lua`, `/x/c.lua` → `a/init.lua`, `b/init.lua`, `c.lua`
  - **modified:** set the buffer modified → its cell contains `●`
  - **diagnostics:** `vim.diagnostic.set(ns, buf, {{lnum=0,col=0,severity=ERROR,message="e"},{...ERROR}})` → cell contains `E2`
  - **click handlers:** `render()` contains `%<buf>@v:lua.K6eTablineClick@` and `@v:lua.K6eTablineClose@×`; `K6eTablineClick(b, 1, "l", "")` makes `b` current; `K6eTablineClick(b, 1, "m", "")` with `_G.Snacks = { bufdelete = spy }` calls the spy with `b`
  - **scroll:** 30 buffers, `columns=60`, current = the 25th → `plain(render())` contains the 25th's name and `‹`, and `vim.api.nvim_strwidth(plain(render())) <= 60`
  - **narrow columns:** `columns=12` and a 40-char name → width ≤ 12, no error
  - **tabpages:** 2 tabpages → `render()` contains `%1T` and `%2T`; with 1 tabpage it contains neither
  - **pick:** stub `vim.fn.getcharstr` to return `"s"` → current = `order()[2]`; stub it to return `"\27"` → current unchanged and the pick state cleared (render shows icons again)
- [ ] **Step 2:** Run it. Expect FAIL.
- [ ] **Step 3:** Implement `lua/k6e/tabline.lua`.
- [ ] **Step 4:** Run it. Expect PASS.
- [ ] **Step 5:** Delete the bufferline spec. Wire `setup()`. Update `keymaps_spec` and the README (descriptions as in the table above).
- [ ] **Step 6:** Gates. Commit `feat(nvim): replace bufferline with k6e.tabline`.

### Task 7: `k6e.ui` cmdline popup (module + tests)

**Files:** Create `lua/k6e/ui.lua`, `tests/ui_spec.lua`.

**Interfaces:**
- Produces: `M.kind(firstc: string, text: string, prompt: string) -> { icon: string, title: string, lang: string? }`.
- Produces: `M.handle(event: string, ...)`, a pure dispatcher for `cmdline_show`, `cmdline_pos`, `cmdline_special_char`, `cmdline_hide`, `cmdline_block_show`, `cmdline_block_append`, `cmdline_block_hide`. Same argument lists as `:h ui-cmdline`.
- Produces: `M.attach()`, `M.detach()`, `M._state() -> { visible: boolean, win: integer?, buf: integer?, lines: string[], title: string?, level: integer? }`.

**`kind` table (checked top to bottom):**

| firstc | text match | icon | title | lang |
|---|---|---|---|---|
| `""` | (prompt or input) | `󰥻` | ` <prompt trimmed> ` or ` Input ` | nil |
| `/` | | `` | ` Search ` | `regex` |
| `?` | | `` | ` Search ` | `regex` |
| `=` | | `` | ` Calculator ` | `vim` |
| `:` | `^%s*!` | `$` | ` Shell ` | `bash` |
| `:` | `^%s*lua%s`, `^%s*lua%s*=`, `^%s*=` | `` | ` Lua ` | `lua` |
| `:` | `^%s*h%a*%s` where the word is a prefix of `help` | `󰋖` | ` Help ` | `vim` |
| `:` | anything else | `` | ` Cmdline ` | `vim` |

**Popup:**
- **Buffer:** a scratch buffer, reused. Its lines are the block lines (if any) followed by `icon .. " " .. text`.
- **Window:** a float, `relative="editor"`, `border="rounded"`, `title=kind.title`, `title_pos="center"`, `zindex=200`, `focusable=false`, `noautocmd=true`.
- **Size:**
  - width = `max(60, strwidth(last line) + 2)`, capped at `columns - 4`
  - height = `#lines`
  - row = `floor(lines * 0.25)`
  - col = `floor((columns - width - 2) / 2)`
- **Highlighting:** if `kind.lang` has a parser, `vim.treesitter.start(buf, kind.lang)`; otherwise none. Errors are ignored.
- **Fake cursor:** an extmark in namespace `k6e.ui.cursor`, hl `K6eUiCursor` (link `Cursor`), at byte `#icon + 1 + pos` on the last line. At end of line, use `virt_text = {{" ", "K6eUiCursor"}}`.
- **`vim.g.ui_cmdline_pos`** = `{ row + 2, col + 1 + strwidth(icon .. " ") }`: the 1-based screen row of the text line (row + border) and the 0-based screen col of the text start.
- **Levels:** keep a stack keyed by `level`; the popup shows the highest level. `cmdline_hide(level)` drops that level, then re-renders the remaining highest level or closes the popup. On close, clear `vim.g.ui_cmdline_pos`.
- **`cmdline_special_char(c, shift, level)`** inserts `c` at pos for display; the next `cmdline_show` replaces it.

**Attach:**
- `vim.ui_attach(ns, { ext_cmdline = true }, function(event, ...) ... end)`. The callback calls `M.handle` inside `xpcall`.
- On error: `vim.ui_detach(ns)`, close the popup, then `vim.schedule(function() vim.notify("k6e.ui: " .. err .. "; falling back to native cmdline", ERROR) end)`. Return without re-raising.
- After a successful render, call `vim.api.nvim__redraw({ flush = true, cursor = true })`. Each `vim.api` call that is disallowed in the callback goes through `vim.schedule`.

- [ ] **Step 1: Write the in-process tests in `tests/ui_spec.lua`.** These drive `M.handle` directly, with no ui_attach.
  - **`kind`** for each table row, e.g. `kind(":", "lua print(1)", "")` → title ` Lua `, lang `lua`; `kind(":", "hel foo", "")` → ` Help `; `kind(":", "hello", "")` → ` Cmdline `; `kind("", "", "Name: ")` → title ` Name: `
  - **show/hide:**
    1. `handle("cmdline_show", {{0,"ec"}}, 2, ":", "", 0, 1, 0)` → `_state().visible`, `lines == {" ec"}`, title ` Cmdline `, and the window config has `relative=="editor"`, `row == floor(lines*0.25)`, `width >= 60`
    2. `vim.g.ui_cmdline_pos[1] == row + 2`
    3. `handle("cmdline_hide", 1, false)` → not visible, the window is invalid, and `vim.g.ui_cmdline_pos == nil`
  - **cursor:** after `cmdline_pos(1, 1)`, the cursor extmark sits at col `#icon + 1 + 1` on the last line
  - **block lines:** `cmdline_block_show({{{0,"lua <<EOF"}}})` then `cmdline_show({{0,"print(1)"}}, ...)` → `lines == {"lua <<EOF", " print(1)"}`
  - **nested level:** show level 1 `"ec"`, then show level 2 (firstc `=`, `"1+1"`) → title ` Calculator `; hide level 2 → title ` Cmdline ` and lines back to `" ec"`
  - **fallback:** stub `M.handle` to error, invoke the attach callback wrapper `M._on_event("cmdline_show", ...)` → no raise, the popup is closed, and the attachment is gone (a test seam `M._attached == false`). After `vim.wait(50)`, a notify spy saw a message containing `falling back`.
- [ ] **Step 2: Child-nvim test.** Same pattern as `tests/startscreen_spec.lua:658`:
  1. Spawn `nvim --headless --embed -u NONE`.
  2. `nvim_ui_attach(80, 24, { ext_linegrid = true })` (ignore redraw notifications).
  3. Prepend the repo root to rtp and `require("k6e.ui").attach()`.
  4. `nvim_input(":ec")`, then `vim.wait` until `nvim_exec_lua("return require('k6e.ui')._state().visible")` is true.
  5. Assert the lines equal `{" ec"}`.
  6. `nvim_input("<Esc>")` → not visible.
- [ ] **Step 3:** Run it. Expect FAIL.
- [ ] **Step 4:** Implement `lua/k6e/ui.lua` (no keys and no `setup()` yet).
- [ ] **Step 5:** Run it. Expect PASS. Run it again 5 times in a loop. Expect 5/5 PASS (flake check).
- [ ] **Step 6:** Gates. Commit `feat(nvim): add k6e.ui cmdline popup`.

### Task 8: Wire `k6e.ui`, remove noice + nui

**Files:** Modify `lua/k6e/ui.lua` (add `setup()`, `redirect()`), `tests/ui_spec.lua`, `lua/plugins/core/ui.lua` (delete the noice spec and owner), `lua/plugins/core/enhancements.lua` (snacks `notifier = { enabled = true }`), `lua/plugins/core/lsp.lua:10` (hover border), `lua/core/02_lazy.lua`, `tests/keymaps_spec.lua` (drop the `folke/noice.nvim` row), `tests/lsp_policy_spec.lua` if it asserts `K`'s action, `README.md`.

**Interfaces:**
- Consumes: Task 7's `M.attach()`.
- Produces: `M.setup()` (claims keys, then `M.attach()`) and `M.redirect(cmd: string)`.

**Redirect:**
- `M.redirect(cmd)` runs `nvim_exec2(cmd, { output = true })` under pcall.
- It opens `botright new` with a scratch buffer (`buftype=nofile`, `bufhidden=wipe`, `filetype=k6e-redirect`). The buffer holds the output lines, or the error message on failure.
- Key: owner `ui`, eager, mode `c`, `<S-CR>`, expr mapping: `function() local cmd = vim.fn.getcmdline(); vim.schedule(function() require("k6e.ui").redirect(cmd) end); return "<C-c>" end`, description "Redirect Cmdline".

**Hover:** `K` action becomes `function() vim.lsp.buf.hover({ border = "rounded" }) end`. The description is unchanged. Do not set the global `winborder`.

- [ ] **Step 1: Tests.**
  - **redirect:** `redirect("echo 'hi'")` → the current window's buffer has filetype `k6e-redirect` and lines `{"hi"}`
  - **redirect error:** `redirect("bogus_cmd")` → the buffer's first line contains `E492`
  - **notifier:** in `keymaps_spec`'s ownership test, the snacks spec has `opts.notifier.enabled == true`, there is no spec named `folke/noice.nvim` or `MunifTanjim/nui.nvim`, and `matching_rows("<S-CR>","c")` has owner `ui`
- [ ] **Step 2:** Run them. Expect FAIL.
- [ ] **Step 3:** Implement. Wire `require("k6e.ui").setup()` in `02_lazy.lua`. Delete the noice spec. Enable the notifier. Change hover.
- [ ] **Step 4:** Run all suites. Expect PASS. Run `grep -rn "noice\|nui" lua tests`. Expect hits only in `k6e/ui.lua` comments, or none.
- [ ] **Step 5:** Manual smoke: `nvim --headless "+lua vim.defer_fn(function() vim.cmd('qa') end, 500)"`. Expect exit 0 with no error output.
- [ ] **Step 6:** Gates. Commit `feat(nvim): replace noice with k6e.ui and snacks notifier`.

### Task 9: Vendor which-key

**Files:**
- Create: `vendor/which-key.nvim/**` (an unmodified tree of upstream `folke/which-key.nvim` at the commit recorded in Step 1), `vendor/which-key.nvim/VENDORED.md`, `tests/vendor_spec.lua`
- Modify: `lua/plugins/core/enhancements.lua` (the which-key spec), `tests/keymaps_spec.lua` (key `specs_by_name` by `spec[1] or spec.name`; the expected owner row `["which-key.nvim"] = "which-key"`)

- [ ] **Step 1:** `git clone --depth 1 https://github.com/folke/which-key.nvim <scratch>/wk`. Record `git -C <scratch>/wk rev-parse HEAD`. Copy the tree, excluding `.git` and `.github`, into `vendor/which-key.nvim/`.
- [ ] **Step 2:** Write `VENDORED.md`: upstream URL, commit SHA, date `2026-10-22`, licence Apache-2.0 (its `LICENSE` is kept), the rule "unmodified; local patches listed below", and an empty patch list.
- [ ] **Step 3: Write `tests/vendor_spec.lua`.**
  1. Prepend `root .. "/vendor/which-key.nvim"` to rtp.
  2. `require("which-key")` succeeds, and `type(require("which-key").show) == "function"`.
  3. `vendor/which-key.nvim/LICENSE` is readable.
  4. `VENDORED.md` contains a 40-hex SHA.

  Run it. Expect FAIL.
- [ ] **Step 4:** Change the spec to `{ dir = vim.fn.stdpath("config") .. "/vendor/which-key.nvim", name = "which-key.nvim", event = "VeryLazy", opts = …unchanged, keys = …unchanged }`. Run the vendor test and `keymaps_spec`. Expect PASS.
- [ ] **Step 5:** Gates. stylua ignores `vendor/`; skip luals for `vendor/`. Commit `chore(nvim): vendor which-key.nvim`.

### Task 10: `k6e.luadev` replaces lazydev

**Files:**
- Create: `lua/k6e/luadev.lua`, `tests/luadev_spec.lua`
- Modify: `lua/plugins/core/enhancements.lua` (delete the lazydev spec), `lua/core/02_lazy.lua`

**Interfaces:**
- Produces: `M.is_active(root: string) -> boolean`, `M.scan(lines: string[]) -> string[]` (unique top-level module names, sorted), `M.resolve(mod: string) -> string?` (a plugin `lua/` dir), `M.library(bufs: integer[]) -> string[]`, `M.setup()`.

**`is_active(root)`:**
- Compare `vim.uv.fs_realpath` values.
- True when `root == realpath(stdpath("config"))`, or when root starts with `realpath(require("lazy.core.config").options.root) .. "/"`.

**`scan(lines)`:**
- Matches: `require%s*%(?%s*["']([%w_%-%.]+)["']` and `^%s*%-%-%-@module%s+["']([%w_%-%.]+)["']`.
- Keep the part before the first `.`.
- Drop `vim`, and any module found under `stdpath("config")/lua`.

**`resolve(mod)`:**
- For each `plugin` in `require("lazy.core.config").plugins`, return `plugin.dir .. "/lua"` if `plugin.dir/lua/<mod>` is a directory or `plugin.dir/lua/<mod>.lua` is a file.
- Memoise per mod.

**`library(bufs)`:** `{ vim.env.VIMRUNTIME, "${3rd}/luv/library" }` plus the resolved dirs (deduped, sorted).

**`setup()`:**
- `LspAttach` autocmd: for `client.name == "lua_ls"` with an active `client.root_dir`, compute `library` over the lua buffers attached to the client.
- If it differs from `client.settings.Lua.workspace.library`, set it, then `client:notify("workspace/didChangeConfiguration", { settings = client.settings })`.
- `BufWritePost *.lua` re-runs the same computation for attached lua_ls clients. Debounce it at 500 ms with one `vim.uv` timer per client.

**Non-active roots:** keep `after/lsp/lua_ls.lua`'s current static library.

- [ ] **Step 1: Write `tests/luadev_spec.lua`.** Stub `package.loaded["lazy.core.config"] = { options = { root = tmp .. "/lazy" }, plugins = { snacks = { dir = tmp .. "/lazy/snacks.nvim" } } }`, with `tmp/lazy/snacks.nvim/lua/snacks/init.lua` created on disk.
  - **scan:** `scan({ 'local s = require("snacks.picker")', "---@module 'snacks'", 'require "core.keymaps"', "require('vim.lsp')" })` → `{ "snacks" }` (core is local config, vim is dropped)
  - **resolve:** `resolve("snacks") == tmp .. "/lazy/snacks.nvim/lua"`; `resolve("nope") == nil`
  - **is_active:** true for `stdpath("config")`, true for `tmp .. "/lazy/snacks.nvim"`, false for `tmp`
  - **symlinked config root:** create the symlink `tmp/cfg → realpath(stdpath("config"))` → `is_active(tmp .. "/cfg")` is true
  - **library:** `library({ buf_with_require_snacks })[1] == vim.env.VIMRUNTIME` and the result contains the snacks lua dir
  - **notify on change:** fake client `{ name = "lua_ls", root_dir = stdpath("config"), settings = { Lua = { workspace = { library = {} } } }, notify = spy }`. Call `M._refresh(client, { buf })` twice. The spy is called exactly once, with `"workspace/didChangeConfiguration"`.
- [ ] **Step 2:** Run it. Expect FAIL.
- [ ] **Step 3:** Implement. `M._refresh(client, bufs)` is the shared body used by both autocmds.
- [ ] **Step 4:** Run it. Expect PASS.
- [ ] **Step 5:** Delete the lazydev spec. Wire `setup()`.
- [ ] **Step 6:** Gates. Commit `feat(nvim): replace lazydev with k6e.luadev`.

### Task 11: claudecode.nvim replaces claude-code.nvim

**Files:** Modify `lua/plugins/extras/claude.lua`, `tests/keymaps_spec.lua` (add `"plugins.extras.claude"` to the module list and `["coder/claudecode.nvim"] = "claudecode"` to the owners), `README.md`.

**Spec:**
- Name: `coder/claudecode.nvim`.
- `dependencies = { "folke/snacks.nvim" }`.
- `cmd = { "ClaudeCode", "ClaudeCodeSend", "ClaudeCodeAdd", "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny" }`.
- `opts = { terminal = { provider = "snacks" } }`.

**Keys (owner `claudecode`, lazy):**

| key | mode | command | description |
|---|---|---|---|
| `<C-,>` | n, t | `<cmd>ClaudeCode<cr>` | "Toggle Claude" |
| `<leader>cs` | v | `<cmd>ClaudeCodeSend<cr>` | "Send selection to Claude" |
| `<leader>cb` | n | `<cmd>ClaudeCodeAdd %<cr>` | "Add buffer to Claude" |
| `<leader>cy` | n | `<cmd>ClaudeCodeDiffAccept<cr>` | "Accept Claude diff" |
| `<leader>cn` | n | `<cmd>ClaudeCodeDiffDeny<cr>` | "Deny Claude diff" |

`<leader>ca` is taken by LSP code action, which is why accept/deny use `cy`/`cn`.

- [ ] **Step 1:** Extend `keymaps_spec` as listed above. Assert no spec named `greggh/claude-code.nvim`. Run it. Expect FAIL.
- [ ] **Step 2:** Rewrite `claude.lua`. Run it. Expect PASS.
- [ ] **Step 3:** Smoke: `nvim --headless "+Lazy! install" +qa`, then `nvim --headless "+lua require('claudecode')" +qa`. Expect exit 0.
- [ ] **Step 4:** Gates. Commit `feat(nvim): replace claude-code.nvim with claudecode.nvim`.

### Task 12: Final gates + merge

- [ ] **Step 1:** Run every suite, stylua, and luals on all files changed on the branch (`git diff --name-only main...HEAD -- '*.lua' ':!vendor'`). Expect PASS with no new diagnostics.
- [ ] **Step 2:** Run `nvim --headless "+Lazy! clean" +qa` in the worktree environment, then a startup smoke test: `nvim --headless "+lua vim.defer_fn(function() vim.cmd('qa') end, 1000)"`. Expect no errors on stderr.
- [ ] **Step 3:** Whole-branch review (superpowers:requesting-code-review).
- [ ] **Step 4:** On the `main` checkout, remove the untracked `tests/external_tools_spec.lua` and `tests/section_header_spec.lua`, after confirming that `external_tools_spec` is identical to the branch copy from Task 1. Then `git merge --ff-only nvim/plugin-purge`.
