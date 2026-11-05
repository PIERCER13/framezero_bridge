-- Suporta qb-vehiclekeys, qbx_vehiclekeys, qs-vehiclekeys, wasabi_carlock e bases vRP/Creative.

framezero = framezero or {}
framezero.VehicleKeys = framezero.VehicleKeys or {}

local function cleanPlate(plate)
    return plate and plate:gsub("^%s*(.-)%s*$", "%1") or ""
end

local localKeys = {}

function framezero.VehicleKeys.Give(plate)
    plate = cleanPlate(plate)
    if not plate or plate == "" then return false end
    localKeys[plate:upper()] = true

    if framezero.IsStarted("qb-vehiclekeys") then
        TriggerEvent("qb-vehiclekeys:client:AddKeys", plate)
    elseif framezero.IsStarted("qs-vehiclekeys") then
        TriggerEvent("qs-vehiclekeys:client:AddKeys", plate)
    end
    return true
end

function framezero.VehicleKeys.Remove(plate)
    plate = cleanPlate(plate)
    if not plate or plate == "" then return false end
    localKeys[plate:upper()] = nil

    if framezero.IsStarted("qb-vehiclekeys") then
        TriggerEvent("qb-vehiclekeys:client:RemoveKeys", plate)
    end
    return true
end

function framezero.VehicleKeys.Has(plate)
    plate = cleanPlate(plate)
    if not plate or plate == "" then return false end

    if framezero.IsStarted("qb-vehiclekeys") and exports["qb-vehiclekeys"].HasKeys then
        local ok, has = pcall(function() return exports["qb-vehiclekeys"]:HasKeys(plate) end)
        if ok and has ~= nil then return has == true end
    end

    if framezero.IsStarted("qbx_vehiclekeys") and exports.qbx_vehiclekeys.HasKeys then
        local ok, has = pcall(function() return exports.qbx_vehiclekeys:HasKeys(plate) end)
        if ok and has ~= nil then return has == true end
    end

    return localKeys[plate:upper()] == true
end

RegisterNetEvent("framezero_bridge:client:giveVehicleKeys", function(plate)
    framezero.VehicleKeys.Give(plate)
end)

RegisterNetEvent("framezero_bridge:client:removeVehicleKeys", function(plate)
    framezero.VehicleKeys.Remove(plate)
end)
