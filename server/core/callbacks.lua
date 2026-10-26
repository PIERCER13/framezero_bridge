-- framezero_bridge / server/core/callbacks.lua (callbacks cliente ⇄ servidor)
-- Servidor → cliente:  FZ.Callback.AwaitClient(src, nome, timeoutMs, ...)
-- Cliente → servidor:  FZ.Callback.Register(nome, function(src, ...) end)
--
-- Tudo que chega do cliente é entrada do jogador: valide no handler.

FZ.Callback = {}

local EVT = FZ.Resource .. ":cb:"
local handlers = {}
local pending = {}
local counter = 0

-- Limite por jogador
local hits = {}
local function limited(src)
    local now = os.time()
    local entry = hits[src]
    if not entry or entry.second ~= now then
        hits[src] = { second = now, count = 1 }
        return false
    end
    entry.count = entry.count + 1
    if entry.count == Config.CallbackRateLimit + 1 then FZ.Log("warn", FZ.L("rate_limited"), src) end
    return entry.count > Config.CallbackRateLimit
end


-- Cliente → servidor
function FZ.Callback.Register(name, handler)
    handlers[name] = handler
end

RegisterNetEvent(EVT .. "request", function(requestId, name, ...)
    local src = source
    if type(requestId) ~= "string" or type(name) ~= "string" then return end

    local handler = handlers[name]
    if not handler or limited(src) then
        TriggerClientEvent(EVT .. "response", src, requestId, nil)
        return
    end

    local ok, a, b, c, d, e = pcall(handler, src, ...)
    if not ok then
        FZ.Log("error", "callback '%s': %s", name, tostring(a))
        a, b, c, d, e = nil, nil, nil, nil, nil
    end
    TriggerClientEvent(EVT .. "response", src, requestId, a, b, c, d, e)
end)


-- Servidor → cliente
function FZ.Callback.AwaitClient(src, name, timeoutMs, ...)
    counter = counter + 1
    local requestId = ("%d:%d"):format(src, counter)
    local p = promise.new()
    pending[requestId] = { promise = p, source = src }

    TriggerClientEvent(EVT .. "client", src, requestId, name, ...)

    if timeoutMs and timeoutMs > 0 then
        SetTimeout(timeoutMs, function()
            local entry = pending[requestId]
            if entry then
                pending[requestId] = nil
                entry.promise:resolve(nil)
            end
        end)
    end

    return Citizen.Await(p)
end

RegisterNetEvent(EVT .. "client:response", function(requestId, ...)
    local entry = pending[requestId]
    -- Só aceita a resposta do mesmo jogador que recebeu o pedido
    if not entry or entry.source ~= source then return end
    pending[requestId] = nil
    entry.promise:resolve(...)
end)

AddEventHandler("playerDropped", function()
    local src = source
    hits[src] = nil
    for requestId, entry in pairs(pending) do
        if entry.source == src then
            pending[requestId] = nil
            entry.promise:resolve(nil)
        end
    end
end)
