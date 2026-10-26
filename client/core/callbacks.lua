-- framezero_bridge / client/core/callbacks.lua (callbacks cliente ⇄ servidor)
-- Cliente → servidor:  FZ.Callback.Await(nome, timeoutMs, ...)
-- Servidor → cliente:  FZ.Callback.Register(nome, function(...) end)

FZ.Callback = {}

local EVT = FZ.Resource .. ":cb:"
local handlers = {}
local pending = {}
local counter = 0


-- Cliente → servidor
function FZ.Callback.Await(name, timeoutMs, ...)
    counter = counter + 1
    local requestId = ("c%d:%d"):format(counter, GetGameTimer())
    local p = promise.new()
    pending[requestId] = p

    TriggerServerEvent(EVT .. "request", requestId, name, ...)

    SetTimeout(timeoutMs or 15000, function()
        if pending[requestId] then
            pending[requestId] = nil
            p:resolve(nil)
        end
    end)

    return Citizen.Await(p)
end

RegisterNetEvent(EVT .. "response", function(requestId, ...)
    local p = pending[requestId]
    if not p then return end
    pending[requestId] = nil
    p:resolve(...)
end)


-- Servidor → cliente
-- O handler pode responder na hora (return) ou depois, com respond(...).

function FZ.Callback.Register(name, handler)
    handlers[name] = handler
end

RegisterNetEvent(EVT .. "client", function(requestId, name, ...)
    local handler = handlers[name]
    local answered = false
    local function respond(...)
        if answered then return end
        answered = true
        TriggerServerEvent(EVT .. "client:response", requestId, ...)
    end

    if not handler then return respond(nil) end
    local results = table.pack(pcall(handler, respond, ...))
    if not results[1] then
        FZ.Log("error", "callback '%s': %s", name, tostring(results[2]))
        return respond(nil)
    end
    if results.n > 1 and results[2] ~= nil then respond(table.unpack(results, 2, results.n)) end
end)
