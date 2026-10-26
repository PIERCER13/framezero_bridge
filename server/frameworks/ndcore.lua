-- framezero_bridge / server/frameworks/ndcore.lua (ND_Core)
-- Feito pela API pública do ND_Core. Ainda não testado num servidor ND.

local function player(src)
    return exports["ND_Core"]:getPlayer(src)
end

FZ.RegisterAdapter("framework", "ndcore", {
    priority = 32,

    detect = function() return FZ.IsStarted("ND_Core") end,

    init = function()
        AddEventHandler("ND:characterLoaded", function(character) if character then FZ.Internal.PlayerLoaded(character.source) end end)
        AddEventHandler("ND:characterUnloaded", function(src) FZ.Internal.PlayerUnloaded(src) end)
        return true
    end,

    getId = function(src)
        local p = player(src)
        return p and tostring(p.id) or nil
    end,

    getSource = function(id)
        for _, p in pairs(exports["ND_Core"]:getPlayers() or {}) do
            if tostring(p.id) == tostring(id) then return p.source end
        end
    end,

    getPlayers = function()
        local list = {}
        for _, p in pairs(exports["ND_Core"]:getPlayers() or {}) do list[#list + 1] = p.source end
        return list
    end,

    getName = function(src)
        local p = player(src)
        return p and FZ.Trim((p.firstname or "") .. " " .. (p.lastname or "")) or nil
    end,

    hasPermission = function(src, permission)
        if IsPlayerAceAllowed(src, permission) then return true end
        local p = player(src)
        return p ~= nil and ((p.job == permission) or (p.groups ~= nil and p.groups[permission] ~= nil))
    end,

    getJob = function(src)
        local p = player(src)
        if not p or not p.job then return nil end
        local info = p.jobInfo or {}
        return { name = p.job, label = info.label or p.job, grade = info.rank or 0, gradeLabel = info.rankName, onDuty = true }
    end,

    getMoney = function(src, acc)
        local p = player(src)
        return p and tonumber(p[acc == "bank" and "bank" or "cash"]) or 0
    end,

    addMoney = function(src, amount, acc)
        local p = player(src)
        return p ~= nil and p.addMoney(acc == "bank" and "bank" or "cash", amount, "framezero") ~= false
    end,

    removeMoney = function(src, amount, acc)
        local p = player(src)
        if not p then return false end
        local key = acc == "bank" and "bank" or "cash"
        if (tonumber(p[key]) or 0) < amount then return false end
        return p.deductMoney(key, amount, "framezero") ~= false
    end,

    -- ND usa ox_inventory: os itens ficam com o adaptador do ox

    notify = function(src, kind, message, duration)
        TriggerClientEvent("ox_lib:notify", src, { description = message, type = kind == "info" and "inform" or kind, duration = duration })
    end,

    revive = function(src)
        local p = player(src)
        if p and p.revive then p.revive() end
    end,
})
