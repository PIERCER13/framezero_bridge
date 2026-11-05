-- Permite que scripts de assalto, drogas, perseguição acionem a polícia com facilidade.
-- Uso: framezero.Dispatch({ code = "10-90", title = "Assalto a Loja", message = "Disparo de alarme", coords = vec3(...) })

framezero = framezero or {}
framezero.Dispatch = framezero.Dispatch or {}

local function getStreetName(coords)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    if crossHash ~= 0 then
        local cross = GetStreetNameFromHashKey(crossHash)
        if cross and cross ~= "" then street = street .. " & " .. cross end
    end
    return street or "Localização Desconhecida"
end

function framezero.ClientDispatch(data)
    data = data or {}
    local ped = PlayerPedId()
    local coords = data.coords or GetEntityCoords(ped)
    local street = data.street or getStreetName(coords)
    local gender = data.gender or (framezero.API.GetGender and framezero.API.GetGender() or "Desconhecido")

    local payload = {
        code = data.code or "10-90",
        title = data.title or "Ocorrência Policial",
        message = data.message or ("Atividade suspeita em " .. street),
        coords = coords,
        street = street,
        gender = gender,
        jobs = data.jobs or { "police", "sheriff", "cop", "pm", "policia" },
        sprite = data.sprite or 161,
        scale = data.scale or 1.0,
        color = data.color or 1,
        blipText = data.blipText or (data.code or "10-90") .. " - " .. (data.title or "Ocorrência"),
        time = data.time or (60 * 1000),
    }

    -- 1. cd_dispatch
    if framezero.IsStarted("cd_dispatch") then
        TriggerServerEvent("cd_dispatch:AddNotification", {
            job_table = payload.jobs,
            coords = payload.coords,
            title = payload.title,
            message = payload.message .. " em " .. payload.street,
            flash = 0,
            unique_id = math.random(100000, 999999),
            sound = 1,
            blip = {
                sprite = payload.sprite,
                scale = payload.scale,
                colour = payload.color,
                flashes = false,
                text = payload.blipText,
                time = math.floor(payload.time / 1000),
                radius = 0,
            }
        })
        return true
    end

    -- 2. ps-dispatch
    if framezero.IsStarted("ps-dispatch") then
        TriggerServerEvent("ps-dispatch:server:notify", {
            message = payload.title,
            codeName = payload.code:lower():gsub("%s+", ""),
            code = payload.code,
            icon = "fas fa-shield-alt",
            priority = 2,
            coords = payload.coords,
            gender = payload.gender,
            street = payload.street,
            jobs = payload.jobs,
        })
        return true
    end

    -- 3. qs-dispatch
    if framezero.IsStarted("qs-dispatch") then
        TriggerServerEvent("qs-dispatch:server:CreateDispatchCall", {
            job = payload.jobs,
            callLocation = payload.coords,
            callCode = { code = payload.code, snippet = payload.title },
            message = payload.message .. " em " .. payload.street,
            flashes = true,
            blip = {
                sprite = payload.sprite,
                scale = payload.scale,
                colour = payload.color,
                flashes = true,
                text = payload.blipText,
                time = payload.time,
            }
        })
        return true
    end

    -- 4. linden_outlawalert
    if framezero.IsStarted("linden_outlawalert") then
        TriggerServerEvent("wf-alerts:svNotify", {
            dispatchData = {
                displayCode = payload.code,
                description = payload.title,
                isImportant = 0,
                recipientList = payload.jobs,
                length = tostring(payload.time),
                infoM = "fa-shield-alt",
                info = payload.message,
            },
            caller = "Cidadão",
            coords = payload.coords,
        })
        return true
    end

    -- 5. Fallback geral pelo servidor da bridge
    TriggerServerEvent("framezero_bridge:server:dispatch", payload)
    return true
end

RegisterNetEvent("framezero_bridge:client:dispatchBlip", function(data)
    if not data or not data.coords then return end
    PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", false)

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, data.sprite or 161)
    SetBlipScale(blip, data.scale or 1.0)
    SetBlipColour(blip, data.color or 1)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.blipText or "10-90 - Ocorrência")
    EndTextCommandSetBlipName(blip)

    local radiusBlip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, 60.0)
    SetBlipColour(radiusBlip, data.color or 1)
    SetBlipAlpha(radiusBlip, 128)

    SetTimeout(data.time or 30000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        if DoesBlipExist(radiusBlip) then RemoveBlip(radiusBlip) end
    end)
end)
