-- A interface Proxy do vRP responde a QUALQUER nome de função, então
-- "if vRP.Passport then" nunca falha. Por isso a bridge lê os arquivos
-- do resource vrp e anota quais funções realmente existem.
--
-- Também carrega a lib/utils.lua do vrp em tempo de execução: não é
-- preciso editar o fxmanifest com "@vrp/lib/utils.lua".

framezero.Vrp = {}

local defined
local FALLBACK_FILES = {
    "base.lua", "modules/base.lua", "modules/player.lua", "modules/players.lua", "modules/user.lua",
    "modules/inventory.lua", "modules/items.lua", "modules/money.lua", "modules/bank.lua",
    "modules/group.lua", "modules/groups.lua", "modules/identity.lua", "modules/survival.lua",
    "modules/vehicles.lua", "modules/garages.lua", "modules/connect.lua", "modules/prepare.lua",
    "modules/player_state.lua", "modules/basic_items.lua", "modules/salary.lua", "modules/misc.lua",
}

local function manifestFiles(resource)
    local files = {}
    for _, key in ipairs({ "server_script", "shared_script" }) do
        for i = 0, (GetNumResourceMetadata(resource, key) or 0) - 1 do
            local entry = GetResourceMetadata(resource, key, i)
            if entry and not entry:find("*", 1, true) and entry:sub(1, 1) ~= "@" then
                files[#files + 1] = entry
            end
        end
    end
    return files
end

function framezero.Vrp.Scan()
    if defined then return defined end
    defined = {}
    local resource = Config.Vrp.Resource
    local files = manifestFiles(resource)
    for _, file in ipairs(FALLBACK_FILES) do files[#files + 1] = file end

    local seen = {}
    for _, file in ipairs(files) do
        if not seen[file] then
            seen[file] = true
            local code = LoadResourceFile(resource, file)
            if code then
                for name in code:gmatch("function%s+vRP[%.:]([%w_]+)%s*%(") do defined[name] = true end
                for name in code:gmatch("vRP%.([%w_]+)%s*=%s*function") do defined[name] = true end
            end
        end
    end
    return defined
end

function framezero.Vrp.Has(name)
    return framezero.Vrp.Scan()[name] == true
end

-- Primeiro nome da lista que existe nesta base
function framezero.Vrp.Pick(...)
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        if framezero.Vrp.Has(name) then return name end
    end
end

function framezero.Vrp.Count()
    local n = 0
    for _ in pairs(framezero.Vrp.Scan()) do n = n + 1 end
    return n
end

-- creative-modern (Passport) · creative (userSource/userList) · vrpex (getUserId)
function framezero.Vrp.Flavor()
    if framezero.Vrp.Has("Passport") then return "creative-modern" end
    if framezero.Vrp.Has("userSource") or framezero.Vrp.Has("userList") then return "creative" end
    return "vrpex"
end

function framezero.Vrp.Load()
    if framezero.Vrp.server then return true end
    local resource = Config.Vrp.Resource

    if type(module) ~= "function" then
        local code = LoadResourceFile(resource, "lib/utils.lua")
        if not code then
            framezero.Log("error", framezero.L("vrp_missing"), resource)
            return false
        end
        local chunk, err = load(code, ("@%s/lib/utils.lua"):format(resource))
        if not chunk then
            framezero.Log("error", "lib/utils.lua: %s", err)
            return false
        end
        chunk()
    end

    local Proxy = module(resource, "lib/Proxy")
    local Tunnel = module(resource, "lib/Tunnel")
    framezero.Vrp.server = Proxy.getInterface("vRP")
    framezero.Vrp.client = Tunnel.getInterface("vRP")
    return true
end
