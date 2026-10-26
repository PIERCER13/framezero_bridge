-- Feito pela API pública do ox_core. Ainda não testado; o ox_core muda bastante
-- entre versões, então confira com o seu e ajuste em custom/server.lua se precisar.

local function player(src)
    local ok, p = pcall(function() return exports.ox_core:GetPlayer(src) end)
    return ok and p or nil
end

framezero.RegisterAdapter("framework", "oxcore", {
    priority = 33,

    detect = function() return framezero.IsStarted("ox_core") end,

    init = function()
        AddEventHandler("ox:playerLoaded", function(src) framezero.Internal.PlayerLoaded(src) end)
        AddEventHandler("ox:playerLogout", function(src) framezero.Internal.PlayerUnloaded(src) end)
        return true
    end,

    getId = function(src)
        local p = player(src)
        return p and p.charId and tostring(p.charId) or nil
    end,

    getSource = function(id)
        local ok, p = pcall(function() return exports.ox_core:GetPlayerFromCharId(tonumber(id)) end)
        return ok and p and p.source or nil
    end,

    getPlayers = function()
        local list = {}
        local ok, players = pcall(function() return exports.ox_core:GetPlayers() end)
        for _, p in pairs(ok and players or {}) do list[#list + 1] = p.source end
        return list
    end,

    getName = function(src)
        local p = player(src)
        if not p then return nil end
        return framezero.Trim((p.get("firstName") or "") .. " " .. (p.get("lastName") or ""))
    end,

    hasPermission = function(src, permission)
        if IsPlayerAceAllowed(src, permission) then return true end
        local p = player(src)
        return p ~= nil and p.getGroup(permission) ~= nil
    end,

    -- Dinheiro em carteira = item "money" do ox_inventory
    getMoney = function(src, acc)
        if acc == "cash" then return exports.ox_inventory:GetItemCount(src, "money") or 0 end
        local p = player(src)
        local account = p and p.getAccount and p.getAccount()
        return account and account.get and account.get("balance") or 0
    end,

    addMoney = function(src, amount, acc)
        if acc == "cash" then return exports.ox_inventory:AddItem(src, "money", amount) == true end
        local p = player(src)
        local account = p and p.getAccount and p.getAccount()
        if not account then return false end
        local result = account.addBalance({ amount = amount, message = "framezero" })
        return result == nil or result == true or (type(result) == "table" and result.success ~= false)
    end,

    removeMoney = function(src, amount, acc)
        if acc == "cash" then return exports.ox_inventory:RemoveItem(src, "money", amount) == true end
        local p = player(src)
        local account = p and p.getAccount and p.getAccount()
        if not account then return false end
        local result = account.removeBalance({ amount = amount, message = "framezero" })
        return result == nil or result == true or (type(result) == "table" and result.success ~= false)
    end,

    notify = function(src, kind, message, duration)
        TriggerClientEvent("ox_lib:notify", src, { description = message, type = kind == "info" and "inform" or kind, duration = duration })
    end,
})
