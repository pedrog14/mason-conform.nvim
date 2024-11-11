local M = {}

---@class MasonConformSettings
local DEFAULT_SETTINGS = {
    ---@type string[]
    ensure_installed = {},

    ---@type boolean
    automatic_installation = false,

    ---@type table<string, fun(server_name: string)>?
    handlers = nil,
}

M._DEFAULT_SETTINGS = DEFAULT_SETTINGS
M.current = M._DEFAULT_SETTINGS

---@param opts MasonConformSettings
function M.set(opts)
    M.current = vim.tbl_deep_extend("force", M.current, opts)
end

return M
