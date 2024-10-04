local registry = require("mason-registry")
local mapping = require("mason-conform.mapping")

local function auto_install()
    local config = require("mason-conform").opts

    local formatters_to_install = {}
    for _, formatter in pairs(config.ensure_installed) do
        formatters_to_install[formatter] = 1
    end

    for conformFormatter, _ in pairs(formatters_to_install) do
        local package = mapping.conform_to_package[conformFormatter]
        if package ~= nil then
            require("mason-conform.install").try_install(package)
        end
    end
end

if registry.refresh then
    return function()
        registry.refresh(vim.schedule_wrap(auto_install))
    end
else
    return auto_install
end
