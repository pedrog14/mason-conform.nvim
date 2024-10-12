local M = {}

local notify = require("mason-conform.notify")
local formatter_mapping = require("mason-conform.mappings.formatter")

function M.install(pkg, version)
    local conform_name = formatter_mapping.package_to_conform[pkg.name]

    vim.notify(("[mason-conform] installing %s"):format(conform_name))

    return pkg:install({ version = version }):once(
        "closed",
        vim.schedule_wrap(function()
            if pkg:is_installed() then
                notify(
                    ("[mason-conform] %s was successfully installed"):format(
                        conform_name
                    )
                )
            else
                notify(
                    ("[mason-conform] failed to install %s. Installation logs are available in :Mason and :MasonLog"):format(
                        conform_name
                    ),
                    vim.log.levels.ERROR
                )
            end
        end)
    )
end

return M
