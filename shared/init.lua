-- framezero_bridge / shared/init.lua (núcleo compartilhado)
-- FZ é a tabela interna da bridge. Os scripts NÃO usam FZ direto:
-- eles recebem a API pública via exports.framezero_bridge:GetBridge().

FZ = FZ or {}

FZ.Resource = GetCurrentResourceName()
FZ.Version  = GetResourceMetadata(FZ.Resource, "version", 0) or "0.0.0"
FZ.IsServer = IsDuplicityVersion()
FZ.Ready    = false

-- Adaptadores registrados por tipo, e o escolhido de cada tipo
FZ.Adapters = { framework = {}, inventory = {}, vehicles = {}, notify = {}, target = {}, progress = {} }
FZ.Active   = {}

-- Funções sobrescritas pelo dono do servidor (custom/server.lua, custom/client.lua)
FZ.Custom = FZ.Custom or {}


-- Idioma
local function lang()
    return Locales[Config.Locale] or Locales["pt-br"]
end

function FZ.L(key, ...)
    local text = lang()[key] or (Locales["en"] and Locales["en"][key]) or key
    if select("#", ...) > 0 then return text:format(...) end
    return text
end


-- Console: verde = info, amarelo = aviso, vermelho = erro
local TAG = "^3[framezero]^0 "
local LEVEL_COLOR = { info = "^2", warn = "^3", error = "^1", debug = "^5" }

function FZ.Log(level, message, ...)
    if level == "debug" and not Config.Debug then return end
    if select("#", ...) > 0 then message = message:format(...) end
    print(TAG .. (LEVEL_COLOR[level] or "") .. message .. "^0")
end

function FZ.Banner(lines)
    print("^3[framezero]^0 bridge by piercer")
    for _, line in ipairs(lines) do
        print("^3[framezero]^0 " .. line)
    end
end


-- Adaptadores
-- def: { priority = n, detect = function() -> bool, init = function() -> bool, ...métodos }
function FZ.RegisterAdapter(kind, name, def)
    def.name = name
    def.priority = def.priority or 0
    FZ.Adapters[kind][name] = def
end

function FZ.IsStarted(resource)
    local state = GetResourceState(resource)
    return state == "started" or state == "starting"
end

-- Forçado no config, ou o detectado com maior prioridade.
function FZ.SelectAdapter(kind, forced)
    local list = FZ.Adapters[kind]
    if forced and forced ~= "auto" then
        if not list[forced] then FZ.Log("error", FZ.L("adapter_unknown"), forced, kind) end
        return list[forced]
    end
    local best
    for _, def in pairs(list) do
        if def.detect and def.detect() and (not best or def.priority > best.priority) then
            best = def
        end
    end
    return best
end

-- Chama um método do adaptador ativo, avisando uma única vez quando ele não existe.
local warned = {}
function FZ.Call(kind, method, ...)
    local adapter = FZ.Active[kind]
    local fn = adapter and adapter[method]
    if not fn then
        local key = kind .. "." .. method
        if not warned[key] then
            warned[key] = true
            FZ.Log("warn", FZ.L("not_supported"), method, adapter and adapter.name or kind)
        end
        return nil
    end
    FZ.Log("debug", "%s.%s → %s", kind, method, adapter.name)
    return fn(...)
end


-- Utilidades
-- Tipos de notificação aceitos: success · error · warning · info
-- (também aceita os nomes em português usados por bases vRP)
local NOTIFY_ALIASES = {
    success = "success", sucesso = "success", verde = "success",
    error = "error", erro = "error", negado = "error", vermelho = "error",
    warning = "warning", warn = "warning", aviso = "warning", amarelo = "warning",
    info = "info", inform = "info", primary = "info", importante = "info", azul = "info",
}

function FZ.NotifyType(value)
    return NOTIFY_ALIASES[string.lower(tostring(value or "info"))] or "info"
end

function FZ.PositiveInt(value)
    local n = math.floor(tonumber(value) or 0)
    return n > 0 and n or nil
end

function FZ.Trim(text)
    return (tostring(text or ""):gsub("^%s*(.-)%s*$", "%1"))
end
