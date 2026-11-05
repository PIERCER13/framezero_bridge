-- Sem garagem detectada, a bridge usa a tabela de veículos do
-- próprio framework (adaptador "framework").

-- nation-garages (vRP)
local nation = function() return exports["nation-garages"] end

framezero.RegisterAdapter("vehicles", "nation-garages", {
    priority = 30,

    detect = function() return framezero.IsStarted("nation-garages") end,
    init = function() return true end,

    -- O nation-garages gera a própria placa; devolvemos a que ele criou.
    giveVehicle = function(id, model, plate, opts)
        local data = nation():addUserVehicle(model, tonumber(id) or id, { plate = plate, type = opts.type })
        return data ~= nil, data and data.plate or plate
    end,

    hasVehicle = function(id, model)
        return nation():getUserVehicle(tonumber(id) or id, model) ~= nil
    end,

    plateExists = function(plate)
        local data = nation():getVehicleData(plate)
        return data ~= nil and next(data) ~= nil
    end,
})


-- qbx_vehicles (Qbox)
framezero.RegisterAdapter("vehicles", "qbx_vehicles", {
    priority = 20,

    detect = function() return framezero.IsStarted("qbx_vehicles") end,
    init = function() return true end,

    giveVehicle = function(id, model, plate, opts)
        local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle({
            model = model,
            citizenid = id,
            garage = opts.garage or Config.VehicleDefaults.Garage,
            props = { plate = plate },
        })
        return vehicleId ~= nil, plate
    end,

    hasVehicle = function(id, model)
        return framezero.DB.Scalar("SELECT 1 FROM player_vehicles WHERE citizenid = ? AND vehicle = ? LIMIT 1", { id, model }) ~= nil
    end,

    plateExists = function(plate)
        return framezero.DB.Scalar("SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1", { plate }) ~= nil
    end,
})


-- qs-advancedgarages (Quasar Store)
-- https://docs.quasar-store.com
framezero.RegisterAdapter("vehicles", "qs-advancedgarages", {
    priority = 25,

    detect = function() return framezero.IsStarted("qs-advancedgarages") end,
    init = function() return true end,

    giveVehicle = function(id, model, plate, opts)
        local ok = pcall(function()
            if exports["qs-advancedgarages"].GiveVehicle then
                exports["qs-advancedgarages"]:GiveVehicle(id, model, plate, opts and opts.garage or Config.VehicleDefaults.Garage)
            end
        end)
        return ok, plate
    end,

    hasVehicle = function(id, model)
        return framezero.DB.Scalar("SELECT 1 FROM player_vehicles WHERE (citizenid = ? OR charid = ? OR owner = ?) AND vehicle = ? LIMIT 1", { id, id, id, model }) ~= nil
    end,

    plateExists = function(plate)
        local trimmed = plate:gsub("^%s*(.-)%s*$", "%1")
        if exports["qs-advancedgarages"].IsVehicleInsured then
            local ok, insured = pcall(function() return exports["qs-advancedgarages"]:IsVehicleInsured(trimmed) end)
            if ok and insured ~= nil then return true end
        end
        return framezero.DB.Scalar("SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1", { trimmed }) ~= nil
    end,
})


-- nn_garages (NANO Scripts)
-- https://nanoscripts.gitbook.io/docs
framezero.RegisterAdapter("vehicles", "nn_garages", {
    priority = 22,

    detect = function() return framezero.IsStarted("nn_garages") end,
    init = function() return true end,

    giveVehicle = function(id, model, plate, opts)
        local ok = pcall(function()
            if exports["nn_garages"] and exports["nn_garages"].AddVehicle then
                exports["nn_garages"]:AddVehicle(id, model, plate, opts)
            end
        end)
        return ok, plate
    end,

    hasVehicle = function(id, model)
        return framezero.DB.Scalar("SELECT 1 FROM player_vehicles WHERE (citizenid = ? OR owner = ?) AND vehicle = ? LIMIT 1", { id, id, model }) ~= nil
    end,

    plateExists = function(plate)
        return framezero.DB.Scalar("SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1", { plate }) ~= nil
    end,
})
