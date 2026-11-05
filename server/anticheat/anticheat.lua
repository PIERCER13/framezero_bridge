-- Marca ações legítimas do servidor (teleportes, models, spawn de entidades) e oferece ban/kick seguro.

framezero = framezero or {}
framezero.Anticheat = framezero.Anticheat or {}

local ADAPTERS = {
    -- FeloxAC
    feloxac = {
        resource = "FeloxAC",
        teleport = function(ac, playerId) ac:markExternalTeleport(playerId) end,
        pedModel = function(ac, playerId, model) ac:registerLegalPedModel(playerId, model) end,
        entity = function(ac, entity, model) ac:MarkServerEntity(entity, model) end,
        weapon = function(ac, playerId, weaponHash, given)
            if given then
                ac:registerLegalWeapon(playerId, weaponHash)
            else
                ac:unregisterLegalWeapon(playerId, weaponHash)
            end
        end,
        heal = function(ac, playerId) ac:markExternalHeal(playerId) end,
        hasBypass = function(ac, playerId) return ac:hasBypass(playerId) end,
        ban = function(ac, playerId, reason, details, duration)
            return ac:banPlayer(playerId, reason, details, duration)
        end,
        kick = function(ac, playerId, reason, details)
            return ac:kickPlayer(playerId, reason, details)
        end,
    },
    -- FiveGuard (https://fiveguard.net/docs/)
    fiveguard = {
        resource = "fiveguard",
        teleport = function(fg, playerId)
            if fg.SetTempPermission then
                fg:SetTempPermission(playerId, "Client", "BypassTeleport", true, false)
                SetTimeout(5000, function() fg:SetTempPermission(playerId, "Client", "BypassTeleport", false, false) end)
            end
        end,
        pedModel = function(fg, playerId)
            if fg.SetTempPermission then
                fg:SetTempPermission(playerId, "Client", "BypassModelChange", true, false)
                SetTimeout(5000, function() fg:SetTempPermission(playerId, "Client", "BypassModelChange", false, false) end)
            end
        end,
        heal = function(fg, playerId)
            if fg.SetTempPermission then
                fg:SetTempPermission(playerId, "Client", "BypassHeal", true, false)
                SetTimeout(5000, function() fg:SetTempPermission(playerId, "Client", "BypassHeal", false, false) end)
            end
        end,
        hasBypass = function(fg, playerId)
            if fg.isStaff then return fg:isStaff(playerId) end
            if fg.hasBypass then return fg:hasBypass(playerId) end
            return false
        end,
        ban = function(fg, playerId, reason)
            if fg.banPlayer then return fg:banPlayer(playerId, reason) end
            return false
        end,
        kick = function(fg, playerId, reason)
            if fg.kickPlayer then return fg:kickPlayer(playerId, reason) end
            DropPlayer(tostring(playerId), reason or "Kicked by server")
            return true
        end,
        verifyToken = function(fg, playerId)
            if fg.VerifyToken then return fg:VerifyToken(playerId) end
            return true
        end,
        registerSafeEvent = function(fg, name, conf, cross)
            if fg.RegisterSafeEvent then return fg:RegisterSafeEvent(name, conf, cross) end
            return true
        end,
    }
}

local activeName, activeAdapter = nil, nil
local warned = {}

local function warnOnce(key, msg, ...)
    if warned[key] then return end
    warned[key] = true
    framezero.Log("warn", "anticheat: " .. msg, ...)
end

local function detect()
    local wanted = (Config.Anticheat or GetConvar("framezero_anticheat", "auto")):lower()
    if wanted == "none" or wanted == "off" or wanted == "false" then return nil, nil end

    if wanted ~= "auto" and not ADAPTERS[wanted] then
        warnOnce("unknown:" .. wanted, "Anticheat '%s' configurado não é suportado.", wanted)
        return nil, nil
    end

    for name, entry in pairs(ADAPTERS) do
        if (wanted == "auto" or wanted == name) and framezero.IsStarted(entry.resource) then
            return name, entry
        end
    end
    return nil, nil
end

local function refresh()
    activeName, activeAdapter = detect()
    if activeAdapter then
        framezero.Log("info", "Anticheat integrado no servidor: %s", activeName)
    end
end

local function call(action, ...)
    if not activeAdapter or not activeAdapter[action] then return false, nil end
    local ok, res = pcall(activeAdapter[action], exports[activeAdapter.resource], ...)
    if not ok then
        warnOnce(activeName .. ":" .. action, "Falha na chamada %s (%s): %s", activeName, action, tostring(res))
        return false, nil
    end
    return true, res
end

local AC = {}

function AC.GetName()
    return activeName
end

function AC.Teleport(playerId)
    call("teleport", tonumber(playerId))
end

function AC.PedModel(playerId, model)
    call("pedModel", tonumber(playerId), model)
end

function AC.Entity(entity, model)
    if not activeAdapter or not entity or entity == 0 then return end
    if model then
        call("entity", entity, model)
        return
    end
    CreateThread(function()
        local stopAt = GetGameTimer() + 2000
        while not DoesEntityExist(entity) and GetGameTimer() < stopAt do Wait(10) end
        if DoesEntityExist(entity) then
            call("entity", entity, GetEntityModel(entity))
        end
    end)
end

function AC.Weapon(playerId, weaponHash, given)
    call("weapon", tonumber(playerId), weaponHash, given ~= false)
end

function AC.Heal(playerId)
    call("heal", tonumber(playerId))
end

function AC.HasBypass(playerId)
    local ok, res = call("hasBypass", tonumber(playerId))
    return ok and res == true
end

function AC.Ban(playerId, reason, details, duration)
    local ok, res = call("ban", tonumber(playerId), reason, details, duration or -1)
    return ok and res ~= false
end

function AC.Kick(playerId, reason, details)
    local ok, res = call("kick", tonumber(playerId), reason, details)
    if ok and res ~= false then return true end
    DropPlayer(tostring(playerId), reason or "Desconectado")
    return true
end

function AC.VerifyToken(playerId)
    local ok, res = call("verifyToken", tonumber(playerId))
    return ok and res ~= false
end

function AC.RegisterSafeEvent(name, conf, cross)
    local ok, res = call("registerSafeEvent", name, conf, cross)
    return ok and res ~= false
end

framezero.Anticheat = AC

CreateThread(function()
    Wait(500)
    refresh()
end)

AddEventHandler("onResourceStart", function(res)
    for _, entry in pairs(ADAPTERS) do
        if entry.resource == res then refresh() return end
    end
end)

AddEventHandler("onResourceStop", function(res)
    if activeAdapter and activeAdapter.resource == res then
        activeName, activeAdapter = nil, nil
    end
end)
