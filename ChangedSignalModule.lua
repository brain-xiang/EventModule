-- Changed Module
-- Username
-- December 21, 2020



local ChangedModule = {}

function ChangedModule.new(tbl, signal)
    --[[
        input: 
    ]]

    local metaTable = {}
    local self = setmetatable(ChangedModule, metaTable)
    self.properties = tbl or {}
    self.events = {}

    print(self.properties)
    metaTable.__index = function(tableAccessed,key)
        if key:lower() == "changed" then
            self.events[tableAccessed] = Signal.new()
            return self.events[tableAccessed]
        end

        return self.properties[key]
    end
    
    metaTable.__newindex = function(tableAccessed,key,value)
        self.properties[key] = value
        if self.events[tableAccessed] then
            self.events[tableAccessed]:Fire(key, value)
        end
    end

	return self
end

function ChangedModule:Init()
    Signal = self.Shared.Signal
    TableUtil = self.Shared.TableUtil
end

return ChangedModule