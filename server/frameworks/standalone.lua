-- Usado quando nenhum framework é encontrado. Identifica o jogador
-- pela license da Rockstar; o resto fica para o custom/server.lua.

FZ.RegisterAdapter("framework", "standalone", {
    priority = -1,

    detect = function() return true end,
    init = function()
        AddEventHandler("playerJoining", function() FZ.Internal.PlayerLoaded(source) end)
        AddEventHandler("playerDropped", function() FZ.Internal.PlayerUnloaded(source) end)
        return true
    end,

    getId = function(src)
        return GetPlayerIdentifierByType(src, "license")
    end,

    getSource = function(id)
        for _, src in ipairs(GetPlayers()) do
            if GetPlayerIdentifierByType(src, "license") == id then return tonumber(src) end
        end
    end,

    getPlayers = function()
        local list = {}
        for _, src in ipairs(GetPlayers()) do list[#list + 1] = tonumber(src) end
        return list
    end,

    getName = function(src)
        return GetPlayerName(src)
    end,

    hasPermission = function(src, permission)
        return IsPlayerAceAllowed(src, permission)
    end,

    notify = function(src, kind, message, duration)
        TriggerClientEvent(FZ.Resource .. ":notify", src, kind, message, duration)
    end,
})
