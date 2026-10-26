-- O servidor decide o framework (e a variante do vRP) e o cliente
-- pergunta uma vez pelo callback "info".

framezero.Client = { info = nil, loaded = {}, isLoaded = false }

function framezero.Client.Info()
    if not framezero.Client.info then
        framezero.Client.info = framezero.Callback.Await("info", 10000) or { framework = "standalone", notify = "framework" }
    end
    return framezero.Client.info
end


-- Notificação
local VRP_STYLES = {
    vrpex     = { success = "sucesso", error = "negado", warning = "aviso", info = "importante" },
    creative  = { success = "verde", error = "vermelho", warning = "amarelo", info = "azul" },
}

function framezero.Client.Notify(kind, message, duration)
    kind, duration = framezero.NotifyType(kind), tonumber(duration) or 5000
    local info = framezero.Client.Info()

    if info.notify == "ox_lib" then
        exports.ox_lib:notify({ description = message, type = kind == "info" and "inform" or kind, duration = duration })
    elseif info.framework == "esx" then
        TriggerEvent("esx:showNotification", message, kind == "warning" and "info" or kind, duration)
    elseif info.framework == "qbcore" or info.framework == "qbox" then
        TriggerEvent("QBCore:Notify", message, kind == "info" and "primary" or kind, duration)
    elseif info.notify == "okokNotify" then
        exports.okokNotify:Alert("", message, duration, kind)
    elseif info.notify == "mythic_notify" then
        exports.mythic_notify:DoHudText(kind == "warning" and "inform" or kind, message)
    elseif info.framework == "tnet" then
        TriggerEvent("Notify", kind, message, math.floor(duration / 1000))
    elseif info.framework == "vrp" then
        local style = Config.Vrp.NotifyStyle
        if style == "auto" then style = info.vrpFlavor == "vrpex" and "vrpex" or "creative" end
        if style == "enchanted" then
            TriggerEvent("Notify", "Notificação", message, VRP_STYLES.creative[kind], duration)
        else
            TriggerEvent("Notify", VRP_STYLES[style][kind], message, duration)
        end
    else
        framezero.UI.Notify(kind, message, duration)
    end
end


-- Jogador carregado
local function playerLoaded()
    if framezero.Client.isLoaded then return end
    framezero.Client.isLoaded = true
    for _, cb in ipairs(framezero.Client.loaded) do
        local ok, err = pcall(cb)
        if not ok then framezero.Log("error", "OnPlayerLoaded: %s", err) end
    end
end

AddEventHandler("esx:playerLoaded", playerLoaded)
AddEventHandler("QBCore:Client:OnPlayerLoaded", playerLoaded)
AddEventHandler("playerSpawned", playerLoaded)       -- vRP · Creative · standalone

-- Bridge reiniciada com o jogador já dentro do servidor
CreateThread(function()
    Wait(2000)
    if NetworkIsPlayerActive(PlayerId()) and DoesEntityExist(PlayerPedId()) then playerLoaded() end
end)
