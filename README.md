<div align="center">

# 🎯 EventModule

### _Reactive State Management for Roblox Lua_

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Lua](https://img.shields.io/badge/Lua-5.1+-00007F.svg)](https://www.lua.org/)
[![Roblox](https://img.shields.io/badge/Roblox-Compatible-00A2FF.svg)](https://www.roblox.com/)

**Transform ordinary Lua tables into observable, reactive data structures with event-driven state management**

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [API Reference](#-api-reference) • [Examples](#-examples)

---

</div>

## ✨ Features

<table>
<tr>
<td width="50%">

### 🔔 **Reactive Properties**
Listen to changes on individual properties with `GetPropertyChangedSignal()`

### 🌊 **Mutation Tracking**
Track all changes to tables and nested tables with the `mutated` signal

### 🎭 **Signal System**
Built-in signal implementation for event-driven architecture

</td>
<td width="50%">

### 📦 **Array Operations**
Use `insert()` and `remove()` that trigger reactive events

### 🔍 **Table Utilities**
Enhanced `pairs()`, `ipairs()`, `len()`, and `find()` methods

### 🗑️ **Lifecycle Management**
Clean up connections with `Disconnect()`, `Destroy()`, and more

</td>
</tr>
</table>

---

## 📥 Installation

### Using Rojo
1. Clone this repository:
```bash
git clone https://github.com/brain-xiang/EventModule.git
```

2. Install dependencies:
```bash
# Install Rojo if you haven't already
npm install -g rojo
```

3. Build the project:
```bash
rojo build -o EventModule.rbxm
```

4. Import `EventModule.rbxm` into Roblox Studio

### Manual Installation
Copy the contents of the `src` folder into your Roblox project's `ReplicatedStorage`.

---

## 🚀 Quick Start

```lua
local EventModule = require(game.ReplicatedStorage.EventModule)

-- Create a reactive table
local playerData = EventModule.new({
    name = "Player1",
    score = 0,
    inventory = {}
})

-- Listen to specific property changes
playerData:GetPropertyChangedSignal("score"):Connect(function(oldValue, newValue)
    print(string.format("Score changed from %d to %d!", oldValue, newValue))
end)

-- Listen to any mutation
playerData.mutated:Connect(function(oldTable, newTable)
    print("PlayerData was updated!")
end)

-- Update the score (triggers events!)
playerData.score = 100
-- Output: "Score changed from 0 to 100!"
-- Output: "PlayerData was updated!"
```

---

## 📖 API Reference

### Constructor

#### `EventModule.new(table) → EventModule`
Creates a new reactive table from an existing table.

```lua
local data = EventModule.new({
    health = 100,
    mana = 50
})
```

---

### Properties

#### `.Parent`
Reference to the parent table (for nested tables).

```lua
local parent = EventModule.new({ child = {} })
print(parent.child.Parent == parent) -- true
```

#### `.mutated`
Signal that fires when the table or any descendant is mutated.

```lua
data.mutated:Connect(function(oldTable, newTable)
    -- oldTable: snapshot before mutation
    -- newTable: current state after mutation
end)
```

---

### Methods

#### `:GetPropertyChangedSignal(propertyName) → Signal`
Returns a signal for a specific property.

```lua
data:GetPropertyChangedSignal("health"):Connect(function(oldVal, newVal)
    print("Health: " .. oldVal .. " → " .. newVal)
end)

data.health = 75 -- Triggers the signal
```

#### `:GetProperties() → table`
Returns a raw table copy of all properties.

```lua
local props = data:GetProperties()
print(props.health) -- 100
```

#### `:pairs() → iterator`
Iterate over key-value pairs (replaces standard `pairs()`).

```lua
for key, value in data:pairs() do
    print(key, value)
end
```

#### `:ipairs() → iterator`
Iterate over array elements (replaces standard `ipairs()`).

```lua
local list = EventModule.new({1, 2, 3})
for i, v in list:ipairs() do
    print(i, v)
end
```

#### `:len() → number`
Get table length (replaces `#` operator).

```lua
local list = EventModule.new({1, 2, 3})
print(list:len()) -- 3
```

#### `:insert(value, pos?)`
Insert a value into the table (triggers events).

```lua
local list = EventModule.new({1, 2, 3})
list:insert(4) -- Appends to end
list:insert(0, 1) -- Inserts at position 1
```

#### `:remove(pos) → any`
Remove and return a value (triggers events).

```lua
local list = EventModule.new({1, 2, 3})
local removed = list:remove(2) -- Removes index 2
print(removed) -- 2
```

#### `:find(value, init?) → number?`
Find the index of a value.

```lua
local list = EventModule.new({"a", "b", "c"})
print(list:find("b")) -- 2
```

#### `:Disconnect()`
Disconnect all signals on this table.

#### `:DisconnectDescendants()`
Disconnect all signals on descendant tables.

#### `:DisconnectAllParents()`
Disconnect all signals up the parent chain.

#### `:Destroy()`
Completely clean up the table and all connections.

```lua
data:Destroy()
```

---

## 💡 Examples

### Nested Reactive Tables

```lua
local gameState = EventModule.new({
    player = {
        stats = {
            health = 100,
            stamina = 50
        }
    }
})

-- Track changes in nested tables
gameState.player.stats.mutated:Connect(function(old, new)
    print("Player stats changed!")
end)

gameState.player.stats.health = 80 -- Triggers signal
```

### Shopping Cart System

```lua
local cart = EventModule.new({
    items = {},
    total = 0
})

cart:GetPropertyChangedSignal("total"):Connect(function(oldPrice, newPrice)
    print(string.format("Cart total: $%.2f → $%.2f", oldPrice, newPrice))
end)

cart.items:insert({ name = "Sword", price = 50 })
cart.total = 50
```

### Game Settings Observer

```lua
local settings = EventModule.new({
    graphics = "High",
    volume = 0.8,
    controls = "WASD"
})

settings.mutated:Connect(function()
    -- Save settings whenever they change
    saveSettingsToDataStore(settings:GetProperties())
end)

settings.volume = 0.5 -- Auto-saves!
```

---

## 🏗️ Project Structure

```
EventModule/
├── src/
│   ├── EventModule.lua       # Main module
│   ├── EventModule.spec.lua  # Unit tests
│   ├── Signal.lua            # Signal implementation
│   ├── TableUtil.lua         # Table utilities
│   └── Test.lua              # Test runner
├── modules/
│   └── TestEZ/               # Testing framework
├── default.project.json      # Rojo project file
└── LICENSE
```

---

## 🧪 Testing

This project uses [TestEZ](https://github.com/Roblox/testez) for unit testing.

```bash
# Run tests with Rojo
rojo serve
```

Then run the tests in Roblox Studio using the Test.lua script.

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 🌟 Acknowledgments

- Created by **Legenderox** (December 21, 2020)
- Maintained by **brain-xiang**
- Built for the Roblox development community

---

<div align="center">

**If you find this project useful, please consider giving it a ⭐!**

Made with ❤️ for the Roblox community

</div>
