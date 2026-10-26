-- framezero_bridge / server/inventory/tnet_inventory.lua

local inv = function() return exports.tnet_inventory end
local items

local function itemData(name)
    items = items or inv():Items() or {}
    return items[name]
end

FZ.RegisterAdapter("inventory", "tnet_inventory", {
    priority = 25,

    detect = function() return FZ.IsStarted("tnet_inventory") end,
    init = function() return true end,

    getItemCount = function(src, item)
        local amount = inv():Search(src, "count", item)
        return tonumber(type(amount) == "table" and amount[1] or amount) or 0
    end,

    canCarry = function(src, item, amount)
        local data = inv():GetInventory(src)
        local each = itemData(item)
        if not data or not each then return true end
        return (data.weight or 0) + (each.weight or 0) * amount <= (data.maxWeight or math.huge)
    end,

    addItem = function(src, item, amount, metadata)
        return inv():AddItem(src, item, amount, metadata) ~= false
    end,

    removeItem = function(src, item, amount, metadata)
        return inv():RemoveItem(src, item, amount, metadata) ~= false
    end,

    getInventory = function(src)
        local list = {}
        for _, it in pairs(inv():GetInventoryItems(src) or {}) do
            if it and it.name then
                list[#list + 1] = { name = it.name, label = it.label, amount = it.count or it.amount or 0, slot = it.slot, metadata = it.metadata }
            end
        end
        return list
    end,

    getItemLabel = function(item)
        local data = itemData(item)
        return data and (data.label or data.name) or item
    end,

    getItemWeight = function(item)
        local data = itemData(item)
        return data and data.weight or 0
    end,
})
