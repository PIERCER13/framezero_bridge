-- local framezero = exports.framezero_bridge:GetFramezero()
-- framezero.AddItem(source, "agua", 2)
--
-- Toda função pode ser trocada em custom/server.lua:
-- framezero.Custom.GiveVehicle = function(target, model, opts) ... end

local API = {}
framezero.Internal = { loaded = {}, unloaded = {} }

local function framework() return framezero.Active.framework end

local function isOnline(src)
    src = tonumber(src)
    return src ~= nil and GetPlayerName(src) ~= nil
end

-- Item e conta de dinheiro sujo do framework atual (Config.DirtyMoney)
local function dirtyMoney()
    return Config.DirtyMoney[framework().name] or {}
end


-- Eventos de jogador
-- Cada callback guarda o resource que o registrou. Se esse resource para ou reinicia,
-- o funcref fica "morto" e estouraria "Execution of function reference in script host
-- failed" a cada evento, pra sempre — então ele é removido (no onResourceStop e, por
-- segurança, na primeira vez que falha assim).
local function runCallbacks(list, label, ...)
    local dead
    for i = 1, #list do
        local ok, err = pcall(list[i].cb, ...)
        if not ok then
            local msg = tostring(err)
            if msg:find("script host failed", 1, true) or msg:find("function reference", 1, true) then
                dead = dead or {}
                dead[#dead + 1] = i
                framezero.Log("warn", "%s: callback de '%s' removido (o resource parou ou reiniciou).", label, list[i].res or "?")
            else
                framezero.Log("error", "%s: %s", label, msg)
            end
        end
    end
    if dead then for j = #dead, 1, -1 do table.remove(list, dead[j]) end end
end

function framezero.Internal.PlayerLoaded(src)
    runCallbacks(framezero.Internal.loaded, "OnPlayerLoaded", src, API.GetPlayerId(src))
end

function framezero.Internal.PlayerUnloaded(src)
    runCallbacks(framezero.Internal.unloaded, "OnPlayerUnloaded", src)
end

function API.OnPlayerLoaded(cb)   framezero.Internal.loaded[#framezero.Internal.loaded + 1]     = { cb = cb, res = GetInvokingResource() } end
function API.OnPlayerUnloaded(cb) framezero.Internal.unloaded[#framezero.Internal.unloaded + 1] = { cb = cb, res = GetInvokingResource() } end

-- Remove os callbacks de um resource assim que ele para (evita funcref morto).
AddEventHandler("onResourceStop", function(res)
    if res == framezero.Resource then return end
    for _, list in ipairs({ framezero.Internal.loaded, framezero.Internal.unloaded }) do
        for i = #list, 1, -1 do
            if list[i].res == res then table.remove(list, i) end
        end
    end
end)


-- Jogador
-- ID do personagem (identifier · citizenid · user_id/passaporte), sempre string
function API.GetPlayerId(src)
    if not isOnline(src) then return nil end
    local id = framezero.Call("framework", "getId", tonumber(src))
    return id and tostring(id) or nil
end

function API.GetSource(id)
    if id == nil then return nil end
    return framezero.Call("framework", "getSource", id)
end

-- Lista de sources online (mesmo formato em todos os frameworks)
function API.GetPlayers()
    return framezero.Call("framework", "getPlayers") or {}
end

function API.GetName(src)
    if not isOnline(src) then return nil end
    return framezero.Call("framework", "getName", tonumber(src)) or GetPlayerName(src)
end

-- Grupo, permissão, job ou ACE (o que o framework entender por permissão)
function API.HasPermission(src, permission)
    if not isOnline(src) or type(permission) ~= "string" then return false end
    return framezero.Call("framework", "hasPermission", tonumber(src), permission) == true
end

-- { name, label, grade, gradeLabel, onDuty } ou nil
function API.GetJob(src)
    if not isOnline(src) then return nil end
    return framezero.Call("framework", "getJob", tonumber(src))
end


-- Dinheiro
-- account: "cash" (padrão) · "bank" · "dirty"

function API.GetMoney(src, account)
    if not isOnline(src) then return 0 end
    account = account or "cash"
    if account == "dirty" and dirtyMoney().item then return API.GetItemCount(src, dirtyMoney().item) end
    return tonumber(framezero.Call("framework", "getMoney", tonumber(src), account)) or 0
end

function API.AddMoney(src, amount, account)
    amount = framezero.PositiveInt(amount)
    if not amount or not isOnline(src) then return false end
    account = account or "cash"
    if account == "dirty" and dirtyMoney().item then return API.AddItem(src, dirtyMoney().item, amount) end
    return framezero.Call("framework", "addMoney", tonumber(src), amount, account) == true
end

function API.RemoveMoney(src, amount, account)
    amount = framezero.PositiveInt(amount)
    if not amount or not isOnline(src) then return false end
    account = account or "cash"
    if account == "dirty" and dirtyMoney().item then return API.RemoveItem(src, dirtyMoney().item, amount) end
    return framezero.Call("framework", "removeMoney", tonumber(src), amount, account) == true
end


-- Itens
-- Usa o inventário detectado (ox, qs) ou o do próprio framework.

local function inv(method, ...)
    local adapter = framezero.Active.inventory
    if adapter and adapter[method] then return adapter[method](...) end
    return framezero.Call("framework", method, ...)
end

function API.GetItemCount(src, item, metadata)
    if not isOnline(src) or type(item) ~= "string" then return 0 end
    return tonumber(inv("getItemCount", tonumber(src), item, metadata)) or 0
end

function API.HasItem(src, item, amount, metadata)
    return API.GetItemCount(src, item, metadata) >= (framezero.PositiveInt(amount) or 1)
end

function API.CanCarry(src, item, amount, metadata)
    amount = framezero.PositiveInt(amount)
    if not amount or not isOnline(src) then return false end
    return inv("canCarry", tonumber(src), item, amount, metadata) ~= false
end

function API.AddItem(src, item, amount, metadata)
    amount = framezero.PositiveInt(amount)
    if not amount or not isOnline(src) or type(item) ~= "string" then return false end
    return inv("addItem", tonumber(src), item, amount, metadata) == true
end

function API.RemoveItem(src, item, amount, metadata)
    amount = framezero.PositiveInt(amount)
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
    local adapter = framezero.Active.vehicles
    if adapter and adapter[method] then return adapter[method](...) end
    return framezero.Call("framework", method, ...)
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
    kind, duration = framezero.NotifyType(kind), tonumber(duration) or 5000
    if framezero.Active.notify == "ox_lib" then
        TriggerClientEvent("ox_lib:notify", src, { description = message, type = kind == "info" and "inform" or kind, duration = duration })
    elseif framezero.Active.notify == "okokNotify" then
        TriggerClientEvent("okokNotify:Alert", src, "", message, duration, kind)
    elseif framezero.Active.notify == "mythic_notify" then
        TriggerClientEvent("mythic_notify:client:SendAlert", src, { type = kind == "warning" and "inform" or kind, text = message, length = duration })
    else
        framezero.Call("framework", "notify", tonumber(src), kind, tostring(message), duration)
    end
end

-- Caixa de texto na tela do jogador. Retorna o texto ou nil (cancelou).
function API.Prompt(src, title, placeholder)
    if not isOnline(src) then return nil end
    local text = framezero.Callback.AwaitClient(tonumber(src), "prompt", nil, title, placeholder or "")
    text = type(text) == "string" and framezero.Trim(text) or ""
    return text ~= "" and text or nil
end

-- Pergunta Sim/Não com teclas (Config.Keys). Retorna true/false.
function API.Request(src, message, timeoutSeconds)
    if not isOnline(src) then return false end
    local ms = (tonumber(timeoutSeconds) or 30) * 1000
    return framezero.Callback.AwaitClient(tonumber(src), "request", ms + 1000, message, ms) == true
end

function API.Revive(src, health)
    if not isOnline(src) then return end
    framezero.Call("framework", "revive", tonumber(src), health)
end


-- Celular
-- Integra com o celular detectado (lb-phone, qb-phone, ...). Se nenhum for
-- detectado, as funções retornam nil/false (e avisam uma vez no console).
-- target: source online OU número do telefone (string).

local function phoneCall(method, ...)
    if not framezero.Active.phone then return nil end
    return framezero.Call("phone", method, ...)
end

-- Número do telefone do jogador (string) ou nil.
function API.GetPhoneNumber(src)
    if not isOnline(src) then return nil end
    local n = phoneCall("getNumber", tonumber(src))
    return n and tostring(n) or nil
end

-- Resolve um target (source online OU número já pronto) para o número do telefone.
local function toPhoneNumber(target)
    if isOnline(target) then return API.GetPhoneNumber(target) end
    local n = target ~= nil and tostring(target) or ""
    return n ~= "" and n or nil
end

-- Envia um e-mail no app de e-mail do celular.
-- data: { subject?, message, sender? }  → true/false
function API.SendMail(target, data)
    data = data or {}
    local number = toPhoneNumber(target)
    if not number or type(data.message) ~= "string" then return false end
    return phoneCall("sendMail", number, {
        subject = tostring(data.subject or Config.PhoneSender or "FrameZero"),
        message = data.message,
        sender  = tostring(data.sender or Config.PhoneSender or "FrameZero"),
    }) == true
end

-- Envia um SMS. sender = número/nome de origem (opcional).  → true/false
-- Passa também o source (quando o target é um jogador online), porque alguns
-- celulares (ex.: smartphone/jesters-lab) criam o SMS pelo client do jogador.
function API.SendMessage(target, message, sender)
    if type(message) ~= "string" then return false end
    local src = isOnline(target) and tonumber(target) or nil
    local number = toPhoneNumber(target)
    if not number and not src then return false end
    sender = sender and tostring(sender) or tostring(Config.PhoneSender or "FrameZero")
    return phoneCall("sendMessage", number, tostring(message), sender, src) == true
end

-- Notificação na tela do celular.
-- data: { app?, title?, content }  → true/false
function API.PhoneNotify(src, data)
    if not isOnline(src) then return false end
    data = data or {}
    if type(data.content) ~= "string" then return false end
    return phoneCall("notify", tonumber(src), { app = data.app, title = data.title, content = data.content }) == true
end


-- Callbacks e banco
API.RegisterCallback = framezero.Callback.Register
API.AwaitClient = framezero.Callback.AwaitClient
API.DB = framezero.DB

function API.Info()
    return {
        version = framezero.Version,
        framework = framezero.Active.framework and framezero.Active.framework.name,
        inventory = framezero.Active.inventory and framezero.Active.inventory.name or "framework",
        vehicles = framezero.Active.vehicles and framezero.Active.vehicles.name or "framework",
        phone = framezero.Active.phone and framezero.Active.phone.name or "nenhum",
        notify = framezero.Active.notify,
        vrpFlavor = framezero.Active.framework and framezero.Active.framework.flavor and framezero.Active.framework.flavor() or nil,
        vrpFunctions = framezero.Active.framework and framezero.Active.framework.functions and framezero.Active.framework.functions() or nil,
    }
end


-- O cliente pergunta qual framework/variante está ativo (notificação, estilo vRP)
framezero.Callback.Register("info", function()
    while not framezero.Ready do Wait(100) end
    return API.Info()
end)


-- Publicação
-- Cada função pública consulta framezero.Custom primeiro.

local Public = {}
for name, fn in pairs(API) do
    if type(fn) == "function" then
        Public[name] = function(...)
            local custom = framezero.Custom[name]
            if custom then return custom(...) end
            return fn(...)
        end
    else
        Public[name] = fn
    end
end
framezero.API = Public

exports("GetFramezero", function() return Public end)
exports("IsReady", function() return framezero.Ready end)


-- Inicialização
local FRAMEWORK_RESOURCES = { "qbx_core", "qb-core", "es_extended", "tnet_core", Config.Vrp.Resource }

local function selectAdapter(kind, forced, fallback)
    if forced == "framework" then return nil end
    local adapter = framezero.SelectAdapter(kind, forced)
    if adapter and adapter.init and not adapter.init() then
        framezero.Log("error", framezero.L("adapter_failed"), kind, adapter.name)
        return nil
    end
    if not adapter and fallback then framezero.Log("debug", framezero.L("adapter_none"), kind, fallback) end
    return adapter
end

local function checkUpdate()
    if not Config.UpdateCheck or Config.UpdateUrl == "" then return end
    PerformHttpRequest(Config.UpdateUrl, function(status, body)
        if status ~= 200 or not body then return end
        local ok, data = pcall(json.decode, body)
        if ok and data and data.version and data.version ~= framezero.Version then
            framezero.Log("warn", framezero.L("update_available"), data.version, framezero.Version)
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

    framezero.Active.framework = selectAdapter("framework", Config.Framework)
    if not framezero.Active.framework then
        framezero.Active.framework = framezero.Adapters.framework.standalone
        framezero.Active.framework.init()
    end
    framezero.Active.inventory = selectAdapter("inventory", Config.Inventory, "framework")
    framezero.Active.vehicles = selectAdapter("vehicles", Config.Vehicles, "framework")
    if Config.Phone ~= "none" then framezero.Active.phone = selectAdapter("phone", Config.Phone) end
    if Config.Notify ~= "auto" then
        framezero.Active.notify = Config.Notify
    elseif framezero.Active.framework.name ~= "vrp" and framezero.IsStarted("ox_lib") then
        framezero.Active.notify = "ox_lib"
    elseif framezero.IsStarted("okokNotify") then
        framezero.Active.notify = "okokNotify"
    elseif framezero.IsStarted("mythic_notify") then
        framezero.Active.notify = "mythic_notify"
    else
        framezero.Active.notify = "framework"
    end

    for _, res in ipairs(FRAMEWORK_RESOURCES) do
        if GetResourceState(res) == "stopped" then
            framezero.Log("warn", framezero.L("start_order"), res)
        end
    end

    framezero.Ready = true
    local info = API.Info()
    framezero.Banner({
        framezero.L("started", info.version, info.framework .. (info.vrpFlavor and (" · " .. info.vrpFlavor) or ""), info.inventory, info.vehicles, info.notify),
    })
    checkUpdate()
end)
