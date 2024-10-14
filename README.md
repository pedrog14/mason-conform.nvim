# mason-conform.nvim

Automatically install formatters registered with [conform.nvim](https://github.com/stevearc/conform.nvim) via [Mason](https://github.com/williamboman/mason.nvim).

# Install
### lazy.nvim

```lua
{
    "pedrog14/mason-conform.nvim",
    dependencies = "williamboman/mason.nvim",
    opts = {},
}
```

# Configuration

```lua
require("mason-conform").setup({
    ensure_installed = { "prettierd" }, -- List of formatters install automatically
    handlers = require("mason-conform").default_handlers -- List of languages and respective formatters installed by mason-conform
})
```

# Available formatters

Only formatters that are available in the [mason registry](https://github.com/mason-org/mason-registry)
can be downloaded automatically. If the formatter is available in the registry and it's not being
downloaded, this plugin might be missing a `conform` => `mason` mapping in the file [lua/mason-conform/mappings/formatter.lua](lua/mason-conform/mappings/formatter.lua).

# License

`mason-conform.nvim` takes heavy insperation from [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)
