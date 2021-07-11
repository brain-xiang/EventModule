-- Event Module
-- Legenderox
-- December 21, 2020

--[[

Injected Properties:

    self = EventModule.new(tbl)    
    self.Parent
    self.mutated
    self:GetPropertyChangedSignal(propertyName)
    self:GetProperties()
    self:pairs()
    self:ipairs()
    self:len()
    self:insert(value, pos)
    self:remove(pos)
    self:find(value, init)
    self:Disconnect()
    self:DisconnectDescendants()
    self:DisconnectAllParents()
    self:Destroy()

    Details:
        Parent:

            Table that contains self's parent object

            local tbl = EventModule.new({a = {}})
            a.Parent == tbl

        mutated:

            returns a signal thats fired when the table or any of it's descending nested tables are mutated/changed.

            self.mutated:Connect(function(oldTable, newTable) 
                oldTable = tbl, copy of the table before mutation
                newTable = self Object after change 
            end)

        GetPropertyChangedSignal:

            returns a signal thats fired when a value of that table with the specifiedKey is, 
            created, changed or deleted.

            self:GetPropertyChangedSignal(propertyName):Connect(function(oldVal, newVal)
                oldVal = property's old value
                newVal = property's new value
            end)

        GetProperties:

            Returns: a raw table copy of the object's properties

            local properties = self:GetProperties()
            print(properties) 
            -- > {a copy of self's properties in raw table form}

        pairs:
            
            Using roblox's pairs() function on the object will error so self:pairs() is a replacement for that,
            it returns what you would expect from pairs(self).

            self:pairs() == pairs(self) 

        ipairs:
            
            Using roblox's ipairs() function on the object will error so self:ipairs() is a replacement for that,
            it returns what you would expect from ipairs(self).

            self:ipairs() == ipairs(self) 

        len:

            Using roblox's # length function on the object will error so self:len() is a replacement for that,
            it returns what you would expect from #self.

            self:len() -- > table length

        insert:

               Roblox's table.insert() function uses rawset and therefore does not trigger the mutation and property events,
               self:insert(value, pos) is an identical replacement that adresses this issue.
                    value = value that's inserted
                    pos = optional, number position in table where value will be inserted, defaults to #t+1

               self:insert("LastValue")
               print(self[self:len()]) -- > "LastValue"

               NOTE: will only fire .mutated once

        remove:

               Roblox's table.remove() function uses rawset and therefore does not trigger the mutation and property events,
               self:remove(pos) is an identical replacement that adresses this issue.
                    pos = Removes from at position pos, 
                          returning the value of the removed element. 
                          When pos is an integer between 1 and #t, 
                          it shifts down the elements t[pos+1], t[pos+2], …, t[#t] and erases element t[#t]. 
                          The index pos can also be 0 when #t is 0 or #t+1; 
                          in those cases, the function erases the element t[pos].
                
               self = {1,2,3}
               self:remove(2)
               print(self) -- > {1,3}

               NOTE: will only fire .mutated once

        find:

               Roblox's table.find() function does not work on self,
               self:find(value, init) is an identical replacement that adresses this issue.
                    value = linear search performed, returns first index that matches "value"
                    init = number pos where linear search starts

               self = {1,2,3,2,1}
               print(self:find(2)) -- > 2
               print(self:find(2, 4)) -- > 4

        Disconnect:

            Disconnects all of the objects events
            does not alter children's or parent's events

            self:Disconnect() -- All events previoustly created for self are no longer active

        DisconnectDescendants:
            
            Disconnects all events of the object's Descendants

            self:DisconnectDescendants() 
            -- all of self's events are still intact but all objects below self in the table hiarchy have had it's events Disconnected.

        DisconnectAllParents

            self has all their parents Events Disconnected

            self:DisconnectAllParents()
            -- all of self's events are still intact but all objects above self in the table hiarchy have had it's events Disconnected.

        Destroy:

            deletes object and all its events/connections
            returns: a raw table copy of the object's properties

            local event = self.mutated:Connect(function)
            local properties = self:Destroy()
            print(event)
            -- > nil
            print(self)
            -- > nil
            print(properties) 
            -- > {a copy of self's properties in raw table form}
            
--]]

local EventModule = {}
local Signal = require(script.Parent.Signal)
local TableUtil = require(script.Parent.TableUtil)

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
            }

            self.Parent = parentObject*
    ]]
    if tbl and typeof(tbl) ~= "table" then error("EventModule only accepts tables") return end
    if tbl and tbl.mutated then return end
    
    local metaTable = {}
    local self = setmetatable(TableUtil.Copy(EventModule), metaTable)
    self.properties = tbl or {}
    self.Parent = parent
    self.events = {}

    metaTable.__index = function(tableAccessed,key)
        if type(key) == "string" and key:lower() == "mutated" then
            self.events.mutated = self.events.mutated and self.events.mutated or Signal.new()
            return self.events.mutated
        end

        return self.properties[key]
    end
    
    metaTable.__newindex = function(tableAccessed,key,value)
        if key == "properties" or key == "events" then warn("Trying to change reserved indexes [EventModule Object]") return end  -- forbidden indexes
        if self.properties == value or self == value then warn("Trying to create cercular dependancies") return end
        if self.properties[key] == value then return end -- Duplicate value

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
                local oldTable = object:GetProperties()
                mutationEvents[object.events.mutated] = {oldTable, object}
            end

            if object.Parent then
                getMutationEvents(object.Parent, mutationEvents)
            end

            return mutationEvents
        end
        local mutationEvents = getMutationEvents()

        -- Disconecting signals when object no longer indexed
        if typeof(self.properties[key]) == "table" then
            self.properties[key]:Destroy()
        end

        -- Uppdateing table values 
        if typeof(value) == "table" and not value.mutated then -- creates new object if value is a raw table
            self.properties[key] = self.new(value, self)
        elseif typeof(value) == "table" and value.mutated then -- insert object and change parent if value is another EvetnModule Object  
            self.properties[key] = value
            if not value.Parent and key ~= "Parent" then
                value.Parent = self
            end
        else
            self.properties[key] = value
        end

        -- Firing mutationEvents
        for signal, args in pairs(mutationEvents) do
            signal:Fire(args[1], args[2]) -- oldTable, newObject
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

