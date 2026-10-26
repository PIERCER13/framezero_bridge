-- framezero / verificação de licença
-- Vai junto dos scripts pagos. Valida a licença na API da FrameZero ao iniciar
-- e de tempos em tempos. A conferência da assinatura roda no license.js (Node).
--
-- No fxmanifest do script protegido:
--   server_script "@framezero_bridge/license.js"
--   server_script "@framezero_bridge/license.lua"
-- A licença NÃO fica no config: ela mora no resource framezero_token
-- (tokens.lua) ou num token.lua dentro do próprio script. O dono do
-- servidor cola a chave num lugar só e todos os scripts leem de lá.

framezero = framezero or {}
framezero.License = {}

local VAZIO = { [""] = true, ["COLE-SUA-LICENCA-AQUI"] = true }

-- Acha a licença de um resource. Ordem: chave passada na mão -> token.lua do
-- próprio script (framezero.Token) -> resource central framezero_token.
local function resolveKey(resource, explicit)
    if explicit and not VAZIO[explicit] then return explicit end

    if framezero.Token and framezero.Token[resource] then
        local v = framezero.Token[resource]
        if v and not VAZIO[v] then return v end
    end

    local ok, v = pcall(function()
        return exports["framezero_token"]:GetToken(resource)
    end)
    if ok and v and not VAZIO[v] then return v end

    return nil
end

local API = "https://api.framezero.com.br/api/v1/validate"   -- trocar pelo endereço real
local CHECK_INTERVAL = 3 * 60 * 60 * 1000                      -- a cada 3 horas
local ok = false

-- Gera um nonce aleatório para cada chamada (impede repetir uma resposta antiga)
local function nonce()
    local chars, out = "abcdef0123456789", {}
    for i = 1, 24 do
        local n = math.random(1, #chars)
        out[i] = chars:sub(n, n)
    end
    return table.concat(out)
end

-- Porta do servidor FiveM. Prende a licença em IP+porta, então 3 servers na
-- mesma máquina (portas diferentes) não validam todos na mesma licença.
local function serverPort()
    return GetConvarInt("netPort", 30120)
end

-- Valida uma vez. Retorna true/false e o motivo.
local function validate(key, resource)
    local n = nonce()
    local p = promise.new()

    PerformHttpRequest(API, function(status, body)
        if status ~= 200 or not body then
            p:resolve({ ok = false, reason = "sem_resposta" })
            return
        end
        -- license.js confere a assinatura Ed25519, o nonce e o resource
        local result = exports[GetCurrentResourceName()]:VerifyLicense(body, n, resource)
        p:resolve(result or { ok = false, reason = "falha_verificacao" })
    end, "POST", json.encode({ key = key, resource = resource, nonce = n, port = serverPort() }), { ["Content-Type"] = "application/json" })

    return Citizen.Await(p)
end

-- Liga a proteção de um script. Chame no início do server.lua do script protegido.
--   framezero.License.Protect("framezero_doors")            -- pega a chave do token
--   framezero.License.Protect("framezero_doors", chave)     -- chave na mão
--   framezero.License.Protect("framezero_doors", nil, fn)   -- onFail próprio
-- onFail: função chamada quando a licença é inválida (padrão: desliga o recurso).
function framezero.License.Protect(resource, key, onFail)
    onFail = onFail or function(reason)
        print(("^1[framezero] licença inválida (%s). O recurso %s não vai iniciar.^0"):format(reason, resource))
        -- Para o recurso em vez de deixar rodar sem licença
        StopResource(resource)
    end

    key = resolveKey(resource, key)
    if not key then
        onFail("sem_licenca")
        print(("^1[framezero] cole a licença de %s em framezero_token (tokens.lua).^0"):format(resource))
        return
    end

    CreateThread(function()
        local result = validate(key, resource)
        ok = result.ok
        if not ok then
            onFail(result.reason)
            return
        end
        print(("^2[framezero] %s validado.^0"):format(resource))

        while true do
            Wait(CHECK_INTERVAL)
            local recheck = validate(key, resource)
            if not recheck.ok and recheck.reason ~= "sem_resposta" then
                ok = false
                onFail(recheck.reason)
                return
            end
        end
    end)
end

function framezero.License.IsValid()
    return ok
end
