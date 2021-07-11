return function()
    local ChangedSignalModule = require(script.Parent.EventModule)

    describe("new", function()
        it("should construct from nothing", function()
            local Table = ChangedSignalModule.new()
            expect(Table).to.be.ok()
        end)

        it("should construct from something", function()
            local Table = ChangedSignalModule.new({a = 1})
            expect(Table.a).to.equal(1)
        end)

        it("should turn all newly assigned tables into objects", function()
            local Table = ChangedSignalModule.new()
            Table.a = {}
            expect(Table.a.mutated).never.to.equal(nil)
        end)

        it("Inserted EventModule Objects should work, Add .Parent if previoustly nil", function()
            local Table = ChangedSignalModule.new()
            local Table2 = ChangedSignalModule.new()
            Table3 = ChangedSignalModule.new({
                b = {}
            })
            
            Table.a = Table2
            expect(Table.a).to.equal(Table2)
            expect(Table2.Parent).to.equal(Table)

            Table.b = Table3.b 
            expect(Table.b).to.equal(Table3.b)
            expect(Table3.b.Parent).never.to.equal(Table)
        end)
    end)

    describe("mutated Event", function()
        it("should fire connected mutated events upon mutation", function()
            local Table = ChangedSignalModule.new({a = 1, b = {}})
            local callCount = 0

            local callback = function(oldTable, newTable)
                expect(oldTable).never.to.equal(nil)
                expect(newTable).never.to.equal(nil)
                callCount = callCount + 1
            end

            Table.mutated:Connect(callback)
            Table.a = 2
            expect(callCount).to.equal(1)

            Table.c = 3
            expect(callCount).to.equal(2)
            
            Table.b[1] = "HELLO"
            expect(callCount).to.equal(3)
        end)
        
        it("should only fire when a property is changed", function()
            local Table = ChangedSignalModule.new({a = 1})
            local callCount = 0

            Table.mutated:Connect(function(oldTable, newTable)
                callCount = callCount + 1
            end)

            Table.a = 1
            wait(1)
            expect(callCount).to.equal(0)
        end)

        it("should pass an independant oldTable and self object as newTable", function()
            local Table = ChangedSignalModule.new()
            local callCount = 0

            Table.mutated:Connect(function(oldTable, newTable)
                callCount = callCount + 1
                wait()
                newTable.a = 2
                wait()
                expect(newTable.a).to.equal(Table.a)
                expect(callCount).never.to.equal(1)
                expect(oldTable.a).never.to.equal(2)
            end)

            Table.a = 1 
        end)

        it("should be available on nested tables too", function()
            local Table = ChangedSignalModule.new({a = {}})
            local callCount = 0

            Table.a.mutated:Connect(function(oldTable, newTable)
                callCount = callCount + 1
            end)

            -- Should fire when mutated
            Table.a[1] = 1
            expect(callCount).to.equal(1)

            -- Should not fire when parent table mutates
            Table.b = 2
            expect(callCount).to.equal(1)
        end)

        it("newTable and oldTable should be from the hiarchy perspective of the listening Object", function()
            local Table = ChangedSignalModule.new({a = {1}})
            
            Table.mutated:Connect(function(oldTable, newTable)
                expect(newTable).to.equal(Table)
                expect(newTable.a[1]).to.equal(2)
                expect(oldTable.a[1]).to.equal(1)
            end)
            Table.a.mutated:Connect(function(oldTable, newTable)
                expect(newTable).to.equal(Table.a)
                expect(newTable[1]).to.equal(2)
                expect(oldTable[1]).to.equal(1)
            end)

            Table.a[1] = 2
        end)
    end)

    describe("Cleanup", function()
        it("self:Disconnect(), self:DisconnectDescendants(), self:DisconnectAllParents() should disconnect signals accordingly", function()
            local Table = ChangedSignalModule.new({
                a = {
                    b = {}
                }
            })
            local callCount = 0

            Table.mutated:Connect(function()
                callCount = callCount + 1
            end)
            Table.a.mutated:Connect(function()
                callCount = callCount + 1
            end)
            Table.a.b.mutated:Connect(function()
                callCount = callCount + 1
            end)

            -- self:DisconnectDescendants() should disconnnect all descendant object's events
            Table.a:DisconnectDescendants()
            Table.a.b[1] = true -- +2
            expect(callCount).to.equal(2)
            callCount = 0
            -- self:Disconnect() should disconnect all of the objects events
            Table.a:Disconnect()
            Table.a[1] = true -- +1
            expect(callCount).to.equal(1)
            callCount = 0

            -- self:DisconnectAllParents() should disconnnect all of the object's parants events
            Table.a:DisconnectAllParents()
            Table[1] = true -- +0
            expect(callCount).to.equal(0)
            callCount = 0
        end)

        it("self:Destroy() should disconnect all events, and return properties in normal table form", function()
            local Table = ChangedSignalModule.new({a = {}, b = 2})
            local callCount = 0
            Table.mutated:Connect(function()
                callCount = callCount + 1
            end)
            Table = Table:Destroy()

            -- should return table
            expect(Table).to.be.a("table")

            -- Values should remain
            expect(Table.b).to.equal(2)

            -- should no longer include object properties
            expect(Table.mutated).to.equal(nil)
            expect(Table.properties).to.equal(nil)
            expect(Table.events).to.equal(nil)

            -- Descendant tables should also no longer include object properties
            expect(Table.a.mutated).to.equal(nil)
            expect(Table.a.properties).to.equal(nil)
            expect(Table.a.events).to.equal(nil)
        end)

        it("should disconnect events and deschendantEvents when object is no longer indexed", function()
            local Table = ChangedSignalModule.new({
                a = {
                    b = {}
                }
            })
            local callCount = 0
            Table.a.mutated:Connect(function()
                callCount = callCount + 1
            end)
            Table.a.b.mutated:Connect(function()
                callCount = callCount + 1
            end)
            local ref = Table.a.b

            -- un-Indexing Table.a object
            Table.a = 1

            ref[1] = true
            expect(callCount).to.equal(0)
        end)
    end)

    describe("GetPropertyChangedSignal", function()
        it("should provide a signal that fires on a specific properties change, creation or removal", function()
            local Table = ChangedSignalModule.new({a = 1})
            local callCount = 0

            Table:GetPropertyChangedSignal("a"):Connect(function(oldVal, newVal)
                expect(oldVal).never.to.equal(newVal)
                callCount = callCount + 1
            end)
            Table:GetPropertyChangedSignal("b"):Connect(function()
                callCount = callCount + 1
            end)

            Table.a = 2
            expect(callCount).to.equal(1)
            Table.b = true
            expect(callCount).to.equal(2)
            Table.a = nil
            expect(callCount).to.equal(3)
        end)
            
    end)

    describe(":GetProperties()", function()
        it("should return raw table copy of the object's properties, accounting for nested tables too", function()
            local Table = ChangedSignalModule.new({1,2,3, a = {4,5,6}})
            local properties = Table:GetProperties()

            -- expect Raw tables
            expect(properties.mutated).to.equal(nil)
            expect(properties.a.mutated).to.equal(nil)

            -- properties stay the same
            expect(properties[1]).to.equal(Table[1])

            --Event nested once
            expect(properties.a[1]).to.equal(Table.a[1])
        end)
    end)

    describe("Looping", function()
        it("Object loopable with self:pairs() and self:ipairs()", function()
            local Table = ChangedSignalModule.new({1,2,3, a = {4,5,6}})
            local callCount = 0

            Table.a.Mutated:Connect(function()
                callCount = callCount + 1
            end)

            expect(function()
                --ipairs should loop numarically
                for i,v in Table:ipairs() do
                    expect(i).to.equal(v)
                end

                --loop should return nested tables as objects
                for i,v in Table:pairs() do
                    if typeof(v) == "table" then
                        -- Object values need to be available
                        expect(v[1]).to.equal(4)

                        --Parent Object exists
                        expect(v.Parent).to.equal(Table)

                        -- mutations fires event
                        v[1] = true
                        expect(callCount).to.equal(1)

                        --Parent object should not excist when looping through nested Tables
                        for k,t in Table.a:pairs() do
                            expect(k).never.to.equal("Parent")
                        end
                    end
                end
            end).never.to.throw()
        end)
    end)

    describe(":len()", function()
        it("should return the length of the table", function()
            local Table = ChangedSignalModule.new({1,2,3, a = {4,5}})
            expect(Table:len()).to.equal(3)
            expect(Table.a:len()).to.equal(2)
        end)
    end)

    describe(":insert()", function()
        it("should insert value at end of list if pos not passed", function()
            local Table = ChangedSignalModule.new({1,2,3})
            Table:insert(10)
            expect(Table[4]).to.equal(10)
        end)

        it("should push previous values uppward in array to clear space for specified insert position", function()
            local Table = ChangedSignalModule.new({1,3,4})
            Table:insert(2, 2)
            local expectedTable = {1,2,3,4}
        
            for i,v in Table:pairs() do
                expect(v).to.equal(expectedTable[i])
            end
        end)

        it("should only fire .mutated event once when value inserted into middle of array (not for every pushing action)", function()
            local t = ChangedSignalModule.new({"a", "c", "d"})
            local callCount = 0
            t.mutated:Connect(function(old, new)
                callCount += 1
            end)
            t:insert("b", 2)

            print(callCount, " INSERT CALLCOUNT")
            expect(callCount).to.equal(1)
        end)
    end)

    describe(":find()", function()
        it("should return index of value if found, with respect to init index", function()
            local Table = ChangedSignalModule.new({1,2,3,2,1})

            -- unspesified init
            expect(Table:find(2)).to.equal(2)

            -- specified init
            expect(Table:find(2, 4)).to.equal(4)
        end)
    end)

    describe(":remove()", function()
        it("should collapse values above the removed value down to fill the gap", function()
            local Table = ChangedSignalModule.new({1,2,2,3})
            Table:remove(2)
            local expectedTable = {1,2,3}
        
            for i,v in Table:pairs() do
                expect(v).to.equal(expectedTable[i])
            end
        end)
        it("should only fire .mutated event once when value removing val from middle of array (not for every filling action)", function()
            local t = ChangedSignalModule.new({"a", "b", "c", "d"})
            local callCount = 0
            t.mutated:Connect(function(old, new)
                callCount += 1
            end)
            t:remove(2)

            print(callCount, " REMOVE CALLCOUNT")
            expect(callCount).to.equal(1)
        end)
    end)
end