function EventModule:GetPropertyChangedSignal(Key)
    --[[
        input: string, name of the property the event is connected to
        returns: signal
    ]]
    self.events[Key] = self.events[Key] and self.events[Key] or Signal.new()
    return self.events[Key]
end

function EventModule:pairs()
    local shallowCopy = TableUtil.CopyShallow(self.properties)
    shallowCopy.Parent = nil
    return pairs(shallowCopy)
end

function EventModule:ipairs()
    local shallowCopy = TableUtil.CopyShallow(self.properties)
    shallowCopy.Parent = nil
    return ipairs(shallowCopy)
end

function EventModule:len()
    return #self.properties
end

function EventModule:insert(value, pos)
    if pos and type(pos) ~= "number" then error(":insert() position has to be a number") return end
    pos = pos or self:len() + 1
    if self[pos] then
        local prevValue = self[pos]
        self.properties[pos] = value
        self:insert(prevValue, pos + 1)
    else
        self[pos] = value
    end
end

function EventModule:find(value, init)
    if init and type(init) ~= "number" then error(":find(), init position has to be a number") return end
    init = init or 1

    for i = init, self:len() do
        if self[i] == value then 
            return i
        end
    end
    return nil
end

function EventModule:remove(pos)
    if not pos or type(pos) ~= "number" then error(":remove(pos), requires a number position") return end

    if self[pos+1] then
        self.properties[pos] = self[pos+1]
        self:remove(pos+1)
    else
        self[pos] = nil
    end
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

function EventModule:GetProperties()
    --[[
        Returns: a raw table copy of the object's properties
    ]]

    local copy = {}
    for i,v in pairs(self.properties) do
        if typeof(v) == "table" and i ~= "Parent" then
            copy[i] = v:GetProperties()
        elseif i ~= "Parent" then
            copy[i] = v
        end
    end

    return copy
end

function EventModule:Destroy()
    --[[
        deletes object and all its events/connections
        returns: a raw table copy of the object's properties
    ]]
    local properties = self:GetProperties()
    self:Disconnect()
    self:DisconnectDescendants()

    return properties
end

return EventModule