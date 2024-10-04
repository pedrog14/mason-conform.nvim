local M = {}

function M.default_handlers(installed)
	local registry = require("mason-registry")
	local form = {}
	for _, pkg_info in ipairs(registry.get_all_packages()) do
		for _, type in ipairs(pkg_info.spec.categories) do
			if type == "Formatter" then
				for _, lang in ipairs(pkg_info.spec.languages) do
					lang = string.lower(lang)
					if form[lang] == nil then
						form[lang] = pkg_info.name ~= installed and { pkg_info.name } or nil
					else
						table.insert(form[lang], pkg_info.name)
					end
				end
			end
		end
	end
	return form
end

M.opts = {
	ensure_installed = {},
	handlers = {},
}

function M.setup(opts)
	M.opts.ensure_installed = opts.ensure_installed or {}
	M.opts.handlers = opts.handlers or {}

	require("mason-conform.auto_install")()
	require("conform").formatters_by_ft = M.opts.handlers
end

return M
