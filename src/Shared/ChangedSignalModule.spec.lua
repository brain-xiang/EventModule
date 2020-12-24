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
    end)

    describe("mutated Event", function()
        itFOCUS("should fire connected mutated events upon mutation", function()
            local Table = ChangedSignalModule.new({a = 1, b = {}})
            local callCount = 0

            local callback = function(keyChanged, oldTable, newTable)
                expect(keyChanged).never.to.equal(nil)
                expect(oldTable).never.to.equal(nil)
                expect(newTable).never.to.equal(nil)
                callCount = callCount + 1
            end

            Table.mutated:Connect(callback)
            Table.a = 2
            expect(callCount).to.equal(1)

            -- Table.c = 3
            -- expect(callCount).to.equal(2)
            
            -- print(Table)
            -- table.insert(Table.b, "String")
            -- expect(callCount).to.equal(3)
        end)
        
        it("should only fire when a property is changed", function()
            local Table = ChangedSignalModule.new({a = 1})
            local callCount = 0

            Table.mutated:Connect(function(keyChanged, oldTable, newTable)
                callCount = callCount + 1
            end)

            Table.a = 1
            wait(1)
            expect(callCount).to.equal(0)
        end)

        it("should pass an independant oldTable and self object as newTable", function()
            local Table = ChangedSignalModule.new()
            local callCount = 0

            Table.mutated:Connect(function(keyChanged, oldTable, newTable)
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
    end)
end