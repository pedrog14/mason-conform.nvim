local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local notify = require "mason-conform.notify"

---@async
---@param user_args string[]: The arguments, as provided by the user.
local function parse_packages_from_user_args(user_args)
    local registry = require "mason-registry"
    local Package = require "mason-core.package"
    local formatter_mapping = require "mason-conform.mappings.formatter"
    local language_mapping = require "mason-conform.mappings.language"
    local language_map = language_mapping.get_language_map()

    return _.filter_map(function(formatter_specifier)
        local formatter_name, version = Package.Parse(formatter_specifier)
        return Optional
            -- 1. first see if the provided arg is an actual conform formatter name
            .of_nilable(formatter_mapping.conform_to_package[formatter_name])
            -- 2. if not, check if it's a language specifier (e.g., "typescript" or "java")
            :or_(function()
                return Optional.of_nilable(language_map[formatter_name])
                    :if_not_present(function()
                        notify(("Could not find formatter %q."):format(formatter_name), vim.log.levels.ERROR)
                    end)
                    :map(function(package_names)
                        package_names = _.filter(function(package_name)
                            return formatter_mapping.package_to_conform[package_name] ~= nil
                        end, package_names)

                        if #package_names == 0 then
                            return nil
                        end

                        return a.promisify(vim.ui.select)(package_names, {
                            prompt = ("Please select which formatter you want to install for language %q:"):format(
                                formatter_name
                            ),
                            format_item = function(package_name)
                                local conform_name = formatter_mapping.package_to_conform[package_name]
                                if registry.is_installed(package_name) then
                                    return ("%s (installed)"):format(conform_name)
                                else
                                    return conform_name
                                end
                            end,
                        })
                    end)
            end)
            :map(function(package_name)
                return { package = package_name, version = version }
            end)
    end, user_args)
end

---@async
local function parse_packages_from_heuristics()
    local formatter_mapping = require "mason-conform.mappings.formatter"
    local registry = require "mason-registry"

    -- Prompt user which formatter they want to install (based on the current filetype)
    local current_ft = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "filetype")
    local filetype_mapping = require "mason-conform.mappings.filetype"
    local formatter_names = _.flatten(_.concat(filetype_mapping[current_ft] or {}, filetype_mapping["*"] or {}))
    if #formatter_names == 0 then
        notify(("No formatters found for filetype %q."):format(current_ft), vim.log.levels.ERROR)
        return {}
    end
    local formatter_name = a.promisify(vim.ui.select)(formatter_names, {
        prompt = ("Please select which formatter you want to install for filetype %q:"):format(current_ft),
        format_item = function(formatter_name)
            if registry.is_installed(formatter_mapping.conform_to_package[formatter_name]) then
                return ("%s (installed)"):format(formatter_name)
            else
                return formatter_name
            end
        end,
    })
    if formatter_name == nil then
        return {}
    end
    local package_name = formatter_mapping.conform_to_package[formatter_name]
    return { { package = package_name, version = nil } }
end

local parse_packages_to_install = _.cond {
    { _.compose(_.gt(0), _.length), parse_packages_from_user_args },
    { _.compose(_.equals(0), _.length), parse_packages_from_heuristics },
    { _.T, _.always {} },
}

local FormatterInstall = a.scope(function(formatters)
    local packages_to_install = parse_packages_to_install(formatters)
    if #packages_to_install > 0 then
        require("mason.api.command").MasonInstall(_.map(function(target)
            if target.version then
                return ("%s@%s"):format(target.package, target.version)
            else
                return target.package
            end
        end, packages_to_install))
        local ui = require "mason.ui"
        ui.set_view "Formatter"
    end
end)

vim.api.nvim_create_user_command("FormatterInstall", function(opts)
    FormatterInstall(opts.fargs)
end, {
    desc = "Install one or more formatters.",
    nargs = "*",
    complete = "custom,v:lua.mason_conform_completion.available_formatter_completion",
})

local function FormatterUninstall(formatters)
    local formatter_mapping = require "mason-conform.mappings.formatter"
    require("mason.api.command").MasonUninstall(_.map(function(conform_name)
        return formatter_mapping.conform_to_package[conform_name] or conform_name
    end, formatters))
    require("mason.ui").set_view "Formatter"
end

vim.api.nvim_create_user_command("FormatterUninstall", function(opts)
    FormatterUninstall(opts.fargs)
end, {
    desc = "Uninstall one or more formatters.",
    nargs = "+",
    complete = "custom,v:lua.mason_conform_completion.installed_formatter_completion",
})

-- selene: allow(global_usage)
_G.mason_conform_completion = {
    available_formatter_completion = function()
        local available_formatters = require("mason-conform").get_available_formatters()
        local language_mapping = require "mason-conform.mappings.language"
        local sort_deduped = _.compose(_.sort_by(_.identity), _.uniq_by(_.identity))
        local completions = sort_deduped(_.concat(_.keys(language_mapping.get_language_map()), available_formatters))
        return table.concat(completions, "\n")
    end,
    installed_formatter_completion = function()
        local installed_formatters = require("mason-conform").get_installed_formatters()
        return table.concat(installed_formatters, "\n")
    end,
}

return {
    FormatterInstall = FormatterInstall,
    FormatterUninstall = FormatterUninstall,
}
