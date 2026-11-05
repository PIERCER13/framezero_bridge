-- snt-inventory & snt-inventory-pro (SNT Resources)
-- https://snt.gg/docs/resources/snt-inventory-pro

local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok and result ~= nil then return result end
    return fallback
end

local function snt()
    return exports["snt-inventory-pro"] or exports["snt-inventory"]
end

local function getSntName()
    return framezero.IsStarted("snt-inventory-pro") and "snt-inventory-pro" or "snt-inventory"
end

framezero.RegisterAdapter("inventory", "snt-inventory", {
    priority = 25,
    detect = function()
        return framezero.IsStarted("snt-inventory-pro") or framezero.IsStarted("snt-inventory") or GlobalState.SNT_INVENTORY_PRO ~= nil
    end,
    init = function() return true end,

    getItemCount = function(src, item)
        return tonumber(safe(function()
            local id = framezero.API.GetPlayerId(src) or src
            return snt():getItemAmount(tonumber(id) or id, item) or snt():getInventoryItemAmount(tonumber(id) or id, item)
        end, 0)) or 0
    end,

    canCarry = function(src, item, amount)
        return safe(function()
            local id = framezero.API.GetPlayerId(src) or src
            if snt().canReceiveItems then
                return snt():canReceiveItems(tonumber(id) or id, item, amount) == true
            end
            return true
        end, true) == true
    end,

    addItem = function(src, item, amount, metadata)
        return safe(function()
            local id = framezero.API.GetPlayerId(src) or src
            local ok = snt():addInventoryItem(tonumber(id) or id, item, amount, false, nil, metadata)
            return ok == true
        end, false) == true
    end,

    removeItem = function(src, item, amount)
        return safe(function()
            local id = framezero.API.GetPlayerId(src) or src
            local ok = snt():removeInventoryItem(tonumber(id) or id, item, amount, false)
            return ok == true
        end, false) == true
    end,

    getInventory = function(src)
        return safe(function()
            local id = framezero.API.GetPlayerId(src) or src
            local raw = snt():getInventory(tonumber(id) or id) or {}
            local list = {}
            for slot, it in pairs(raw) do
                if type(it) == "table" and it.item then
                    list[#list + 1] = {
                        name = it.item,
                        label = snt():getItemName(it.item) or it.item,
                        amount = tonumber(it.amount) or 1,
                        slot = it.slot or tonumber(slot),
                        metadata = it.metadatas or it.metadata,
                        weight = tonumber(snt():getItemWeight(it.item)) or 0,
                    }
                end
            end
            return list
        end, {})
    end,

    getItemLabel = function(item)
        return safe(function() return snt():getItemName(item) end, item) or item
    end,

    getItemWeight = function(item)
        return tonumber(safe(function() return snt():getItemWeight(item) end, 0)) or 0
    end,
})
