-- framezero_bridge / server/api.lua (API pública do servidor)
-- local Bridge = exports.framezero_bridge:GetBridge()
-- Bridge.AddItem(source, "agua", 2)
--
-- Toda função pode ser trocada em custom/server.lua:
-- FZ.Custom.GiveVehicle = function(target, model, opts) ... end

local API = {}
FZ.Internal = { loaded = {}, unloaded = {} }

local function framework() return FZ.Active.framework end

local function isOnline(src)
    src = tonumber(src)
    return src ~= nil and GetPlayerName(src) ~= nil
end

-- Item e conta de dinheiro sujo do framework atual (Config.DirtyMoney)
local function dirtyMoney()
    return Config.DirtyMoney[framework().name] or {}
end


-- Eventos de jogador
function FZ.Internal.PlayerLoaded(src)
    for _, cb in ipairs(FZ.Internal.loaded) do
        local ok, err = pcall(cb, src, API.GetPlayerId(src))
        if not ok then FZ.Log("error", "OnPlayerLoaded: %s", err) end
    end
end

function FZ.Internal.PlayerUnloaded(src)
    for _, cb in ipairs(FZ.Internal.unloaded) do
        local ok, err = pcall(cb, src)
        if not ok then FZ.Log("error", "OnPlayerUnloaded: %s", err) end
    end
end

