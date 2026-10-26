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
