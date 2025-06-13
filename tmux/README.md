# TMUX Configuration

A comprehensive tmux configuration optimized for development workflows with vi-style keybindings and enhanced productivity features.

## 🚀 Key Features

### **Smart Directory Handling**
- New panes and windows inherit current directory
- No more navigating back to working directory after splits

### **Vi-Style Navigation**
- `h/j/k/l` for pane navigation
- `H/J/K/L` for pane resizing
- Vi-mode copy/paste with `v` and `y`

### **Intuitive Split Keys**
- `|` for horizontal splits
- `-` for vertical splits
- Both open in current directory

### **Enhanced Status Bar**
- Clean, informative status line
- Real-time clock updates
- Activity monitoring

### **Mouse Support**
- Click to select panes
- Drag to resize panes
- Scroll wheel in copy mode

## 📋 Quick Reference

### **Pane Management**
| Key | Action |
|-----|--------|
| `prefix + \|` | Split horizontally (current dir) |
| `prefix + -` | Split vertically (current dir) |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + H/J/K/L` | Resize panes |
| `prefix + z` | Zoom/unzoom pane |
| `prefix + x` | Kill pane (with confirmation) |
| `prefix + Tab` | Switch to last pane |

### **Window Management**
| Key | Action |
|-----|--------|
| `prefix + c` | New window (current dir) |
| `prefix + n/p` | Next/previous window |
| `prefix + 1-9` | Jump to window by number |
| `prefix + ,` | Rename window |
| `prefix + X` | Kill window (with confirmation) |

### **Copy Mode**
| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `v` | Start selection |
| `y` | Copy and exit |
| `prefix + ]` | Paste |

### **Configuration**
| Key | Action |
|-----|--------|
| `prefix + r` | Reload config |
| `prefix + e` | Edit config |

## 🛠 Installation

The tmux configuration is managed by the dotfiles link script:

```bash
# Link tmux configuration
./link.sh link tmux

# Check status
./link.sh status

# Reload tmux config (in tmux session)
prefix + r
```

## 🎨 Customization

### **Color Scheme**
The configuration uses a dark theme with:
- Dark grey status bar background
- Cyan active pane borders
- Orange message backgrounds

### **Changing Prefix Key**
To use `Ctrl+a` instead of `Ctrl+b`, uncomment these lines in `tmux.conf`:
```bash
# set-option -g prefix C-a
# bind-key C-a send-prefix
# unbind C-b
```

### **System Clipboard Integration**
To copy to system clipboard, uncomment the appropriate line for your OS:
```bash
# Linux (X11)
# bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

# macOS
# bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel 'pbcopy'
```

## 📁 Directory Structure

```
tmux/
├── tmux.conf          # Main configuration file
└── README.md          # This documentation
```

## 🔧 Settings Overview

### **Window/Pane Settings**
- Windows and panes start at index 1
- Automatic window renumbering
- Preserve custom window names
- 10,000 line scrollback buffer

### **Terminal Settings**
- 256 color support
- Fast escape time for vim
- Extended display time for pane numbers

### **Activity Monitoring**
- Monitor activity in background windows
- Visual alerts in status bar
- Configurable alert behavior

## 💡 Tips & Tricks

1. **Quick Pane Creation**: Use `|` and `-` for intuitive splits
2. **Pane Navigation**: Learn `h/j/k/l` for efficient movement
3. **Copy Mode**: Enter with `[`, navigate with vi keys, copy with `v` then `y`
4. **Zoom Feature**: Use `z` to temporarily fullscreen a pane
5. **Session Management**: Use `prefix + s` to switch between sessions
6. **Config Editing**: Use `prefix + e` to quickly edit configuration

## 🔄 Updates

When you modify the configuration:
1. Use `prefix + r` to reload in existing sessions
2. Or restart tmux completely for major changes
3. Test changes in a separate session first

## 🐛 Troubleshooting

**Colors not working?**
- Ensure your terminal supports 256 colors
- Check `$TERM` environment variable

**Vi keys not working in copy mode?**
- Verify `mode-keys vi` is set
- Check if other software is intercepting keys

**Mouse not working?**
- Ensure terminal supports mouse reporting
- Check if other software is capturing mouse events

For more details, see the extensive comments in `tmux.conf`.
