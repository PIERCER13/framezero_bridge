-- Utilitários de Streaming, Assets, Peds e Imagens de Itens para o FrameZero

framezero = framezero or {}
framezero.Streaming = framezero.Streaming or {}

-- 1. Await com timeout
function framezero.AwaitLoad(checkFn, errorMsg, timeoutMs)
    timeoutMs = timeoutMs or 5000
    local deadline = GetGameTimer() + timeoutMs
    while GetGameTimer() < deadline do
        if checkFn() then return true end
        Wait(10)
    end
    framezero.Log("warn", "%s (timeout após %d ms)", errorMsg or "Falha de carregamento de asset", timeoutMs)
    return false
end

-- 2. Carregar Model
function framezero.LoadModel(model, timeoutMs)
    local hash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        framezero.Log("error", "Modelo inválido: %s", tostring(model))
        return false
    end
    RequestModel(hash)
    local ok = framezero.AwaitLoad(function() return HasModelLoaded(hash) end, ("Timeout carregando modelo %s"):format(model), timeoutMs or 7500)
    return ok and hash or false
end

-- 3. Carregar Dicionário de Animação
function framezero.LoadAnim(dict, timeoutMs)
    if not DoesAnimDictExist(dict) then
        framezero.Log("warn", "Dicionário de animação não existe: %s", tostring(dict))
        return false
    end
    RequestAnimDict(dict)
    local ok = framezero.AwaitLoad(function() return HasAnimDictLoaded(dict) end, ("Timeout carregando animação %s"):format(dict), timeoutMs or 5000)
    return ok and dict or false
end

-- 4. Carregar Particle FX
function framezero.LoadPtfx(asset, timeoutMs)
    RequestNamedPtfxAsset(asset)
    local ok = framezero.AwaitLoad(function() return HasNamedPtfxAssetLoaded(asset) end, ("Timeout carregando partícula %s"):format(asset), timeoutMs or 5000)
    return ok and asset or false
end

-- 5. Imagem do item (URL nui://)
local INVENTORY_PATHS = {
    { res = "ox_inventory",     fmt = "nui://ox_inventory/web/images/%s.png" },
    { res = "codem-inventory",  fmt = "nui://codem-inventory/html/itemimages/%s.png" },
    { res = "qs-inventory-pro", fmt = "nui://qs-inventory-pro/html/images/%s.png" },
    { res = "qs-inventory",     fmt = "nui://qs-inventory/html/images/%s.png" },
    { res = "qb-inventory",     fmt = "nui://qb-inventory/html/images/%s.png" },
    { res = "ps-inventory",     fmt = "nui://ps-inventory/html/images/%s.png" },
    { res = "lj-inventory",     fmt = "nui://lj-inventory/html/images/%s.png" },
}

function framezero.GetItemImage(item)
    if not item or item == "" then return "" end
    for _, inv in ipairs(INVENTORY_PATHS) do
        if framezero.IsStarted(inv.res) then
            return inv.fmt:format(item)
        end
    end
    return ("nui://inventory/html/images/%s.png"):format(item)
end

-- 6. Gerenciamento e Spawner de Peds / NPCs
local spawnedPeds = {}
local pointPeds = {}

local function applyPedOptions(ped, data)
    if data.freeze ~= false then FreezeEntityPosition(ped, true) end
    if data.invincible ~= false then SetEntityInvincible(ped, true) end
    if data.blockEvents ~= false then SetBlockingOfNonTemporaryEvents(ped, true) end
    if data.scenario then TaskStartScenarioInPlace(ped, data.scenario, 0, true) end
    PlaceObjectOnGroundProperly(ped)

    if data.targetOptions then
        local opts = data.targetOptions
        if opts.options then
            -- Suporte direto a options do target
            framezero.API.AddModel("ped_" .. tostring(ped), { data.model }, opts.options)
        end
    end
end

function framezero.CreatePed(data)
    if not data or not data.model or not data.coords then return nil end
    local hash = framezero.LoadModel(data.model)
    if not hash then return nil end

    local c = data.coords
    local ped = CreatePed(0, hash, c.x, c.y, c.z, c.w or (c.heading or 0.0), false, false)
    SetModelAsNoLongerNeeded(hash)

    applyPedOptions(ped, data)
    spawnedPeds[#spawnedPeds + 1] = ped
    return ped
end

--- Cria um Ped que só existe na memória quando o jogador está perto.
-- Economiza FPS, memória de streaming e entidades na rede.
-- data = { model, coords = vec4, distance = 40.0, scenario?, freeze?, targetOptions? }
function framezero.CreatePedAtPoint(data)
    data = data or {}
    local id = #pointPeds + 1
    pointPeds[id] = {
        data = data,
        distance = data.distance or 40.0,
        ped = nil,
    }
    return id
end

-- Thread de streaming por distância para peds at point
CreateThread(function()
    while true do
        local sleep = 1000
        if #pointPeds > 0 then
            local pCoords = GetEntityCoords(PlayerPedId())
            for id, entry in ipairs(pointPeds) do
                local c = entry.data.coords
                local dist = #(pCoords - vector3(c.x, c.y, c.z))

                if dist <= entry.distance then
                    if not entry.ped or not DoesEntityExist(entry.ped) then
                        entry.ped = framezero.CreatePed(entry.data)
                    end
                    sleep = 500
                else
                    if entry.ped and DoesEntityExist(entry.ped) then
                        DeleteEntity(entry.ped)
                        entry.ped = nil
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Limpeza ao parar a resource
AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        for _, ped in ipairs(spawnedPeds) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        for _, entry in ipairs(pointPeds) do
            if entry.ped and DoesEntityExist(entry.ped) then DeleteEntity(entry.ped) end
        end
    end
end)
