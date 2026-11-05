-- Suporta ox_doorlock, qb-doorlock, nui-doorlock, cd_doorlock e doors_creator.

framezero = framezero or {}
framezero.Doorlock = framezero.Doorlock or {}

local function safe(fn)
    local ok, res = pcall(fn)
    return ok and res
end

function framezero.Doorlock.SetState(doorId, locked, options)
    options = options or {}
    local state = (locked == true or locked == 1)

    -- 1. ox_doorlock
    if framezero.IsStarted("ox_doorlock") then
        local id = tonumber(doorId)
        if not id and type(doorId) == "string" and exports["ox_doorlock"].getDoorFromName then
            local d = exports["ox_doorlock"]:getDoorFromName(doorId)
            id = d and d.id
        end
        if id then
            TriggerEvent("ox_doorlock:setState", id, state and 1 or 0)
            return true
        end
    end

    -- 2. qb-doorlock
    if framezero.IsStarted("qb-doorlock") then
        TriggerEvent("qb-doorlock:server:updateState", doorId, state, false, false, options.playSound ~= false, false, false)
        return true
    end

    -- 3. nui-doorlock
    if framezero.IsStarted("nui-doorlock") then
        TriggerEvent("nui_doorlock:server:updateState", doorId, state, false, false, options.playSound ~= false)
        return true
    end

    -- 4. cd_doorlock
    if framezero.IsStarted("cd_doorlock") then
        TriggerClientEvent("cd_doorlock:SetDoorState_name", -1, state, doorId, options.location)
        return true
    end

    -- 5. doors_creator
    if framezero.IsStarted("doors_creator") then
        safe(function()
            exports["doors_creator"]:setDoorState(tonumber(doorId) or doorId, state and 1 or 0)
        end)
        return true
    end

    framezero.Log("warn", "Nenhum sistema de tranca suportado encontrado para a porta '%s'", tostring(doorId))
    return false
end

RegisterNetEvent("framezero_bridge:server:setDoorState", function(doorId, locked, options)
    framezero.Doorlock.SetState(doorId, locked, options)
end)
