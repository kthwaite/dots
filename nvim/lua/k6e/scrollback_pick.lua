-- ~/.config/nvim/lua/scrollback_pick.lua
--
-- Neovim UI used by two zsh ZLE widgets:
--
--   1. "pick"
--      Select arbitrary text from terminal scrollback and immediately insert it
--      into the current shell command.
--
--   2. "compose"
--      Show scrollback in one window and the current shell command in another.
--      The command buffer is freely editable.  On ZZ, the whole edited command
--      replaces ZLE's current $BUFFER.
--
-- The zsh side communicates with this module entirely through temporary files.
-- This may look slightly more elaborate than environment variables, but it
-- means multiline commands, quotes, Unicode etc. don't require shell escaping.

local M = {}

local api = vim.api

-------------------------------------------------------------------------------
-- Small file helpers
-------------------------------------------------------------------------------

local function read_all(path)
	local f, err = io.open(path, "rb")

	if not f then
		error(("cannot read %s: %s"):format(path, err))
	end

	local text = f:read("*a") or ""
	f:close()

	return text
end

local function write_all(path, text)
	local f, err = io.open(path, "wb")

	if not f then
		error(("cannot write %s: %s"):format(path, err))
	end

	f:write(text)
	f:close()
end

-------------------------------------------------------------------------------
-- Environment supplied by the zsh widget.
-------------------------------------------------------------------------------

local function config()
	return {
		mode = vim.env.ZLE_SCROLLBACK_MODE or "pick",

		-- Where accepted text / composed command should be written.
		result = assert(vim.env.ZLE_SCROLLBACK_RESULT),

		-- Existence/content of this file distinguishes "accepted empty command"
		-- from "cancelled".
		accepted = assert(vim.env.ZLE_SCROLLBACK_ACCEPTED),

		-- Only really needed by compose mode:
		command = vim.env.ZLE_SCROLLBACK_COMMAND,
		prefix = vim.env.ZLE_SCROLLBACK_PREFIX,

		-- Compose mode writes the portion of the command before the Neovim cursor
		-- here.  zsh can then reconstruct $CURSOR exactly.
		cursor_result = vim.env.ZLE_SCROLLBACK_CURSOR_RESULT,
	}
end

-------------------------------------------------------------------------------
-- Convert a string into Neovim buffer lines.
--
-- vim.split() deliberately preserves empty lines here.  Thus:
--
--     "foo\nbar"  -> { "foo", "bar" }
--     "foo\n"     -> { "foo", "" }
--     ""          -> { "" }
--
-- That's important for multiline ZLE buffers.
-------------------------------------------------------------------------------

local function text_to_lines(text)
	return vim.split(text, "\n", {
		plain = true,
		trimempty = false,
	})
end

local function buffer_text(buf)
	return table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

-------------------------------------------------------------------------------
-- Quit helpers
-------------------------------------------------------------------------------

local function accept(cfg)
	-- We don't use result-file size as our success indicator because accepting
	-- an *empty* command is perfectly legitimate.
	write_all(cfg.accepted, "1")
	vim.cmd("qa!")
end

local function cancel()
	-- No accepted marker -> zsh leaves its command line untouched.
	vim.cmd("qa!")
end

-------------------------------------------------------------------------------
-- Configure the scrollback buffer shared by both modes.
-------------------------------------------------------------------------------

local function setup_scrollback(buf)
	-- It is source material, never something we want to accidentally edit.
	vim.bo[buf].readonly = true
	vim.bo[buf].modifiable = false
	vim.bo[buf].swapfile = false

	vim.wo.wrap = false
	vim.wo.cursorline = true
	vim.wo.scrolloff = 3

	-- Terminal output you're interested in is normally recent, so begin at EOF.
	local last_line = api.nvim_buf_line_count(buf)

	api.nvim_win_set_cursor(0, {
		math.max(last_line, 1),
		0,
	})
end

-------------------------------------------------------------------------------
-- PICK MODE
--
-- Exactly the simple behaviour from the first version:
--
--     visual selection -> y -> close Neovim -> insert at shell cursor
-------------------------------------------------------------------------------

