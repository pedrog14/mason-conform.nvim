local M = {}

local registry = require("mason-registry")

---@return table<string, string[]>
function M.get_language_map()
	if not registry.get_all_package_specs then
		return {}
	end
	---@type table<string, string[]>
	local languages = {}
	for _, pkg_info in ipairs(registry.get_all_package_specs()) do
		for _, language in ipairs(pkg_info.languages) do
			language = string.lower(language)
			if not languages[language] then
				languages[language] = {}
			end
			table.insert(languages[language], pkg_info.name)
		end
	end
	return languages
end

vim.print(M.get_language_map())

return M
