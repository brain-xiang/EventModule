return function()
    while (not _G.Aero) do wait() end
    local aero = _G.Aero
    local TableUtil = aero.Shared.TableUtil

    describe("SafeCopyTable", function()
        it("should copy deep tables", function()
            local table = {1, 2, {3,4}}
            local copy = TableUtil.SafeCopy(table)

            -- Copied single values should stay the same
            expect(copy[1]).to.equal(table[1])

            -- Make copy of instead of refferencing nested tables
            expect(copy[3]).never.to.equal(table[3])

            -- Nested values should stay the same
            expect(copy[3][1]).to.equal(table[3][1])
        end)

        it("should copy tables with cyclic dependencies", function()
            local table = {}
            table[1] = table
            table[2] = {t = table}
            table[3] = 3
        
            -- table should have a cyclic dependency
            expect(table).to.equal(table[1])
            expect(function()
                copy = TableUtil.Copy(table)
            end).to.throw()

            expect(function()
                copy = TableUtil.SafeCopy(table)
            end).never.to.throw()

            -- Copied table should have same cyclic dependency as original
            expect(copy[1]).to.equal(copy)

            -- nested dependencies should also copy over
            expect(copy[2].t).to.equal(copy)

            -- copied cyclic dependencies should still read values as intended
            expect(copy[1][3]).to.equal(3)
        end)
    end)
end