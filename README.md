# mason-conform.nvim

mason-conform bridges [mason.nvim](https://github.com/williamboman/mason.nvim) with the [conform.nvim](https://github.com/stevearc/conform.nvim) plugin - making it easier to use both plugins together.

(It is also a blatant copy of [mason-lspconfig](https://github.com/williamboman/mason-lspconfig.nvim), all credits to [williamboman](https://github.com/williamboman))

# Requirements

-   Neovim version Neovim 0.10+
-   [mason.nvim](https://github.com/williamboman/mason.nvim)
-   [conform.nvim](https://github.com/stevearc/conform.nvim)

# Installation

## [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "pedrog14/mason-conform.nvim",
    lazy = false,
    dependencies = "williamboman/mason.nvim",
    opts = {}
}
```

# Commands

Available after loading the plugin...

-   `:ConformInstall [<source>...]` - installs the provided formatters
-   `:ConformUninstall [<source> ...]` - uninstalls the provided formatters

# Configuration

Example:

```lua
opts = {
    ensure_installed = { "stylua", "prettier" },
    handlers = {
        function(formatter_name)
            require("conform").formatters_by_ft = require("mason-conform").formatter_handler(formatter_name)
        end,
    },
}
```
