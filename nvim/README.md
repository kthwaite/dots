# neovim config

Respects the following environment variables:

- `K6E_EXTRA_PLUGINS`: comma-separated list of plugin specs in `lua/plugins` which Lazy will attempt to source
- `K6E_SESSION_PLUGINS`: comma-separated list of plugin specs in `lua/plugins` which Lazy will attempt to source; implicitly ephemeral, for this session only 
- `K6E_COPILOT_LUA`: if 1, use copilot-lua plugin, rather than copilot; requires that the `copulot` plugin is loaded

## Keybindings

Leader key is `<Space>`.

### General

| Mode | Key | Action |
|------|-----|--------|
| n | `Y` | Yank to end of line |
| i | `jk` | Escape |
| n/v/i | `<C-h/j/k/l>` | Navigate splits |
| n | `<leader>hv` | Horizontal split → vertical |
| n | `<leader>vh` | Vertical split → horizontal |

### Terminal & Splits

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>st` | Open terminal (bottom) |
| n | `<leader>vt` | Open terminal (vertical) |
| n | `<leader>sl/sh/sj/sk` | Navigate splits |

### Tabs & Buffers

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>tn` | Next tab |
| n | `<leader>tp` | Previous tab |
| n | `<leader>tc` | New tab |
| n | `<leader>tx` | Close tab |
| n | `<leader>Bd` | Close all hidden buffers |
| n | `<leader>bb` | Move buffer left |
| n | `<leader>bn` | Move buffer right |
| n | `<leader>bp` | Pick buffer |

### LSP

| Mode | Key | Action |
|------|-----|--------|
| n | `gD` | Go to declaration |
| n | `gd` | Go to definition |
| n | `K` | Hover documentation |
| n | `gi` | Go to implementation |
| n | `gr` | List references |
| n | `<space>D` | Go to type definition |
| n | `<space>rn` | Rename symbol |
| n | `<space>ca` | Code action |
| n | `<space>f` | Format buffer |
| n | `[d` / `]d` | Previous/next diagnostic |

### File Finding (Snacks.nvim)

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>tf` | Find files (smart) |
| n | `<leader>,` | Find buffers |
| n | `<leader>/` | Live grep |
| n | `<leader>:` | Command history |
| n | `<leader>n` | Notification history |
| n | `<leader>cf` | Find config files |
| n | `<leader>cg` | Grep config files |
| n | `<leader>th` | Pick colorscheme |
| n | `<leader>sh` | Help pages |
| n | `<leader>sk` | Keymaps |
| n | `<leader>e` | File explorer |

### Git

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>gb` | Git blame (line) |
| n | `<leader>gl` | Git log |
| n | `<leader>gs` | Git status |
| n | `<leader>gg` | Lazygit |
| n | `]c` / `[c` | Next/prev hunk |
| n/v | `<leader>hs` | Stage hunk |
| n/v | `<leader>hr` | Reset hunk |

### Comments

| Mode | Key | Action |
|------|-----|--------|
| n | `gcc` | Toggle line comment |
| n/v | `gc` | Line comment (operator) |
| n | `gbc` | Toggle block comment |
| n/v | `gb` | Block comment (operator) |
| n | `gcO` / `gco` | Comment above/below |
| n | `gcA` | Comment at end of line |

### Utilities

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>?` | Show buffer keymaps (which-key) |
| n | `<leader>o` | Toggle symbol outline |
| n | `<leader>te` | Toggle diagnostics (Trouble) |
| n | `<leader>tt` | Todo list (Trouble) |
| n | `<leader>tq` | Todo list (Quickfix) |
| n | `<leader>u` | Toggle undo tree |
| n | `<leader>z` | Toggle Zen mode |
| n | `<leader>rN` | Rename current file |
| n | `<leader>gn` | Generate docstring (Neogen) |

### Plugin Management

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>lu` | Lazy update |
| n | `<leader>ls` | Lazy sync |
| n | `<leader>mo` | Open Mason |
| n | `<leader>mu` | Mason update |

### Filetype-Specific

**Rust:**
| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>a` | Rust code action (grouped) |

**Python:**
| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>pi` | Save and run in Python REPL |