function API.OnPlayerLoaded(cb)   FZ.Internal.loaded[#FZ.Internal.loaded + 1] = cb end
function API.OnPlayerUnloaded(cb) FZ.Internal.unloaded[#FZ.Internal.unloaded + 1] = cb end


-- Jogador
-- ID do personagem (identifier · citizenid · user_id/passaporte), sempre string
function API.GetPlayerId(src)
    if not isOnline(src) then return nil end
    local id = FZ.Call("framework", "getId", tonumber(src))
    return id and tostring(id) or nil
end

function API.GetSource(id)
    if id == nil then return nil end
    return FZ.Call("framework", "getSource", id)
end

-- Lista de sources online (mesmo formato em todos os frameworks)
function API.GetPlayers()
    return FZ.Call("framework", "getPlayers") or {}
end

function API.GetName(src)
    if not isOnline(src) then return nil end
    return FZ.Call("framework", "getName", tonumber(src)) or GetPlayerName(src)
end

-- Grupo, permissão, job ou ACE (o que o framework entender por permissão)
function API.HasPermission(src, permission)
    if not isOnline(src) or type(permission) ~= "string" then return false end
    return FZ.Call("framework", "hasPermission", tonumber(src), permission) == true
end

-- { name, label, grade, gradeLabel, onDuty } ou nil
function API.GetJob(src)
    if not isOnline(src) then return nil end
    return FZ.Call("framework", "getJob", tonumber(src))
end


-- Dinheiro
-- account: "cash" (padrão) · "bank" · "dirty"

function API.GetMoney(src, account)
    if not isOnline(src) then return 0 end
    account = account or "cash"
    if account == "dirty" and dirtyMoney().item then return API.GetItemCount(src, dirtyMoney().item) end
    return tonumber(FZ.Call("framework", "getMoney", tonumber(src), account)) or 0
end

function API.AddMoney(src, amount, account)
    amount = FZ.PositiveInt(amount)
    if not amount or not isOnline(src) then return false end
    account = account or "cash"
    if account == "dirty" and dirtyMoney().item then return API.AddItem(src, dirtyMoney().item, amount) end
    return FZ.Call("framework", "addMoney", tonumber(src), amount, account) == true
end

function API.RemoveMoney(src, amount, account)
    amount = FZ.PositiveInt(amount)
    if not amount or not isOnline(src) then return false end
    account = account or "cash"
    if account == "dirty" and dirtyMoney().item then return API.RemoveItem(src, dirtyMoney().item, amount) end
    return FZ.Call("framework", "removeMoney", tonumber(src), amount, account) == true
end


-- Itens
-- Usa o inventário detectado (ox, qs) ou o do próprio framework.

local function inv(method, ...)
    local adapter = FZ.Active.inventory
    if adapter and adapter[method] then return adapter[method](...) end
    return FZ.Call("framework", method, ...)
end

function API.GetItemCount(src, item, metadata)
    if not isOnline(src) or type(item) ~= "string" then return 0 end
    return tonumber(inv("getItemCount", tonumber(src), item, metadata)) or 0
end

function API.HasItem(src, item, amount, metadata)
    return API.GetItemCount(src, item, metadata) >= (FZ.PositiveInt(amount) or 1)
end

function API.CanCarry(src, item, amount, metadata)
    amount = FZ.PositiveInt(amount)
    if not amount or not isOnline(src) then return false end
    return inv("canCarry", tonumber(src), item, amount, metadata) ~= false
end

function API.AddItem(src, item, amount, metadata)
    amount = FZ.PositiveInt(amount)
    if not amount or not isOnline(src) or type(item) ~= "string" then return false end
    return inv("addItem", tonumber(src), item, amount, metadata) == true
end

function API.RemoveItem(src, item, amount, metadata)
    amount = FZ.PositiveInt(amount)
    if not amount or not isOnline(src) or type(item) ~= "string" then return false end
    return inv("removeItem", tonumber(src), item, amount, metadata) == true
end

-- Lista de { name, label, amount, slot?, metadata?, weight? }
function API.GetInventory(src)
    if not isOnline(src) then return {} end
    local list = inv("getInventory", tonumber(src)) or {}
    for _, it in ipairs(list) do it.label = it.label or API.GetItemLabel(it.name) end
    return list
end

function API.GetItemLabel(item)
    return inv("getItemLabel", item) or item
end

function API.GetItemWeight(item)
    return tonumber(inv("getItemWeight", item)) or 0
end


-- Veículos
local function vehicles(method, ...)
    local adapter = FZ.Active.vehicles
    if adapter and adapter[method] then return adapter[method](...) end
    return FZ.Call("framework", method, ...)
end

local PLATE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789"

function API.GeneratePlate()
    local prefix = Config.VehicleDefaults.PlatePrefix or ""
    local size = math.max(1, (Config.VehicleDefaults.PlateLength or 8) - #prefix)
    for _ = 1, 25 do
        local plate = prefix
        for _ = 1, size do
            local i = math.random(1, #PLATE_CHARS)
            plate = plate .. PLATE_CHARS:sub(i, i)
        end
        if not vehicles("plateExists", plate) then return plate end
    end
    return prefix .. tostring(os.time()):sub(-size)
end

-- target: source online OU id do personagem. Retorna a placa ou false.
-- opts: { plate?, garage?, type? }
function API.GiveVehicle(target, model, opts)
    if type(model) ~= "string" or model == "" then return false end
    opts = opts or {}
    local id = isOnline(target) and API.GetPlayerId(target) or (target and tostring(target))
    if not id then return false end
    local plate = opts.plate or API.GeneratePlate()
    local ok, finalPlate = vehicles("giveVehicle", id, model, plate, opts)
    return ok and (finalPlate or plate) or false
end

function API.HasVehicle(target, model)
    local id = isOnline(target) and API.GetPlayerId(target) or (target and tostring(target))
    if not id then return false end
    return vehicles("hasVehicle", id, model) == true
end


-- Interface
-- kind: success · error · warning · info (aceita sucesso/negado/aviso)
function API.Notify(src, kind, message, duration)
    if not isOnline(src) then return end
    kind, duration = FZ.NotifyType(kind), tonumber(duration) or 5000
    if FZ.Active.notify == "ox_lib" then
        TriggerClientEvent("ox_lib:notify", src, { description = message, type = kind == "info" and "inform" or kind, duration = duration })
    elseif FZ.Active.notify == "okokNotify" then
        TriggerClientEvent("okokNotify:Alert", src, "", message, duration, kind)
    elseif FZ.Active.notify == "mythic_notify" then
        TriggerClientEvent("mythic_notify:client:SendAlert", src, { type = kind == "warning" and "inform" or kind, text = message, length = duration })
    else
        FZ.Call("framework", "notify", tonumber(src), kind, tostring(message), duration)
    end
end

-- Caixa de texto na tela do jogador. Retorna o texto ou nil (cancelou).
function API.Prompt(src, title, placeholder)
    if not isOnline(src) then return nil end
    local text = FZ.Callback.AwaitClient(tonumber(src), "prompt", nil, title, placeholder or "")
    text = type(text) == "string" and FZ.Trim(text) or ""
    return text ~= "" and text or nil
end

-- Pergunta Sim/Não com teclas (Config.Keys). Retorna true/false.
function API.Request(src, message, timeoutSeconds)
    if not isOnline(src) then return false end
    local ms = (tonumber(timeoutSeconds) or 30) * 1000
    return FZ.Callback.AwaitClient(tonumber(src), "request", ms + 1000, message, ms) == true
end

function API.Revive(src, health)
    if not isOnline(src) then return end
    FZ.Call("framework", "revive", tonumber(src), health)
end


-- Callbacks e banco
API.RegisterCallback = FZ.Callback.Register
API.AwaitClient = FZ.Callback.AwaitClient
API.DB = FZ.DB

function API.Info()
    return {
        version = FZ.Version,
        framework = FZ.Active.framework and FZ.Active.framework.name,
        inventory = FZ.Active.inventory and FZ.Active.inventory.name or "framework",
        vehicles = FZ.Active.vehicles and FZ.Active.vehicles.name or "framework",
        notify = FZ.Active.notify,
        vrpFlavor = FZ.Active.framework and FZ.Active.framework.flavor and FZ.Active.framework.flavor() or nil,
        vrpFunctions = FZ.Active.framework and FZ.Active.framework.functions and FZ.Active.framework.functions() or nil,
    }
end


-- O cliente pergunta qual framework/variante está ativo (notificação, estilo vRP)
FZ.Callback.Register("info", function()
    while not FZ.Ready do Wait(100) end
    return API.Info()
end)


-- Publicação
-- Cada função pública consulta FZ.Custom primeiro.

local Public = {}
for name, fn in pairs(API) do
    if type(fn) == "function" then
        Public[name] = function(...)
            local custom = FZ.Custom[name]
            if custom then return custom(...) end
            return fn(...)
        end
    else
        Public[name] = fn
    end
end
FZ.API = Public

exports("GetBridge", function() return Public end)
exports("IsReady", function() return FZ.Ready end)


-- Inicialização
local FRAMEWORK_RESOURCES = { "qbx_core", "qb-core", "es_extended", "tnet_core", Config.Vrp.Resource }

local function selectAdapter(kind, forced, fallback)
    if forced == "framework" then return nil end
    local adapter = FZ.SelectAdapter(kind, forced)
    if adapter and adapter.init and not adapter.init() then
        FZ.Log("error", FZ.L("adapter_failed"), kind, adapter.name)
        return nil
    end
    if not adapter and fallback then FZ.Log("debug", FZ.L("adapter_none"), kind, fallback) end
    return adapter
end

local function checkUpdate()
    if not Config.UpdateCheck or Config.UpdateUrl == "" then return end
    PerformHttpRequest(Config.UpdateUrl, function(status, body)
        if status ~= 200 or not body then return end
        local ok, data = pcall(json.decode, body)
        if ok and data and data.version and data.version ~= FZ.Version then
            FZ.Log("warn", FZ.L("update_available"), data.version, FZ.Version)
        end
    end, "GET")
end

CreateThread(function()
    -- Dá tempo para o framework terminar de subir quando a ordem do server.cfg estiver errada
    for _ = 1, 50 do
        local starting = false
        for _, res in ipairs(FRAMEWORK_RESOURCES) do
            if GetResourceState(res) == "starting" then starting = true end
        end
        if not starting then break end
        Wait(200)
    end

    FZ.Active.framework = selectAdapter("framework", Config.Framework)
    if not FZ.Active.framework then
        FZ.Active.framework = FZ.Adapters.framework.standalone
        FZ.Active.framework.init()
    end
    FZ.Active.inventory = selectAdapter("inventory", Config.Inventory, "framework")
    FZ.Active.vehicles = selectAdapter("vehicles", Config.Vehicles, "framework")
    if Config.Notify ~= "auto" then
        FZ.Active.notify = Config.Notify
    elseif FZ.Active.framework.name ~= "vrp" and FZ.IsStarted("ox_lib") then
        FZ.Active.notify = "ox_lib"
    elseif FZ.IsStarted("okokNotify") then
        FZ.Active.notify = "okokNotify"
    elseif FZ.IsStarted("mythic_notify") then
        FZ.Active.notify = "mythic_notify"
    else
        FZ.Active.notify = "framework"
    end

    for _, res in ipairs(FRAMEWORK_RESOURCES) do
        if GetResourceState(res) == "stopped" then
            FZ.Log("warn", FZ.L("start_order"), res)
        end
    end

    FZ.Ready = true
    local info = API.Info()
    FZ.Banner({
        FZ.L("started", info.version, info.framework .. (info.vrpFlavor and (" · " .. info.vrpFlavor) or ""), info.inventory, info.vehicles, info.notify),
    })
    checkUpdate()
end)
