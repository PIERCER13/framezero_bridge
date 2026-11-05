-- Atende chamadas diretas de scripts no servidor ou repassa alertas do fallback do cliente.

framezero = framezero or {}
framezero.Dispatch = framezero.Dispatch or {}

local function notifyPolice(data)
    local players = framezero.API.GetPlayers()
    local policePerms = {
        "police.permissao",
        "policia.permissao",
        "cop.permissao",
        "police",
        "policia",
        "pm",
        "sheriff",
    }

    local text = ("^3[%s]^0 %s - %s (%s)"):format(data.code or "10-90", data.title or "Ocorrência", data.message or "", data.street or "")

    for _, src in ipairs(players) do
        local isPolice = false
        for _, perm in ipairs(policePerms) do
            if framezero.API.HasPermission(src, perm) then
                isPolice = true
                break
            end
        end

        if not isPolice then
            local job = framezero.API.GetJob(src)
            if job and (job.name == "police" or job.name == "policia" or job.name == "sheriff") then
                isPolice = true
            end
        end

        if isPolice then
            framezero.API.Notify(src, "warning", text, 10000)
            TriggerClientEvent("framezero_bridge:client:dispatchBlip", src, data)
        end
    end
end

RegisterNetEvent("framezero_bridge:server:dispatch", function(data)
    notifyPolice(data)
end)

function framezero.Dispatch.Send(data)
    notifyPolice(data)
end
