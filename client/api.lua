-- local framezero = exports.framezero_bridge:GetFramezero()
-- if framezero.Progress("Fabricando munição", 5000) then ... end
--
-- Toda função pode ser trocada em custom/client.lua:
-- framezero.Custom.Notify = function(kind, message, duration) ... end

local API = {}

local function useOxLib(setting)
    return setting == "ox_lib" or (setting == "auto" and framezero.IsStarted("ox_lib"))
end


-- Interface
function API.Notify(kind, message, duration)
    framezero.Client.Notify(kind, message, duration)
end

-- Barra de progresso. Retorna true se completou.
-- opts: { canCancel = bool, disableControls = bool }
function API.Progress(label, duration, opts)
    opts = opts or {}
    if useOxLib(Config.Progress) then
        return exports.ox_lib:progressBar({
            label = label,
            duration = duration,
            canCancel = opts.canCancel == true,
            disable = { move = opts.disableMove == true, combat = opts.disableControls ~= false, car = opts.disableCar == true },
        }) == true
    end
    return framezero.UI.Progress(label, duration, opts)
end

function API.ShowText(text)
    if useOxLib(Config.Progress) then return exports.ox_lib:showTextUI(text) end
    framezero.UI.ShowText(text)
end

function API.HideText()
    if useOxLib(Config.Progress) then return exports.ox_lib:hideTextUI() end
    framezero.UI.HideText()
end


-- Target
-- options: lista de { label, icon?, distance?, onSelect = function(entity) end, canInteract? = function(entity) end }

-- Target próprio do servidor: defina framezero.CustomTarget em custom/client.lua
-- com addSphere(id, coords, radius, options), addModel(id, models, options) e remove(id).
local targetMode
local function target()
    if targetMode then return targetMode end
    local setting = Config.Target
    if setting == "auto" then
        setting = (framezero.CustomTarget and "custom")
            or (framezero.IsStarted("ox_target") and "ox_target")
            or (framezero.IsStarted("qb-target") and "qb-target")
            or "none"
    end
    if setting == "custom" and not framezero.CustomTarget then
        framezero.Log("error", "Config.Target = \"custom\", mas framezero.CustomTarget não foi definido em custom/client.lua.")
        setting = "none"
    end
    targetMode = setting
    return targetMode
end

local function toOx(id, options)
    local list = {}
    for i, opt in ipairs(options) do
        list[i] = {
            name = ("%s:%d"):format(id, i),
            label = opt.label,
            icon = opt.icon,
            distance = opt.distance or 2.0,
            canInteract = opt.canInteract and function(entity) return opt.canInteract(entity) end or nil,
            onSelect = function(data) opt.onSelect(data and data.entity) end,
        }
    end
    return list
end

local function toQb(options)
    local list = {}
    for i, opt in ipairs(options) do
        list[i] = {
            label = opt.label,
            icon = opt.icon,
            canInteract = opt.canInteract,
            action = function(entity) opt.onSelect(entity) end,
        }
    end
    return { options = list, distance = (options[1] and options[1].distance) or 2.0 }
end

local zones = {}      -- id → { kind, handle }
local fallback = {}   -- id → { coords, radius, options } (sem script de target)

function API.AddSphere(id, coords, radius, options)
    API.RemoveTarget(id)
    local mode = target()
    if mode == "custom" then
        framezero.CustomTarget.addSphere(id, coords, radius, options)
        zones[id] = { kind = "custom" }
    elseif mode == "ox_target" then
        zones[id] = { kind = "zone", handle = exports.ox_target:addSphereZone({ coords = coords, radius = radius, options = toOx(id, options) }) }
    elseif mode == "qb-target" then
        exports["qb-target"]:AddCircleZone(id, coords, radius, { name = id, useZ = true }, toQb(options))
        zones[id] = { kind = "qb-zone" }
    else
        fallback[id] = { coords = coords, radius = radius, options = options }
    end
end

function API.AddModel(id, models, options)
    API.RemoveTarget(id)
    local mode = target()
    if mode == "custom" then
        if not framezero.CustomTarget.addModel then return framezero.Log("warn", framezero.L("not_supported"), "AddModel", "custom target") end
        framezero.CustomTarget.addModel(id, models, options)
        zones[id] = { kind = "custom" }
    elseif mode == "ox_target" then
        exports.ox_target:addModel(models, toOx(id, options))
        zones[id] = { kind = "model", models = models, names = toOx(id, options) }
    elseif mode == "qb-target" then
        exports["qb-target"]:AddTargetModel(models, toQb(options))
        zones[id] = { kind = "qb-model", models = models, options = options }
    else
        framezero.Log("warn", framezero.L("not_supported"), "AddModel", "target: none")
    end
end

function API.RemoveTarget(id)
    local zone = zones[id]
    fallback[id] = nil
    if not zone then return end
    zones[id] = nil
    if zone.kind == "custom" then
        framezero.CustomTarget.remove(id)
    elseif zone.kind == "zone" then
        exports.ox_target:removeZone(zone.handle)
    elseif zone.kind == "qb-zone" then
        exports["qb-target"]:RemoveZone(id)
    elseif zone.kind == "model" then
        local names = {}
        for i, opt in ipairs(zone.names) do names[i] = opt.name end
        exports.ox_target:removeModel(zone.models, names)
    elseif zone.kind == "qb-model" then
        local labels = {}
        for i, opt in ipairs(zone.options) do labels[i] = opt.label end
        exports["qb-target"]:RemoveTargetModel(zone.models, labels)
    end
