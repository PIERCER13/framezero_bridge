-- Compatibilidade transparente com Anticheats no cliente
-- Evita falsos positivos / banimentos acidentais em ações comuns de scripts
-- (teleportes, invencibilidade temporária, invisibilidade, câmeras, armas e peds).

framezero = framezero or {}
framezero.Anticheat = framezero.Anticheat or {}

local ADAPTERS = {
    -- FeloxAC (https://feloxac.com/docs#exports)
    feloxac = {
        resource = "FeloxAC",
        teleport = function(ac) ac:markExternalTeleport() end,
        invincible = function(ac, on)
            ac:isInvincible(on)
            ac:canBeDamaged(not on)
        end,
        visible = function(ac, on) ac:isVisible(on) end,
        spectating = function(ac, on) ac:setSpectatorMode(on) end,
        pedModel = function(ac, model) ac:hasChangedPedModel(model) end,
        spawn = function(ac, kind, model)
            if kind == "vehicle" then
                ac:CreateVehicle(model)
            elseif kind == "object" then
                ac:CreateObject(model)
            else
                ac:CreatePed(model)
            end
        end,
        camera = function(ac, cam) ac:createCam(cam) end,
        cameraDestroyed = function(ac, cam) ac:destroyCam(cam) end,
        weapon = function(ac, weaponHash, given)
            if given then
                ac:giveWeapon(weaponHash, GetCurrentResourceName())
            else
                ac:removeWeapon(weaponHash)
            end
        end,
        heal = function(ac) ac:markExternalHeal() end,
        revive = function(ac) ac:playerRevived() end,
    },
    -- FiveGuard
    fiveguard = {
        resource = "fiveguard",
        teleport = function() TriggerEvent("fg:teleportAllowed") end,
        invincible = function(_, on) TriggerEvent("fg:godmodeAllowed", on) end,
        spawn = function(_, kind, model) TriggerEvent("fg:spawnAllowed", kind, model) end,
        camera = function() TriggerEvent("fg:camAllowed") end,
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

local function call(action, ...)
    if not activeAdapter or not activeAdapter[action] then return false end
    local ok, err = pcall(activeAdapter[action], exports[activeAdapter.resource], ...)
    if not ok then
        warnOnce(activeName .. ":" .. action, "Falha na chamada %s (%s): %s", activeName, action, tostring(err))
    end
    return ok
end

local held = {
    invincible = false,
    hidden = false,
    spectating = false,
    cameras = {},
}

local function reapply()
    if held.invincible then call("invincible", true) end
    if held.hidden then call("visible", false) end
    if held.spectating then call("spectating", true) end
    for cam in pairs(held.cameras) do call("camera", cam) end
end

local function refresh()
    local name, entry = detect()
    if name == activeName then return end
    activeName, activeAdapter = name, entry
    if activeAdapter then
        framezero.Log("info", "Anticheat detectado e integrado: %s", activeName)
        reapply()
    end
end

-- API Pública do Anticheat
local AC = {}

function AC.GetName()
    return activeName
end

function AC.Teleport()
    call("teleport")
end

function AC.SetInvincible(on)
    on = on == true
    if held.invincible == on then return end
    held.invincible = on
    call("invincible", on)
end

function AC.SetVisible(visible)
    local hidden = visible == false
    if held.hidden == hidden then return end
    held.hidden = hidden
    call("visible", not hidden)
end

function AC.SetSpectating(on)
    on = on == true
    if held.spectating == on then return end
    held.spectating = on
    call("spectating", on)
end

function AC.PedModel(model)
    call("pedModel", model)
end

function AC.Spawn(kind, model)
    call("spawn", kind, model)
end

function AC.Camera(cam)
    if not cam then return end
    held.cameras[cam] = true
    call("camera", cam)
end

function AC.CameraDestroyed(cam)
    if not cam or not held.cameras[cam] then return end
    held.cameras[cam] = nil
    call("cameraDestroyed", cam)
end

function AC.Weapon(weaponHash, given)
    call("weapon", weaponHash, given ~= false)
end

function AC.Heal()
    call("heal")
end

function AC.Revive()
    call("revive")
end

function AC.ReleaseAll()
    AC.SetInvincible(false)
    AC.SetVisible(true)
    AC.SetSpectating(false)
    for cam in pairs(held.cameras) do
        AC.CameraDestroyed(cam)
    end
end

--- Dispara um evento para o servidor protegido pelo token do FiveGuard (se ativo),
--- ou via TriggerServerEvent normal caso contrário.
function AC.ExecuteServerEvent(name, ...)
    if activeName == "fiveguard" and exports["fiveguard"] and exports["fiveguard"].ExecuteServerEvent then
        exports["fiveguard"]:ExecuteServerEvent(name, ...)
    else
        TriggerServerEvent(name, ...)
    end
end

framezero.Anticheat = AC

CreateThread(function()
    Wait(500)
    refresh()
end)

AddEventHandler("onClientResourceStart", function(res)
    if res == GetCurrentResourceName() then return end
    for _, entry in pairs(ADAPTERS) do
        if entry.resource == res then refresh() return end
    end
end)

AddEventHandler("onClientResourceStop", function(res)
    if res == GetCurrentResourceName() then
        AC.ReleaseAll()
        return
    end
    if activeAdapter and activeAdapter.resource == res then
        activeName, activeAdapter = nil, nil
    end
end)
