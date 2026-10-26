-- framezero_bridge / client/core/ui.lua (interface própria (web/))
-- Prompt, Request (Sim/Não), barra de progresso, texto de ajuda e
-- notificação. Usada quando o servidor não tem ox_lib.

FZ.UI = {}

local function strings()
    return {
        promptTitle = FZ.L("prompt_title"),
        confirm = FZ.L("prompt_confirm"),
        cancel = FZ.L("prompt_cancel"),
        requestTitle = FZ.L("request_title"),
        accept = FZ.L("accept"),
        decline = FZ.L("decline"),
        acceptKey = Config.Keys.Accept,
        declineKey = Config.Keys.Decline,
    }
end


-- Prompt (caixa de texto)
local promptRespond

FZ.Callback.Register("prompt", function(respond, title, placeholder)
    if promptRespond then promptRespond(nil) end
    promptRespond = respond
    SendNUIMessage({ action = "prompt:open", title = title, placeholder = placeholder or "", strings = strings() })
    SetNuiFocus(true, true)
end)

local function closePrompt(value)
    if not promptRespond then return end
    local respond = promptRespond
    promptRespond = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "prompt:close" })
    respond(value)
end

RegisterNUICallback("prompt:submit", function(data, cb) closePrompt(data and data.value) cb({}) end)
RegisterNUICallback("prompt:cancel", function(_, cb) closePrompt(nil) cb({}) end)


-- Request (Sim/Não com teclas)
local requestRespond

local function closeRequest(accepted)
    if not requestRespond then return end
    local respond = requestRespond
    requestRespond = nil
    SendNUIMessage({ action = "request:close" })
    respond(accepted == true)
end

FZ.Callback.Register("request", function(respond, message, timeoutMs)
    if requestRespond then closeRequest(false) end
    requestRespond = respond
    SendNUIMessage({ action = "request:open", message = message, timeout = timeoutMs, strings = strings() })
    local mine = respond
    SetTimeout(timeoutMs or 30000, function()
        if requestRespond == mine then closeRequest(false) end
    end)
end)

-- Nomes de comando únicos por sessão para não colidir com outros resources
local suffix = tostring(math.random(10000, 99999))
RegisterCommand("+fz_accept_" .. suffix, function() closeRequest(true) end, false)
RegisterCommand("+fz_decline_" .. suffix, function() closeRequest(false) end, false)
RegisterKeyMapping("+fz_accept_" .. suffix, FZ.L("keymap_accept"), "keyboard", Config.Keys.Accept)
RegisterKeyMapping("+fz_decline_" .. suffix, FZ.L("keymap_decline"), "keyboard", Config.Keys.Decline)


-- Progresso
local progressActive = false

-- Retorna true se completou, false se cancelou (X ou morte)
function FZ.UI.Progress(label, duration, opts)
    if progressActive then return false end
    opts = opts or {}
    progressActive = true
    SendNUIMessage({ action = "progress:start", label = label, duration = duration })

    local finished, cancelled = false, false
    SetTimeout(duration, function() finished = true end)
    while not finished and not cancelled do
        if opts.disableControls ~= false then
            DisableControlAction(0, 24, true)  -- atacar
            DisableControlAction(0, 25, true)  -- mirar
            DisableControlAction(0, 21, true)  -- correr
        end
        if opts.canCancel and IsControlJustPressed(0, 73) then cancelled = true end   -- X
        if IsEntityDead(PlayerPedId()) then cancelled = true end
        Wait(0)
    end

    SendNUIMessage({ action = "progress:stop", cancelled = cancelled })
    progressActive = false
    return not cancelled
end


-- Texto de ajuda e notificação
function FZ.UI.ShowText(text)
    SendNUIMessage({ action = "text:show", text = text })
end

function FZ.UI.HideText()
    SendNUIMessage({ action = "text:hide" })
end

function FZ.UI.Notify(kind, message, duration)
    SendNUIMessage({ action = "notify", kind = kind, message = message, duration = duration or 5000 })
end

RegisterNetEvent(FZ.Resource .. ":notify", function(kind, message, duration)
    FZ.UI.Notify(FZ.NotifyType(kind), message, duration)
end)
