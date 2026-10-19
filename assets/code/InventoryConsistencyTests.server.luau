local Players = game:GetService("Players")
local Inventory = require(script.Parent.InventoryService)

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
assert(Inventory.Open(player, { Potion = 5, Crystal = 15 }))
local initial = Inventory.Snapshot(player)
assert(initial.Version == 0)
local success, version = Inventory.Transact(player, {
    { Id = "Potion", Amount = -2 },
    { Id = "Crystal", Amount = 3 },
}, initial.Version, "purchase-001")
assert(success and version == 1)
assert(Inventory.GetCount(player, "Potion") == 3)
assert(Inventory.GetCount(player, "Crystal") == 18)
assert(Inventory.Transact(player, { { Id = "Potion", Amount = -2 }, { Id = "Crystal", Amount = 3 } }, 0, "purchase-001"))
assert(Inventory.GetCount(player, "Potion") == 3)
assert(not Inventory.Transact(player, { { Id = "Potion", Amount = -3 } }, 1, "purchase-001"))
assert(not Inventory.Transact(player, { { Id = "Potion", Amount = -4 } }, 1))
assert(Inventory.Snapshot(player).Version == 1)
assert(Inventory.Snapshot(player).Items.Potion == 3)
Inventory.Close(player)
print("Inventory consistency assertions finished in Studio")
