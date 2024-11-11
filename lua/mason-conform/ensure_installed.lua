local notify = require "mason-conform.notify"
local registry = require "mason-registry"
local settings = require "mason-conform.settings"

---@param conform_formatter_name string
local function resolve_package(conform_formatter_name)
    local Optional = require "mason-core.optional"
    local formatter_mapping = require "mason-conform.mappings.formatter"

    return Optional.of_nilable(formatter_mapping.conform_to_package[conform_formatter_name]):map(function(package_name)
        local ok, pkg = pcall(registry.get_package, package_name)
        if ok then
            return pkg
        end
    end)
end

local function ensure_installed()
    for _, formatter_identifier in ipairs(settings.current.ensure_installed) do
        local Package = require "mason-core.package"

        local formatter_name, version = Package.Parse(formatter_identifier)
        resolve_package(formatter_name)
            :if_present(
                ---@param pkg Package
                function(pkg)
                    if not pkg:is_installed() then
                        require("mason-conform.install").install(pkg, version)
                    end
                end
            )
            :if_not_present(function()
                notify(
                    ("[mason-conform.nvim] Server %q is not a valid entry in ensure_installed. Make sure to only provide conform server names."):format(
                        formatter_name
                    ),
                    vim.log.levels.WARN
                )
            end)
    end
end

if registry.refresh then
    return function()
        registry.refresh(vim.schedule_wrap(ensure_installed))
    end
else
    return ensure_installed
end
