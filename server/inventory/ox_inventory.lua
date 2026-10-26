-- framezero_bridge / server/inventory/ox_inventory.lua

local ox = function() return exports.ox_inventory end
local items

local function itemData(name)
    items = items or ox():Items() or {}
    return items[name]
end

FZ.RegisterAdapter("inventory", "ox_inventory", {
    priority = 30,

    detect = function() return FZ.IsStarted("ox_inventory") end,
    init = function() return true end,

    getItemCount = function(src, item, metadata)
        return ox():GetItemCount(src, item, metadata) or 0
    end,

    canCarry = function(src, item, amount, metadata)
        return ox():CanCarryItem(src, item, amount, metadata) == true
    end,

    addItem = function(src, item, amount, metadata)
        if not ox():CanCarryItem(src, item, amount, metadata) then return false end
        local ok = ox():AddItem(src, item, amount, metadata)
        return ok == true or (type(ok) == "table" and ok[1] ~= nil)
    end,

    removeItem = function(src, item, amount, metadata)
        return ox():RemoveItem(src, item, amount, metadata) == true
    end,

    getInventory = function(src)
        local list = {}
        for _, it in pairs(ox():GetInventoryItems(src) or {}) do
            if it and it.name then
                list[#list + 1] = {
                    name = it.name, label = it.label, amount = it.count or 0,
                    slot = it.slot, metadata = it.metadata, weight = it.weight,
                }
            end
        end
        return list
    end,

    getItemLabel = function(item)
        local data = itemData(item)
        return data and data.label or item
    end,

    getItemWeight = function(item)
        local data = itemData(item)
        return data and data.weight or 0
    end,
})
