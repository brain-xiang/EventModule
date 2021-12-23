EventModule = require(EventModule)

local t = EventModule.new({
    a = 1,
    b = {
        a = 1
    },
})

t.mutated:Connect(function(old, new)

)

t:GetPropertyChangedSignal("a"):Connect(function(old, new)
    if old < new then

    end
end)

local TweenService = game:GetService("Tween")