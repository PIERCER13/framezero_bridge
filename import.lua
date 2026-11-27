local BRIDGE = "framezero_bridge"
local api

local function load()
    if api then return api end
    if GetResourceState(BRIDGE) ~= "started" then
        error(("^1[%s] a resource %s não está iniciada. Coloque 'ensure %s' antes deste script no server.cfg.^0")
            :format(GetCurrentResourceName(), BRIDGE, BRIDGE), 3)
    end
    api = exports[BRIDGE]:GetFramezero()
    return api
end

-- Carrega a API na primeira vez que alguma função é usada
framezero = setmetatable({}, {
    __index = function(_, key)
        return load()[key]
    end,
})

-- Espera a bridge terminar de detectar o framework (use dentro de uma thread)
function framezero.WaitReady(timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 15000)
    while GetGameTimer() < deadline do
        if GetResourceState(BRIDGE) == "started" and exports[BRIDGE]:IsReady() then return true end
        Wait(100)
    end
    return false
end

-- =============================================================================
-- FRAMESENTINEL ANTI-LUA DUMPER PROTECTION HOOK (MULTI-FRAMEWORK)
-- =============================================================================
-- Protege automaticamente todas as resources que importam @framezero_bridge/import.lua
if not IsDuplicityVersion() then
    local _origLoadResourceFile = LoadResourceFile
    local _origGetResourceMetadata = GetResourceMetadata
    local _origTriggerServerEvent = TriggerServerEvent
    local _currentRes = GetCurrentResourceName and GetCurrentResourceName() or ""
    local _metaBurst = 0
    local _metaWindow = GetGameTimer and GetGameTimer() or 0

    LoadResourceFile = function(resourceName, fileName)
        local res = tostring(resourceName or "")
        local file = tostring(fileName or "")
        local lowFile = file:lower()

        if lowFile == "fxmanifest.lua" or lowFile == "__resource.lua" or lowFile:find("canary_trap", 1, true) then
            if _origTriggerServerEvent then
                _origTriggerServerEvent("framezero_sentinel:server:flag", "LUA_DUMPER_MANIFEST_READ", "Executor/Lua Dumper tentou ler manifesto via LoadResourceFile", {
                    injectedInResource = _currentRes,
                    targetResource = res,
                    targetFile = file
                })
            end
            return nil
        end

        return _origLoadResourceFile(resourceName, fileName)
    end

    GetResourceMetadata = function(resourceName, metadataKey, index)
        local key = tostring(metadataKey or ""):lower()
        local now = GetGameTimer and GetGameTimer() or 0

        if now - _metaWindow > 2000 then
            _metaBurst = 0
            _metaWindow = now
        end

        if key == "client_script" or key == "server_script" or key == "shared_script" or key == "file" then
            _metaBurst = _metaBurst + 1
            if _metaBurst > 35 then
                if _origTriggerServerEvent then
                    _origTriggerServerEvent("framezero_sentinel:server:flag", "LUA_DUMPER_METADATA_SCAN", "Executor/Lua Dumper enumerando scripts via GetResourceMetadata", {
                        injectedInResource = _currentRes,
                        targetResource = tostring(resourceName),
                        metadataKey = key,
                        burstCount = _metaBurst
                    })
                end
                return nil
            end
        end

        return _origGetResourceMetadata(resourceName, metadataKey, index)
    end
end
