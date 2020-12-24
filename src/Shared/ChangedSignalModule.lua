-- Changed Module
-- Username
-- December 21, 2020



local ChangedSignalModule = {}

function ChangedSignalModule.new(tbl, parentEvents)
    --[[
        input: tbl, initial table to contruct object around

        Linked List structures:
        self.events = {
            [AllNumericalIndex*] = mutated signal,
            ["PropertyName"] = PropertyChangedSignal
            ["Parent"]= {parent.events}
        }

        self.properties = {
            [propertyName] = property,
            ["PropertyTableName"] = ChangedSignalModule.new(tbl, self.events)
        }
    ]]
    
    local metaTable = {}
    local self = setmetatable(TableUtil.Copy(ChangedSignalModule), metaTable)
    self.properties = tbl or {}
    self.events = {
        Parent = parentEvents or nil
    }

    metaTable.__index = function(tableAccessed,key)
        if key:lower() == "mutated" then
            local Signal = Signal.new()
            table.insert(self.events, Signal)
            return Signal
        end

        return self.properties[key]
    end
    
    metaTable.__newindex = function(tableAccessed,key,value)
        if self.properties[key] ~= value then
            oldTable = TableUtil.Copy(self.properties)
            self.properties[key] = value

            --Firing mutated events
            local function fireAllMutatedEvents(eventsTable)
                --[[
                    input: eventsTable = linked list with self.events structure
                    Fires all .mutated events, including all parents events
                ]]
                for i,signal in pairs(eventsTable) do
                    if type(i) == "number" then
                        signal:Fire(key, oldTable, self) -- keyChanged, oldTable, newTable
                    end
                end
                
                if eventsTable.Parent then
                    fireAllMutatedEvents(eventsTable.Parent)
                end
            end
            fireAllMutatedEvents(self.events)
        end
    end

    -- Creating Objects for nested Tables
    for i,v in pairs(self.properties) do
        if typeof(v) == "table" then
            self.properties[i] = self.new(v, self.events)
        end
    end

    print(ChangedSignalModule)

	return self
end

function ChangedSignalModule:Init()
    Signal = self.Shared.Signal
    TableUtil = self.Shared.TableUtil
end

return ChangedSignalModule