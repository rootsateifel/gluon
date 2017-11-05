return function(form, uci)
	local site = require 'gluon.site'
	local path = '/lib/gluon/domains'
	local fs = require 'nixio.fs'

	local function read_json(path)

		local json = require 'luci.jsonc'
		local decoder = json.new()
		local sink = decoder:sink()

		local file = assert(io.open(path))

		while true do
			local chunk = file:read(2048)
			if not chunk or chunk:len() == 0 then break end
			sink(chunk)
		end

		file:close()

		return assert(decoder:get())
	end

	local function get_domain_list()
		local list = {}
		for domain_path in io.popen('find ' .. path .. '/ -iname \*.json -print'):lines() do
			local domain_code = domain_path:match(path .. '/(.*)\.json$')
			table.insert(list, domain_code)
		end
		return list
	end

	local s = form:section(Section, nil, translate('gluon-config-mode:domain-select'))

	local o = s:option(ListValue, 'domain', translate('gluon-config-mode:domain'))
	o.optional = false

	if uci:get_bool('gluon-setup-mode', uci:get_first('gluon-setup-mode','setup_mode'), 'configured')  then
		local system = uci:get_first('gluon', 'system')
		o:value(uci:get('gluon', system, 'domain_code') or site.default_domain(), site.domain_name())
	else
		o:value('')
	end

	for _, domain_code in pairs(get_domain_list()) do
		local domain = read_json(path .. '/' .. domain_code .. '.json')
		if not domain.hide_domain then
			o:value(domain_code, domain.domain_name)
		end
	end

	function o:write(data)
		fs.writefile('/tmp/new_domain_code', data)
	end

	return {'gluon'}
end
