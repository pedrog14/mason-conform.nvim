local M = {}

M.opts = {
	ensure_installed = {},
	handlers = {},
}

function M.default_handlers()
	local registry = require("mason-registry")
	local languages = {}
	for _, pkg_info in ipairs(registry.get_installed_packages()) do
		for _, type in ipairs(pkg_info.spec.categories) do
			if type == "Formatter" then
				for _, lang in ipairs(pkg_info.spec.languages) do
					lang = string.lower(lang)
					if not languages[lang] then
						languages[lang] = {}
					end
					table.insert(languages[lang], pkg_info.name)
				end
				break
			end
		end
	end
	return languages
end

function M.setup(opts)
	M.opts.ensure_installed = opts.ensure_installed or {}
	M.opts.handlers = opts.handlers or {}

	require("mason-conform.auto_install")()
	require("conform").formatters_by_ft = M.opts.handlers
end

return M
