local M = {}

local _ = require("mason-core.functional")
local log = require("mason-core.log")
local platform = require("mason-core.platform")
local settings = require("mason-conform.settings")

local function check_and_notify_bad_setup_order()
    local mason_ok, mason = pcall(require, "mason")
    local is_bad_order = not mason_ok or mason.has_setup == false
    local impacts_functionality = not mason_ok
        or #settings.current.ensure_installed > 0
    if is_bad_order and impacts_functionality then
        require("mason-lspconfig.notify")(
            "mason.nvim has not been set up. Make sure to set up 'mason' before 'mason-conform'.",
            vim.log.levels.WARN
        )
    end
end

function M.setup(config)
    if config then
        settings.set(config)
    end

    check_and_notify_bad_setup_order()

    if not platform.is_headless and #settings.current.ensure_installed > 0 then
        require("mason-conform.ensure_installed")()
    end

    local registry = require("mason-registry")
    if registry.register_package_aliases then
        registry.register_package_aliases(
            _.map(function(formatter_name)
                return { formatter_name }
            end, require("mason-conform.mappings.formatter").package_to_conform)
        )
    end

    -- API settings
    require("mason-conform.api.command")

    if settings.current.handlers then
        M.setup_handlers(settings.current.handlers)
    end
end

---@param handlers table<string, fun(formatter_name: string)>
function M.setup_handlers(handlers)
    local Optional = require("mason-core.optional")
    local formatter_mapping = require("mason-conform.mappings.formatter")
    local registry = require("mason-registry")
    local notify = require("mason-conform.notify")

    local default_handler = Optional.of_nilable(handlers[1])

    _.each(function(handler)
        if
            type(handler) == "string"
            and not formatter_mapping.conform_to_package[handler]
        then
            notify(
                ("mason-conform.setup_handlers: Received handler for unknown conform formatter name: %s."):format(
                    handler
                ),
                vim.log.levels.WARN
            )
        end
    end, _.keys(handlers))

    ---@param pkg_name string
    local function get_formatter_name(pkg_name)
        return Optional.of_nilable(
            formatter_mapping.package_to_conform[pkg_name]
        )
    end

    local function call_handler(formatter_name)
        log.fmt_trace("Checking handler for %s", formatter_name)
        Optional.of_nilable(handlers[formatter_name])
            :or_(_.always(default_handler))
            :if_present(function(handler)
                log.fmt_trace("Calling handler for %s", formatter_name)
                local ok, err = pcall(handler, formatter_name)
                if not ok then
                    notify(err, vim.log.levels.ERROR)
                end
            end)
    end

    local installed_formatters =
        _.filter_map(get_formatter_name, registry.get_installed_package_names())
    _.each(call_handler, installed_formatters)
    registry:on(
        "package:install:success",
        vim.schedule_wrap(function(pkg)
            get_formatter_name(pkg.name):if_present(call_handler)
        end)
    )
end

---@return string[]
function M.get_installed_formatters()
    local Optional = require("mason-core.optional")
    local registry = require("mason-registry")
    local formatter_mapping = require("mason-conform.mappings.formatter")

    return _.filter_map(function(pkg_name)
        return Optional.of_nilable(
            formatter_mapping.package_to_conform[pkg_name]
        )
    end, registry.get_installed_package_names())
end

---Get a list of available formatters in mason-registry
---@param filter { filetype: string | string[] }?: (optional) Used to filter the list of formatter names.
--- The available keys are
---   - filetype (string | string[]): Only return formatters with matching filetype
---@return string[]
function M.get_available_formatters(filter)
    local registry = require("mason-registry")
    local formatter_mapping = require("mason-conform.mappings.formatter")
    local Optional = require("mason-core.optional")
    filter = filter or {}
    local predicates = {}

    return _.filter_map(function(pkg_name)
        return Optional.of_nilable(
            formatter_mapping.package_to_conform[pkg_name]
        )
            :map(function(formatter_name)
                if
                    #predicates == 0 or _.all_pass(predicates, formatter_name)
                then
                    return formatter_name
                end
            end)
    end, registry.get_all_package_names())
end

---Returns the "conform <-> mason" mapping tables.
---@return { conform_to_mason: table<string, string>, mason_to_conform: table<string, string> }
function M.get_mappings()
    local mappings = require("mason-conform.mappings.formatter")
    return {
        conform_to_mason = mappings.conform_to_package,
        mason_to_conform = mappings.package_to_conform,
    }
end

M.default_handlers = {
    function(formatter_name)
        local formatters_by_ft = require("conform").formatters_by_ft

        local conform_to_package =
            require("mason-conform.mappings.formatter").conform_to_package

        local get_languages = function(pkg_name)
            return require("mason-registry").get_package(pkg_name).spec.languages
        end

        for _, language in
            ipairs(get_languages(conform_to_package[formatter_name]))
        do
            language = language:lower()
            if not formatters_by_ft[language] then
                formatters_by_ft[language] = {}
            end
            table.insert(formatters_by_ft[language], formatter_name)
        end
    end,
}

return M
