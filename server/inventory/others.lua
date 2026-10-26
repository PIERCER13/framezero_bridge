-- codem-inventory, core_inventory e ak47_inventory, pelas APIs públicas de cada um.
-- Ainda não testados: toda chamada passa por pcall e devolve um valor seguro se falhar.

local function safe(fn, fallback)
    local ok, result = pcall(fn)
    if ok and result ~= nil then return result end
    return fallback
end

local function normalize(items, amountKey)
    local list = {}
    for slot, it in pairs(items or {}) do
        if type(it) == "table" and it.name then
            list[#list + 1] = {
                name = it.name, label = it.label, amount = tonumber(it[amountKey] or it.amount or it.count) or 0,
                slot = it.slot or tonumber(slot), metadata = it.info or it.metadata,
            }
        end
    end
    return list
end


-- codem-inventory
local codem = function() return exports["codem-inventory"] end

framezero.RegisterAdapter("inventory", "codem-inventory", {
    priority = 22,
    detect = function() return framezero.IsStarted("codem-inventory") end,
    init = function() return true end,

    getItemCount = function(src, item) return tonumber(safe(function() return codem():GetItemsTotalAmount(src, item) end, 0)) or 0 end,
    canCarry = function() return true end,
    addItem = function(src, item, amount, metadata) return safe(function() return codem():AddItem(src, item, amount, nil, metadata) end, false) ~= false end,
    removeItem = function(src, item, amount) return safe(function() return codem():RemoveItem(src, item, amount) end, false) ~= false end,
    getInventory = function(src) return normalize(safe(function() return codem():GetInventory(nil, src) end, {}), "amount") end,
    getItemLabel = function(item)
        local list = safe(function() return codem():GetItemList() end, {})
        return list[item] and list[item].label or item
    end,
    getItemWeight = function(item)
        local list = safe(function() return codem():GetItemList() end, {})
        return list[item] and list[item].weight or 0
    end,
})


-- core_inventory
local core = function() return exports.core_inventory end
local function coreInv(src) return "content-" .. tostring(src) end

framezero.RegisterAdapter("inventory", "core_inventory", {
    priority = 21,
    detect = function() return framezero.IsStarted("core_inventory") end,
    init = function() return true end,

    getItemCount = function(src, item) return tonumber(safe(function() return core():getItemCount(coreInv(src), item) end, 0)) or 0 end,
    canCarry = function(src, item, amount) return safe(function() return core():canCarry(coreInv(src), item, amount) end, true) == true end,
    addItem = function(src, item, amount, metadata) return safe(function() return core():addItem(coreInv(src), item, amount, metadata) end, false) ~= false end,
    removeItem = function(src, item, amount) return safe(function() return core():removeItem(coreInv(src), item, amount) end, false) ~= false end,
    getInventory = function(src) return normalize(safe(function() return core():getInventory(coreInv(src)) end, {}), "count") end,
})


-- ak47_inventory
local ak = function() return exports["ak47_inventory"] end

framezero.RegisterAdapter("inventory", "ak47_inventory", {
    priority = 21,
    detect = function() return framezero.IsStarted("ak47_inventory") end,
    init = function() return true end,

    getItemCount = function(src, item) return tonumber(safe(function() return ak():GetAmount(src, item) end, 0)) or 0 end,
    canCarry = function(src, item, amount) return safe(function() return ak():CanCarryItem(src, item, amount) end, true) == true end,
    addItem = function(src, item, amount, metadata) return safe(function() return ak():AddItem(src, item, amount, nil, metadata) end, false) ~= false end,
    removeItem = function(src, item, amount) return safe(function() return ak():RemoveItem(src, item, amount) end, false) ~= false end,
    getInventory = function(src) return normalize(safe(function() return ak():GetInventoryItems(src) end, {}), "count") end,
})
