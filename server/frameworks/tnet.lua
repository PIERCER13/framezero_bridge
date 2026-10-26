-- framezero_bridge / server/frameworks/tnet.lua
-- Feito em cima da API pública da tnet (tnet_core + tnet_inventory).
-- Ainda não testado num servidor tnet: se algo não bater, ajuste em custom/server.lua.

local tNet

local function character(src)
    return tNet and tNet.GetCharacterByPlayerSrc(src)
end

-- Chama um método do personagem só se ele existir nesta versão da tnet
local function charCall(src, method, ...)
    local c = character(src)
    if c and type(c[method]) == "function" then return c[method](...) end
end

FZ.RegisterAdapter("framework", "tnet", {
    priority = 35,

    detect = function()
        return FZ.IsStarted("tnet_core")
    end,

    init = function()
        local ok, shared = pcall(function() return exports.tnet_core:getSharedObject() end)
        tNet = ok and shared or nil
        AddEventHandler("playerJoining", function() FZ.Internal.PlayerLoaded(source) end)
        AddEventHandler("playerDropped", function() FZ.Internal.PlayerUnloaded(source) end)
        return tNet ~= nil
    end,

    -- Jogador
    getId = function(src)
        local id = tNet.GetCharacterIdByPlayerSrc(src)
        return id and tostring(id) or nil
    end,

    getSource = function(id)
        return tNet.GetPlayerSrcByCharacterId(tonumber(id) or id)
    end,

    getPlayers = function()
        local list = {}
        for key, value in pairs(tNet.GetUsers() or {}) do
            local src = type(value) == "number" and value or (type(value) == "table" and value.source) or tonumber(key)
            if src then list[#list + 1] = src end
        end
        return list
    end,

    getName = function(src)
        local c = character(src)
        if not c then return nil end
        return FZ.Trim((c.name or "") .. " " .. (c.lastName or ""))
    end,

    hasPermission = function(src, permission)
        if IsPlayerAceAllowed(src, permission) then return true end
        return charCall(src, "getRoleIdByGroupName", permission) ~= nil
    end,

    -- Dinheiro
    getMoney = function(src, acc)
        if acc == "bank" then return tonumber(charCall(src, "getBankMoney")) or 0 end
        return tonumber(charCall(src, "getMoney")) or 0
    end,

    addMoney = function(src, amount, acc)
        return charCall(src, "addBankMoney", amount, acc == "bank" and "bank" or "cash") ~= false
    end,

    removeMoney = function(src, amount)
        return charCall(src, "tryFullPayment", amount) == true
    end,

    -- Interface
    notify = function(src, kind, message, duration)
        TriggerClientEvent("Notify", src, kind, message, math.floor((duration or 5000) / 1000))
    end,

    revive = function(src)
        TriggerClientEvent("net.reviveCharacter", src)
    end,
})
