local qs = function() return exports["qs-inventory"] end
local items

local function itemData(name)
    items = items or qs():GetItemList() or {}
    return items[name]
end

framezero.RegisterAdapter("inventory", "qs-inventory", {
    priority = 20,

    detect = function() return framezero.IsStarted("qs-inventory") end,
    init = function() return true end,

    getItemCount = function(src, item)
        return qs():GetItemTotalAmount(src, item) or 0
    end,

    canCarry = function(src, item, amount)
        return qs():CanCarryItem(src, item, amount) == true
    end,

    addItem = function(src, item, amount, metadata)
        if not qs():CanCarryItem(src, item, amount) then return false end
        return qs():AddItem(src, item, amount, nil, metadata) == true
    end,

    removeItem = function(src, item, amount)
        return qs():RemoveItem(src, item, amount) == true
    end,

    getInventory = function(src)
        local list = {}
        for slot, it in pairs(qs():GetInventory(src) or {}) do
            if it and it.name then
                list[#list + 1] = {
                    name = it.name, label = it.label, amount = it.amount or it.count or 0,
                    slot = it.slot or slot, metadata = it.info, weight = it.weight,
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
