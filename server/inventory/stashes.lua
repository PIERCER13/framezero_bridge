-- Gerenciamento de Baús / Stashes Compartilhados no Servidor
-- Suporta ox_inventory, qs-inventory, snt-inventory e qb-inventory.

framezero = framezero or {}
framezero.Stashes = framezero.Stashes or {}

local function safe(fn, fallback)
    local ok, res = pcall(fn)
    if ok and res ~= nil then return res end
    return fallback
end

function framezero.Stashes.Register(id, label, slots, weight, groups, coords)
    if not id or id == "" then return false end
    slots = tonumber(slots) or 50
    weight = tonumber(weight) or 100000

    -- 1. ox_inventory
    if framezero.IsStarted("ox_inventory") and exports.ox_inventory and exports.ox_inventory.RegisterStash then
        safe(function()
            exports.ox_inventory:RegisterStash(id, label or id, slots, weight, nil, groups, coords)
        end)
        return true
    end

    -- 2. qs-inventory
    if framezero.IsStarted("qs-inventory") or framezero.IsStarted("qs-inventory-pro") then
        local res = framezero.IsStarted("qs-inventory-pro") and "qs-inventory-pro" or "qs-inventory"
        if exports[res] and exports[res].RegisterStash then
            safe(function() exports[res]:RegisterStash(id, label or id, slots, weight) end)
            return true
        end
    end

    -- 3. snt-inventory
    if framezero.IsStarted("snt-inventory-pro") or framezero.IsStarted("snt-inventory") then
        local snt = exports["snt-inventory-pro"] or exports["snt-inventory"]
        if snt and snt.registerChest then
            safe(function() snt:registerChest(id, { name = label or id, slots = slots, weight = weight }) end)
            return true
        end
    end

    return true
end

function framezero.Stashes.Count(id, item)
    if not id or not item then return 0 end

    if framezero.IsStarted("ox_inventory") and exports.ox_inventory and exports.ox_inventory.Search then
        return tonumber(safe(function() return exports.ox_inventory:Search(id, "count", item) end, 0)) or 0
    end

    return 0
end

function framezero.Stashes.Add(id, item, count)
    count = framezero.PositiveInt(count) or 1
    if not id or not item then return false end

    if framezero.IsStarted("ox_inventory") and exports.ox_inventory and exports.ox_inventory.AddItem then
        return safe(function() return exports.ox_inventory:AddItem(id, item, count) == true end, false)
    end

    return false
end

function framezero.Stashes.Remove(id, item, count)
    count = framezero.PositiveInt(count) or 1
    if not id or not item then return false end

    if framezero.IsStarted("ox_inventory") and exports.ox_inventory and exports.ox_inventory.RemoveItem then
        return safe(function() return exports.ox_inventory:RemoveItem(id, item, count) == true end, false)
    end

    return false
end
