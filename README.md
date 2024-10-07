# mason-conform.nvim

Automatically install formatters registered with [conform.nvim](https://github.com/stevearc/conform.nvim) via [Mason](https://github.com/williamboman/mason.nvim).

# Install

```lua
require("lazy").setup({
    "williamboman/mason.nvim",
    "stevearc/conform.nvim",
    "pedrog14/mason-conform.nvim",
})
```

# Setup

It's crucial to setup plugins in the following order:

- `mason.nvim`
- `conform.nvim`
- `mason-conform.nvim`

Otherwise `mason-conform.nvim` will not have enough information about configured formatters and
access the mason registry.

# Configuration

```lua
require("mason-conform").setup({
    ensure_installed = { "prettierd" }, -- List of formatters install automatically
    handlers = require("mason-conform").default_handlers() -- List of languages and respective formatters installed by mason-conform
})
```

# Available formatters

Only formatters that are available in the [mason registry](https://github.com/mason-org/mason-registry)
can be downloaded automatically. If the formatter is available in the registry and it's not being
downloaded, this plugin might be missing a `conform` => `mason` mapping in the file [lua/mason-conform/mapping.lua](lua/mason-conform/mapping.lua).

# License

`mason-conform.nvim` is a blatant copy of zapling's [mason-conform.nvim](https://github.com/zapling/mason-conform.nvim), which is also a blatant copy of [mason-nvim-lint](https://github.com/rshkarin/mason-nvim-lint)
which in turn takes heavy insperation from [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)