local function setup_pick(cfg, scrollback_buf)
	local function accept_selection()
		-- mode() here is v, V, or Ctrl-V, so getregion() respects characterwise,
		-- linewise and blockwise selection respectively.
		local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
			type = vim.fn.mode(),
		})

		write_all(cfg.result, table.concat(region, "\n"))

		accept(cfg)
	end

	-- Override y ONLY in Visual mode and ONLY in this temporary scrollback
	-- buffer.  Normal-mode y remains untouched.
	vim.keymap.set("x", "y", accept_selection, {
		buffer = scrollback_buf,
		silent = true,
		desc = "Insert scrollback selection into shell command",
	})

	vim.keymap.set("x", "<CR>", accept_selection, {
		buffer = scrollback_buf,
		silent = true,
		desc = "Insert scrollback selection into shell command",
	})

	-- ZQ has its usual intuitive meaning: quit without accepting anything.
	vim.keymap.set("n", "ZQ", cancel, {
		buffer = scrollback_buf,
		silent = true,
		desc = "Cancel scrollback selection",
	})

	api.nvim_echo({
		{ "scrollback pick  ", "ModeMsg" },
		{ "v/V/C-v select  ", "Normal" },
		{ "y accept  ", "Normal" },
		{ "ZQ cancel", "Normal" },
	}, false, {})
end

-------------------------------------------------------------------------------
-- COMPOSE MODE
-------------------------------------------------------------------------------

