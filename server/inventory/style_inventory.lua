local inv = function() return exports.style_inventory end

local function toId(src)
    local id = framezero.GetPlayerId(src)
    return tonumber(id)
end

framezero.RegisterAdapter("inventory", "style_inventory", {
    priority = 29,

    detect = function() return framezero.IsStarted("style_inventory") end,
    init = function() return true end,

    getItemCount = function(src, item)
        local id = toId(src)
        if not id then return 0 end
        local ok, amount = pcall(function()
            return inv():getInventoryItemAmount(id, item)
        end)
        return (ok and tonumber(amount)) or 0
    end,

    canCarry = function(src, item, amount)
        local id = toId(src)
        if not id then return false end
        local ok, can = pcall(function()
            local weight = (inv():getItemWeight(item) or 0) * (tonumber(amount) or 1)
            local current = inv():getCharacterInventoryCurrentWeight(id) or 0
            local maxW = inv():getCharacterInventoryMaxWeight(id) or 0
            return (current + weight) <= maxW
        end)
        return (ok and can) or false
    end,

    addItem = function(src, item, amount, metadata)
        local id = toId(src)
        if not id then return false end
        local ok, res = pcall(function()
            return inv():addInventoryItem(id, item, tonumber(amount) or 1, nil, nil, metadata)
        end)
        return ok and res ~= false
    end,

    removeItem = function(src, item, amount)
        local id = toId(src)
        if not id then return false end
        local ok, res = pcall(function()
            return inv():removeInventoryItem(id, item, tonumber(amount) or 1)
        end)
        return ok and res ~= false
    end,

    getInventory = function(src)
        local id = toId(src)
        if not id then return {} end
        local ok, raw = pcall(function()
            return inv():getCharacterInventory(id)
        end)
        if not ok or type(raw) ~= "table" then return {} end

        local list = {}
        for slot, it in pairs(raw) do
            if type(it) == "table" and it.i then
                list[#list + 1] = {
                    name = it.i,
                    label = inv():getItemName(it.i) or it.i,
                    amount = tonumber(it.a) or 1,
                    slot = tonumber(slot),
                    metadata = it.md,
                    weight = inv():getItemWeight(it.i) or 0,
                }
            end
        end
        return list
    end,

    getItemLabel = function(item)
        local ok, label = pcall(function() return inv():getItemName(item) end)
        return (ok and label and label ~= "?") and label or item
    end,

    getItemWeight = function(item)
        local ok, w = pcall(function() return inv():getItemWeight(item) end)
        return (ok and tonumber(w)) or 0
    end,
})
