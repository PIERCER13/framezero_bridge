-- Módulo de Chaves de Veículos no Servidor
-- Suporta qb-vehiclekeys, qbx_vehiclekeys, qs-vehiclekeys, wasabi_carlock e bases vRP/Creative.

framezero = framezero or {}
framezero.VehicleKeys = framezero.VehicleKeys or {}

local function safe(fn)
    local ok, res = pcall(fn)
    return ok and res
end

local function cleanPlate(plate)
    return plate and plate:gsub("^%s*(.-)%s*$", "%1") or ""
end

local function findVehicleByPlate(plate)
    local target = cleanPlate(plate):upper()
    for _, veh in ipairs(GetAllVehicles()) do
        if DoesEntityExist(veh) then
            local p = cleanPlate(GetVehicleNumberPlateText(veh)):upper()
            if p == target then return veh end
        end
    end
    return nil
end

function framezero.VehicleKeys.Give(src, plate)
    src = tonumber(src)
    if not src or not plate or plate == "" then return false end
    plate = cleanPlate(plate)

    -- 1. qbx_vehiclekeys
    if framezero.IsStarted("qbx_vehiclekeys") then
        local veh = findVehicleByPlate(plate)
        if veh and exports.qbx_vehiclekeys and exports.qbx_vehiclekeys.GiveKeys then
            return safe(function() return exports.qbx_vehiclekeys:GiveKeys(src, veh) ~= false end) or true
        end
    end

    -- 2. qb-vehiclekeys
    if framezero.IsStarted("qb-vehiclekeys") then
        local ok = safe(function()
            if exports["qb-vehiclekeys"] and exports["qb-vehiclekeys"].GiveKeys then
                return exports["qb-vehiclekeys"]:GiveKeys(src, plate) ~= false
            end
            return false
        end)
        if not ok then
            TriggerClientEvent("qb-vehiclekeys:client:AddKeys", src, plate)
        end
        return true
    end

    -- 3. qs-vehiclekeys
    if framezero.IsStarted("qs-vehiclekeys") then
        safe(function()
            exports["qs-vehiclekeys"]:GiveKeys(plate, src)
        end)
        TriggerClientEvent("qs-vehiclekeys:client:AddKeys", src, plate)
        return true
    end

    -- 4. wasabi_carlock
    if framezero.IsStarted("wasabi_carlock") then
        safe(function()
            exports.wasabi_carlock:GiveKey(src, plate)
        end)
        return true
    end

    -- 5. Fallback geral client / vRP / Creative
    TriggerClientEvent("framezero_bridge:client:giveVehicleKeys", src, plate)
    return true
end

function framezero.VehicleKeys.Remove(src, plate)
    src = tonumber(src)
    if not src or not plate or plate == "" then return false end
    plate = cleanPlate(plate)

    if framezero.IsStarted("qb-vehiclekeys") then
        safe(function()
            if exports["qb-vehiclekeys"] and exports["qb-vehiclekeys"].RemoveKeys then
                exports["qb-vehiclekeys"]:RemoveKeys(src, plate)
            end
        end)
        TriggerClientEvent("qb-vehiclekeys:client:RemoveKeys", src, plate)
        return true
    elseif framezero.IsStarted("qs-vehiclekeys") then
        safe(function()
            exports["qs-vehiclekeys"]:RemoveKeys(plate, src)
        end)
        return true
    end

    TriggerClientEvent("framezero_bridge:client:removeVehicleKeys", src, plate)
    return true
end
