-- Controle de portas / trancas no cliente
-- Uso: framezero.SetDoorState(doorId, locked, options)

framezero = framezero or {}
framezero.Doorlock = framezero.Doorlock or {}

function framezero.Doorlock.SetState(doorId, locked, options)
    options = options or {}
    local state = (locked == true or locked == 1)

    if framezero.IsStarted("qb-doorlock") then
        TriggerServerEvent("qb-doorlock:server:updateState", doorId, state, false, false, options.playSound ~= false, false, false)
        return true
    elseif framezero.IsStarted("nui-doorlock") then
        TriggerServerEvent("nui_doorlock:server:updateState", doorId, state, false, false, options.playSound ~= false)
        return true
    else
        TriggerServerEvent("framezero_bridge:server:setDoorState", doorId, state, options)
        return true
    end
end
