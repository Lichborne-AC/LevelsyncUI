assert(LibStub, "LibDataBroker-1.1 requires LibStub")

local lib, oldminor = LibStub:NewLibrary("LibDataBroker-1.1", 4)
if not lib then return end
oldminor = oldminor or 0

lib.proxies        = lib.proxies        or {}
lib.attributestorage = lib.attributestorage or {}
lib.callbacks      = lib.callbacks      or {}   -- {[eventname] = {[1]=func, ...}}

local function fire(lib, event, ...)
	local handlers = lib.callbacks[event]
	if not handlers then return end
	for i = 1, #handlers do handlers[i](...) end
end

function lib:NewDataObject(name, dataobj)
	if self.proxies[name] then
		error(("A data object with the name %q already exists."):format(name), 2)
	end

	local storage = {}
	self.attributestorage[name] = storage

	if dataobj then
		for k, v in pairs(dataobj) do
			storage[k] = v
		end
	end

	local proxy = setmetatable({}, {
		__index = function(_, key)
			return storage[key]
		end,
		__newindex = function(_, key, value)
			storage[key] = value
			fire(lib, "LibDataBroker_AttributeChanged_" .. name, name, key, value, self.proxies[name])
			fire(lib, "LibDataBroker_AttributeChanged",             name, key, value, self.proxies[name])
		end,
		__metatable = "access denied",
	})

	self.proxies[name] = proxy
	fire(lib, "LibDataBroker_DataObjectCreated", name, proxy)
	return proxy
end

function lib:DataObjectIterator()
	return pairs(self.proxies)
end

function lib:GetDataObjectByName(name)
	return self.proxies[name]
end

function lib:GetNameByDataObject(dataobject)
	for name, obj in pairs(self.proxies) do
		if obj == dataobject then return name end
	end
end

-- Minimal callback registration so LibDBIcon can subscribe
function lib:RegisterCallback(event, func)
	self.callbacks[event] = self.callbacks[event] or {}
	table.insert(self.callbacks[event], func)
end
