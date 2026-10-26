
-- Depois é só usar a global Bridge, no servidor ou no cliente:
-- Bridge.Notify(source, "success", "Pronto!")

local BRIDGE = "framezero_bridge"
local api

local function load()
    if api then return api end
    if GetResourceState(BRIDGE) ~= "started" then
        error(("^1[%s] a resource %s não está iniciada. Coloque 'ensure %s' antes deste script no server.cfg.^0")
            :format(GetCurrentResourceName(), BRIDGE, BRIDGE), 3)
    end
    api = exports[BRIDGE]:GetBridge()
    return api
end

-- Carrega a API na primeira vez que alguma função é usada
Bridge = setmetatable({}, {
    __index = function(_, key)
        return load()[key]
    end,
})

-- Espera a bridge terminar de detectar o framework (use dentro de uma thread)
function Bridge.WaitReady(timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 15000)
    while GetGameTimer() < deadline do
        if GetResourceState(BRIDGE) == "started" and exports[BRIDGE]:IsReady() then return true end
        Wait(100)
    end
    return false
end
