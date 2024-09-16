# neovim config

Respects the following environment variables:

- `K6E_EXTRA_PLUGINS`: comma-separated list of plugin specs in `lua/plugins` which Lazy will attempt to source
- `K6E_SESSION_PLUGINS`: comma-separated list of plugin specs in `lua/plugins` which Lazy will attempt to source; implicitly ephemeral, for this session only 
- `K6E_COPILOT_LUA`: if 1, use copilot-lua plugin, rather than copilot; requires that the `copulot` plugin is loaded
