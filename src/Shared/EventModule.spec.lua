return function()
    while (not _G.Aero) do wait() end
    local aero = _G.Aero
    local ChangedSignalModule = aero.Shared.ChangedSignalModule

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

    describe("GetPropertyChangedEvent", function()
        it("should provide a signal that fires on a specific properties change, creation or removal", function()
            local Table = ChangedSignalModule.new({a = 1})
            local callCount = 0

            Table:GetPropertyChangedEvent("a"):Connect(function(oldVal, newVal)
                expect(oldVal).never.to.equal(newVal)
                callCount = callCount + 1
            end)
            Table:GetPropertyChangedEvent("b"):Connect(function()
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
end