local function setup_compose(cfg, scrollback_buf)
	assert(cfg.command, "ZLE_SCROLLBACK_COMMAND is not set")
	assert(cfg.prefix, "ZLE_SCROLLBACK_PREFIX is not set")
	assert(cfg.cursor_result, "ZLE_SCROLLBACK_CURSOR_RESULT is not set")

	---------------------------------------------------------------------------
	-- Construct a scratch buffer containing the current ZLE $BUFFER.
	---------------------------------------------------------------------------

	local command_text = read_all(cfg.command)
	local command_lines = text_to_lines(command_text)

	-- listed=false:
	--   don't pollute :ls
	--
	-- scratch=true:
	--   nofile-ish disposable buffer with no swapfile concerns
	local command_buf = api.nvim_create_buf(false, true)

	api.nvim_buf_set_name(command_buf, "zle://command-line")

	api.nvim_buf_set_lines(command_buf, 0, -1, false, command_lines)

	-- Useful if your normal Neovim config has shell syntax highlighting,
	-- Treesitter, completion, etc.
	vim.bo[command_buf].filetype = "zsh"

	---------------------------------------------------------------------------
	-- Put it underneath the scrollback.
	--
	-- Give short commands a compact editing area, but don't let a large
	-- multiline command consume the entire screen.
	---------------------------------------------------------------------------

	local height = math.max(4, math.min(#command_lines + 2, 12))

	vim.cmd(("botright %dsplit"):format(height))

	local command_win = api.nvim_get_current_win()

	api.nvim_win_set_buf(command_win, command_buf)

	vim.wo[command_win].wrap = false
	vim.wo[command_win].cursorline = true

	---------------------------------------------------------------------------
	-- Restore the shell cursor position.
	--
	-- The zsh widget gives us $LBUFFER -- the exact text preceding the ZLE
	-- cursor -- in a separate file.
	--
	-- Rather than trying to reconcile zsh's character indexing and Neovim's
	-- byte-column indexing numerically, we simply inspect that exact prefix.
	---------------------------------------------------------------------------

	local prefix = read_all(cfg.prefix)
	local prefix_lines = text_to_lines(prefix)

	local cursor_row = #prefix_lines

	-- Lua's #string is byte length, which is *exactly* what nvim_win_set_cursor()
	-- expects for its column.  That also makes this work properly for UTF-8.
	local cursor_col = #(prefix_lines[#prefix_lines] or "")

	-- Defensive bounds checks in case some unusual autocmd altered the buffer.
	cursor_row = math.max(1, math.min(cursor_row, api.nvim_buf_line_count(command_buf)))

	local current_line = api.nvim_buf_get_lines(command_buf, cursor_row - 1, cursor_row, false)[1] or ""

	cursor_col = math.min(cursor_col, #current_line)

	api.nvim_win_set_cursor(command_win, {
		cursor_row,
		cursor_col,
	})

	---------------------------------------------------------------------------
	-- Reconstruct the text preceding the current Neovim cursor.
	--
	-- We write this back separately from the completed command because zsh
	-- needs it to reconstruct $CURSOR after assigning the new $BUFFER.
	---------------------------------------------------------------------------

	local function command_prefix()
		local pos = api.nvim_win_get_cursor(command_win)

		local row = pos[1]
		local col = pos[2]

		local lines = api.nvim_buf_get_lines(command_buf, 0, -1, false)

		local before = {}

		-- Every complete line before the cursor line.
		for i = 1, row - 1 do
			before[#before + 1] = lines[i]
		end

		-- Plus the portion of the cursor line preceding the cursor.
		--
		-- Neovim columns are zero-based byte offsets.
		--
		-- Lua string.sub() is one-based and inclusive, so:
		--
		--     col == 0 -> sub(1, 0) == ""
		--     col == 3 -> first three bytes
		before[#before + 1] = (lines[row] or ""):sub(1, col)

		return table.concat(before, "\n")
	end

	---------------------------------------------------------------------------
	-- Accept the edited command.
	---------------------------------------------------------------------------

	local function accept_command()
		write_all(cfg.result, buffer_text(command_buf))

		write_all(cfg.cursor_result, command_prefix())

		accept(cfg)
	end

	---------------------------------------------------------------------------
	-- Keybindings.
	--
	-- The interesting design choice here is what we DON'T map.
	--
	-- In compose mode:
	--
	--     y
	--     p
	--     "
	--     d
	--     c
	--     macros
	--
	-- all retain completely ordinary Vim behaviour.
	--
	-- This means you can yank from scrollback and paste into the command buffer
	-- using whichever register/motions you already instinctively use.
	---------------------------------------------------------------------------

	for _, buf in ipairs({
		scrollback_buf,
		command_buf,
	}) do
		vim.keymap.set("n", "ZZ", accept_command, {
			buffer = buf,
			silent = true,
			desc = "Accept composed shell command",
		})

		vim.keymap.set("n", "ZQ", cancel, {
			buffer = buf,
			silent = true,
			desc = "Cancel shell command composition",
		})
	end

	---------------------------------------------------------------------------
	-- Commands are handy if you forget the mappings, and make experimentation
	-- easier while modifying this.
	---------------------------------------------------------------------------

	api.nvim_create_user_command("AcceptZleCommand", accept_command, {})

	api.nvim_create_user_command("CancelZleCommand", cancel, {})

	---------------------------------------------------------------------------
	-- Start focused on the command itself.
	--
	-- I think this is preferable to starting in scrollback: invoking compose
	-- mode should feel like an enhanced edit-command-line first, scrollback
	-- browser second.
	---------------------------------------------------------------------------

	api.nvim_set_current_win(command_win)

	api.nvim_echo({
		{ "shell compose  ", "ModeMsg" },
		{ "Ctrl-w k/j: command ↔ scrollback  ", "Normal" },
		{ "y/p normally  ", "Normal" },
		{ "ZZ accept  ", "Normal" },
		{ "ZQ cancel", "Normal" },
	}, false, {})
end

-------------------------------------------------------------------------------
-- Entry point
-------------------------------------------------------------------------------

function M.setup()
	local cfg = config()

	-- Neovim was started with the scrollback file as its initial buffer.
	local scrollback_buf = api.nvim_get_current_buf()

	setup_scrollback(scrollback_buf)

	if cfg.mode == "compose" then
		setup_compose(cfg, scrollback_buf)
	else
		setup_pick(cfg, scrollback_buf)
	end
end

return M
