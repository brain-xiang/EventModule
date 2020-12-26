-- Event Module
-- Legenderox
-- December 21, 2020

--[[

Injected Properties:

    self = EventModule.new(tbl)    
    self.Parent
    self.mutated
    self:GetPropertyChangedEvent(propertyName)
    self:pairs()
    self:ipairs()
    self:Disconnect()
    self:DisconnectDescendants()
    self:DisconnectAllParents(object)
    self:DisassembleObject()
    self:Destroy()

    Details:
        Parent:

            Table that contains self

            local tbl = EventModule.new({a = {}})
            a.Parent == tbl

        mutated:

            returns a signal thats fired when the table or any of it's descending nested tables are mutated/changed.

            self.mutated:Connect(function(oldTable, newTable) 
                oldTable = tbl, copy of the table before mutation
                newTable = self Object after change 
            end)

        GetPropertyChangedEvent:

            returns a signal thats fired when a value of that table with the specifiedKey is, 
            created, changed or deleted.

            self:GetPropertyChangedEvent(propertyName):Connect(function(oldVal, newVal)
                oldVal = property's old value
                newVal = property's new value
            end)

        pairs:
            
            Using roblox's pairs() function on the object will error so self:pairs() is a replacement for that,
            it returns what you would expect from pairs(self).

            self:pairs() == pairs(self) 

        ipairs:
            
            Using roblox's ipairs() function on the object will error so self:ipairs() is a replacement for that,
            it returns what you would expect from ipairs(self).

            self:ipairs() == ipairs(self) 

        Disconnect:

            Disconnects all of the objects events
            does not alter children's or parent's events

            self:Disconnect() -- All events previoustly created for self are no longer active

        DisconnectDescendants:
            
            Disconnects all events of the object's Descendants

            self:DisconnectDescendants() 
            -- all of self's events are still intact but all objects below self in the table hiarchy have had it's events Disconnected.

        DisconnectAllParents

            object provided have all their parents Events Disconnected
            if object not provided default to self

            self:DisconnectAllParents(object)
            -- all of self's events are still intact but all objects above self in the table hiarchy have had it's events Disconnected.

        DisassembleObject

            disassembles the object, removes all injected properties and returns the properties in a normal Table/dictionary

            local disassembledTable = self:DisassembleObject()
            print(disassembledTable) 
            -- > {properties}
            
        Destroy

            Alias for: Disconnect, DisconnectDescendants and DisassembleObject

            local event = self.mutated:Connect(function)
            local destroyedTable = self:Destroy()
            print(disassembledTable) 
            -- > {properties}
            print(event)
            -- > nil
--]]


local EventModule = {}

function EventModule.new(tbl, parent)
    --[[
        input: tbl, initial table to contruct object around, parent = not required* only used for construction of nested tables

        Linked List structures:

            self.events = {
                ["mutated"] = mutated signal,
                ["PropertyName"] = PropertyChangedSignal
            }

            self.properties = {
                [propertyName] = property,
                ["PropertyTableName"] = EventModule.new(tbl, self.events)
                ["Parent"]= parentObject*
            }
    ]]
    if tbl and typeof(tbl) ~= "table" then error("EventModule only accepts tables") return end
    if tbl and tbl.mutated then return end
    
    local metaTable = {}
    local self = setmetatable(TableUtil.Copy(EventModule), metaTable)
    self.properties = tbl or {}
    self.properties.Parent = parent
    self.events = {}

    metaTable.__index = function(tableAccessed,key)
        if type(key) == "string" and key:lower() == "mutated" then
            self.events.mutated = self.events.mutated and self.events.mutated or Signal.new()
            return self.events.mutated
        end


        return self.properties[key]
    end
    
    metaTable.__newindex = function(tableAccessed,key,value)
        if self.properties[key] ~= value and key ~= "Parent" and key ~= "properties" then
            
            -- Disconecting signals when object no longer indexed
            if typeof(self.properties[key]) == "table" then
                self.properties[key]:Disconnect()
                self.properties[key]:DisconnectDescendants()
            end

            -- Firing propertyChangedEvents
            if self.events[key] then
                self.events[key]:Fire(self.properties[key], value) -- oldVal, newVal
            end

            --Getting all mutation events events
            local function getMutationEvents(object, mutationEvents)
                --[[
                    input: object = EventModule object or self, mutationEvents = tbl, Not Required* where all events are stored before return
                    returns: mutationEvents = {
                        signal = {oldTable, newTable(aka. self object)}
                    }
                ]]

                object = object or self
                mutationEvents = mutationEvents or {}

                -- storing event and it's args into mutationEvents tbl
                if object.events.mutated then
                    local oldTable = TableUtil.SafeCopy(object)
                    oldTable = oldTable:DisassembleObject()
                    mutationEvents[object.events.mutated] = {oldTable, object}
                end

                if object.Parent then
                    getMutationEvents(object.Parent, mutationEvents)
                end

                return mutationEvents
            end
            local mutationEvents = getMutationEvents()

            -- Uppdateing table values, creates new object if value is a table
            self.properties[key] = typeof(value) == "table" and self.new(value, self) or value

            -- Firing mutationEvents
            for signal, args in pairs(mutationEvents) do
                signal:Fire(args[1], args[2]) -- oldTable, newObject
            end
        end
    end

    -- Creating Objects for nested Tables
    for i,v in pairs(self.properties) do
        if typeof(v) == "table" and i ~= "Parent" then
            self.properties[i] = self.new(v, self)
        end
    end

	return self
end

function EventModule:GetPropertyChangedEvent(Key)
    --[[
        input: string, name of the property the event is connected to
        returns: signal
    ]]
    self.events[Key] = self.events[Key] and self.events[Key] or Signal.new()
    return self.events[Key]
end

function EventModule:pairs()
    return pairs(self.properties)
end

function EventModule:ipairs()
    return ipairs(self.properties)
end

function EventModule:Disconnect(events)
    --[[
        input: events = tbl or self.events
        Disconnects all of this objects events
        does not touch children or parents events
    ]]

     events = events or self.events
     for i,signal in pairs(events) do
        events[i] = nil
        signal:Destroy()
     end
end

function EventModule:DisconnectDescendants()
    --[[
        Disconnects all events of the object's Descendants
    ]]

     for i,v in pairs(self.properties) do
        if typeof(v) == "table" and i ~= "Parent" then
            v:Disconnect()
            v:DisconnectDescendants()
        end
     end
end

function EventModule:DisconnectAllParents(object)
    --[[
        input: object = EventModule object or self 
        Disconnects all of this objects parent Events
    ]]

    object = object or self
    if object.Parent then
        self:Disconnect(object.Parent.events)
        self:DisconnectAllParents(object.Parent)
    end
end

function EventModule:DisassembleObject()
    --[[
        input: object = EventModule object or self 
        Returns: disassembles object into normal tbl
    ]]
    for i,v in pairs(self.properties) do
        if typeof(v) == "table" and i ~= "Parent" then
            self.properties[i] = v:DisassembleObject()
        elseif i == "Parent" then
            self.properties[i] = nil
        end
    end

    return self.properties
end

function EventModule:Destroy()
    --[[
        input: object = EventModule object or self 
        Returns: object and it's descendants converted to normal table, and disconnects all connections
    ]]

    self:Disconnect()
    self:DisconnectDescendants()
    return self:DisassembleObject()
end


function EventModule:Init()
    Signal = self.Shared.Signal
    TableUtil = self.Shared.TableUtil
end

return EventModule