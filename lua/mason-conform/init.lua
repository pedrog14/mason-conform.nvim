local _ = require "mason-core.functional"
local log = require "mason-core.log"
local platform = require "mason-core.platform"
local settings = require "mason-conform.settings"

local M = {}

local function check_and_notify_bad_setup_order()
    local mason_ok, mason = pcall(require, "mason")
    local is_bad_order = not mason_ok or mason.has_setup == false
    local impacts_functionality = not mason_ok or #settings.current.ensure_installed > 0
    if is_bad_order and impacts_functionality then
        require "mason-conform.notify"(
            "mason.nvim has not been set up. Make sure to set up 'mason' before 'mason-conform'.",
            vim.log.levels.WARN
        )
    end
end

---@param config MasonConformSettings | nil
function M.setup(config)
    if config then
        settings.set(config)
    end

    check_and_notify_bad_setup_order()

    if not platform.is_headless and #settings.current.ensure_installed > 0 then
        require "mason-conform.ensure_installed"()
    end

    local registry = require "mason-registry"
    if registry.register_package_aliases then
        registry.register_package_aliases(_.map(function(formatter_name)
            return { formatter_name }
        end, require("mason-conform.mappings.formatter").package_to_conform))
    end

    require "mason-conform.api.command"

    if settings.current.handlers then
        M.setup_handlers(settings.current.handlers)
    end
end

---See `:h mason-conform.setup_handlers()`
---@param handlers table<string, fun(formatter_name: string)>
function M.setup_handlers(handlers)
    local Optional = require "mason-core.optional"
    local formatter_mapping = require "mason-conform.mappings.formatter"
    local registry = require "mason-registry"
    local notify = require "mason-conform.notify"

    local default_handler = Optional.of_nilable(handlers[1])

    _.each(function(handler)
        if type(handler) == "string" and not formatter_mapping.conform_to_package[handler] then
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
        return Optional.of_nilable(formatter_mapping.package_to_conform[pkg_name])
    end

    local function call_handler(formatter_name)
        log.fmt_trace("Checking handler for %s", formatter_name)
        Optional.of_nilable(handlers[formatter_name]):or_(_.always(default_handler)):if_present(function(handler)
            log.fmt_trace("Calling handler for %s", formatter_name)
            local ok, err = pcall(handler, formatter_name)
            if not ok then
                notify(err, vim.log.levels.ERROR)
            end
        end)
    end

    local installed_formatters = _.filter_map(get_formatter_name, registry.get_installed_package_names())
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
    local Optional = require "mason-core.optional"
    local registry = require "mason-registry"
    local formatter_mapping = require "mason-conform.mappings.formatter"

    return _.filter_map(function(pkg_name)
        return Optional.of_nilable(formatter_mapping.package_to_conform[pkg_name])
    end, registry.get_installed_package_names())
end

---@param filetype string | string[]
local function is_formatter_in_filetype(filetype)
    local filetype_mapping = require "mason-conform.mappings.filetype"

    local function get_formatters_by_filetype(ft)
        return filetype_mapping[ft] or {}
    end

    local formatter_candidates = _.compose(
        _.set_of,
        _.cond {
            { _.is "string", get_formatters_by_filetype },
            { _.is "table", _.compose(_.flatten, _.map(get_formatters_by_filetype)) },
            { _.T, _.always {} },
        }
    )(filetype)

    ---@param formatter_name string
    ---@return boolean
    return function(formatter_name)
        return formatter_candidates[formatter_name]
    end
end

---Get a list of available formatters in mason-registry
---@param filter { filetype: string | string[] }?: (optional) Used to filter the list of formatter names.
--- The available keys are
---   - filetype (string | string[]): Only return formatters with matching filetype
---@return string[]
function M.get_available_formatters(filter)
    local registry = require "mason-registry"
    local formatter_mapping = require "mason-conform.mappings.formatter"
    local Optional = require "mason-core.optional"
    filter = filter or {}
    local predicates = {}

    if filter.filetype then
        table.insert(predicates, is_formatter_in_filetype(filter.filetype))
    end

    return _.filter_map(function(pkg_name)
        return Optional.of_nilable(formatter_mapping.package_to_conform[pkg_name]):map(function(formatter_name)
            if #predicates == 0 or _.all_pass(predicates, formatter_name) then
                return formatter_name
            end
        end)
    end, registry.get_all_package_names())
end

---Returns the "conform <-> mason" mapping tables.
---@return { conform_to_mason: table<string, string>, mason_to_conform: table<string, string> }
function M.get_mappings()
    local mappings = require "mason-conform.mappings.formatter"
    return {
        conform_to_mason = mappings.conform_to_package,
        mason_to_conform = mappings.package_to_conform,
    }
end

---@param formatter_name string
---@return conform.FiletypeFormatter
function M.formatter_handler(formatter_name)
    local fts = {}
    for ft, fmts in pairs(require "mason-conform.mappings.filetype") do
        for _, fmt in ipairs(fmts) do
            if fmt == formatter_name then
                if not fts[ft] then
                    fts[ft] = {}
                end
                fts[ft][#fts[ft] + 1] = formatter_name
                break
            end
        end
    end
    local fmt_by_ft = vim.deepcopy(require("conform").formatters_by_ft)
    return vim.tbl_deep_extend("force", fmt_by_ft, fts)
end

return M