end

-- Sem ox_target/qb-target: texto na tela + tecla E na primeira opção disponível
CreateThread(function()
    local showing
    while true do
        local sleep = 750
        if next(fallback) then
            local pos = GetEntityCoords(PlayerPedId())
            local near
            for id, zone in pairs(fallback) do
                if #(pos - zone.coords) <= zone.radius then
                    for _, opt in ipairs(zone.options) do
                        if not opt.canInteract or opt.canInteract(nil) then near = { id = id, opt = opt } break end
                    end
                end
                if near then break end
            end
            if near then
                sleep = 0
                if showing ~= near.id then
                    showing = near.id
                    API.ShowText(("[E] %s"):format(near.opt.label))
                end
                if IsControlJustReleased(0, Config.Keys.Interact) then near.opt.onSelect(nil) end
            elseif showing then
                showing = nil
                API.HideText()
            end
        end
        Wait(sleep)
    end
end)


-- Callbacks e jogador
-- Chama um callback registrado no servidor com framezero.RegisterCallback
function API.TriggerCallback(name, timeoutMs, ...)
    return framezero.Callback.Await(name, timeoutMs, ...)
end

-- Responde a pedidos do servidor (framezero.AwaitClient). O handler recebe (respond, ...).
API.RegisterCallback = framezero.Callback.Register

function API.OnPlayerLoaded(cb)
    framezero.Client.loaded[#framezero.Client.loaded + 1] = cb
    if framezero.Client.isLoaded then CreateThread(cb) end
end

function API.IsLoaded()
    return framezero.Client.isLoaded
end

function API.Info()
    return framezero.Client.Info()
end

-- Minigames e Hacking
API.Minigame = function(gameType, ...) return framezero.ExecuteMinigame(gameType, ...) end
API.StartHack = API.Minigame

-- Alerta Policial (Dispatch) e Trancas (Doorlock)
API.Dispatch = function(data) return framezero.ClientDispatch(data) end
API.SetDoorState = function(doorId, locked, options) return framezero.Doorlock.SetState(doorId, locked, options) end

-- Streaming & Assets
API.AwaitLoad = function(checkFn, errorMsg, timeoutMs) return framezero.AwaitLoad(checkFn, errorMsg, timeoutMs) end
API.LoadModel = function(model, timeoutMs) return framezero.LoadModel(model, timeoutMs) end
API.LoadAnim = function(dict, timeoutMs) return framezero.LoadAnim(dict, timeoutMs) end
API.LoadPtfx = function(asset, timeoutMs) return framezero.LoadPtfx(asset, timeoutMs) end
API.GetItemImage = function(item) return framezero.GetItemImage(item) end

-- Peds & NPCs
API.CreatePed = function(data) return framezero.CreatePed(data) end
API.CreatePedAtPoint = function(data) return framezero.CreatePedAtPoint(data) end

-- Jogador (Gênero)
API.GetGender = function()
    return GetEntityModel(PlayerPedId()) == GetHashKey("mp_f_freemode_01") and "Female" or "Male"
end

-- Fechar Inventário Ativo
function API.CloseInventory()
    if framezero.IsStarted("ox_inventory") and exports["ox_inventory"].closeInventory then
        exports["ox_inventory"]:closeInventory()
    elseif framezero.IsStarted("snt-inventory-pro") or framezero.IsStarted("snt-inventory") then
        TriggerEvent("snt-inventory:client:close")
    elseif framezero.IsStarted("qs-inventory") or framezero.IsStarted("qs-inventory-pro") then
        TriggerEvent("qs-inventory:client:closeInventory")
    elseif framezero.IsStarted("qb-inventory") then
        TriggerEvent("inventory:client:close")
    elseif framezero.IsStarted("codem-inventory") then
        TriggerEvent("codem-inventory:client:close")
    end
    if framezero.IsStarted("heyy_houses") then
        TriggerEvent("heyy_houses:closeUI")
    end
    SetNuiFocus(false, false)
end

RegisterNetEvent("framezero_bridge:client:closeInventory", function()
    API.CloseInventory()
end)

-- Anticheat (evita falsos positivos de teleporte, godmode, armas, invisibilidade)
API.Anticheat = framezero.Anticheat

-- Chaves de Veículos (Client)
API.GiveVehicleKeys = function(plate) return framezero.VehicleKeys and framezero.VehicleKeys.Give(plate) end
API.RemoveVehicleKeys = function(plate) return framezero.VehicleKeys and framezero.VehicleKeys.Remove(plate) end
API.HasVehicleKeys = function(plate) return framezero.VehicleKeys and framezero.VehicleKeys.Has(plate) end


-- Publicação
local Public = {}
for name, fn in pairs(API) do
    Public[name] = function(...)
        local custom = framezero.Custom[name]
        if custom then return custom(...) end
        return fn(...)
    end
end

exports("GetFramezero", function() return Public end)
exports("IsReady", function() return true end)
framezero.API = Public
framezero.Ready = true
