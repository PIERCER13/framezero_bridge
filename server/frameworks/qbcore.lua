-- framezero_bridge / server/frameworks/qbcore.lua (QBCore e Qbox)
-- O Qbox expõe a mesma API de jogador do QBCore. As diferenças
-- (grupos, inventário ox, qbx_vehicles) ficam no adaptador "qbox".

local function build(name, priority, resource, getCore)
    local Core

    local function player(src)
        return Core and Core.Functions.GetPlayer(src)
    end

    local adapter = {
        priority = priority,

        detect = function()
            return FZ.IsStarted(resource)
        end,

        init = function()
            Core = getCore()
            AddEventHandler("QBCore:Server:PlayerLoaded", function(p)
                if p and p.PlayerData then FZ.Internal.PlayerLoaded(p.PlayerData.source) end
            end)
            AddEventHandler("QBCore:Server:OnPlayerUnload", function(src) FZ.Internal.PlayerUnloaded(src) end)
            return Core ~= nil
        end,

        -- Jogador
        getId = function(src)
            local p = player(src)
            return p and p.PlayerData.citizenid
        end,

        getSource = function(id)
            local p = Core.Functions.GetPlayerByCitizenId(id)
            return p and p.PlayerData.source
        end,

        getPlayers = function()
            return Core.Functions.GetPlayers()
        end,

        getName = function(src)
            local p = player(src)
            if not p then return nil end
            local info = p.PlayerData.charinfo or {}
            return FZ.Trim(("%s %s"):format(info.firstname or "", info.lastname or ""))
        end,

        hasPermission = function(src, permission)
            if IsPlayerAceAllowed(src, permission) then return true end
            if Core.Functions.HasPermission and Core.Functions.HasPermission(src, permission) then return true end
            local p = player(src)
            if not p then return false end
            local data = p.PlayerData
            return (data.job and data.job.name == permission) or (data.gang and data.gang.name == permission) or false
        end,

        getJob = function(src)
            local p = player(src)
            local job = p and p.PlayerData.job
            if not job then return nil end
            return {
                name = job.name,
                label = job.label,
                grade = job.grade and job.grade.level or 0,
                gradeLabel = job.grade and job.grade.name,
                onDuty = job.onduty ~= false,
            }
        end,

        -- Dinheiro
        getMoney = function(src, acc)
            local p = player(src)
            return p and p.PlayerData.money[acc] or 0
        end,

        addMoney = function(src, amount, acc)
            local p = player(src)
            return p ~= nil and p.Functions.AddMoney(acc, amount, "framezero") ~= false
        end,

        removeMoney = function(src, amount, acc)
            local p = player(src)
            return p ~= nil and p.Functions.RemoveMoney(acc, amount, "framezero") == true
        end,

        -- Itens (qb-inventory e compatíveis)
        getItemCount = function(src, item)
            local p = player(src)
            if not p then return 0 end
            local total = 0
            for _, it in pairs(p.PlayerData.items or {}) do
                if it and it.name == item then total = total + (it.amount or it.count or 0) end
            end
            return total
        end,

        canCarry = function(src, item, amount)
            if FZ.IsStarted("qb-inventory") then
                local ok, can = pcall(function() return exports["qb-inventory"]:CanAddItem(src, item, amount) end)
                if ok then return can == true end
            end
            return player(src) ~= nil
        end,

        addItem = function(src, item, amount, metadata)
            local p = player(src)
            if not p then return false end
            local added = p.Functions.AddItem(item, amount, nil, metadata)
            if added and Core.Shared.Items[item] then
                TriggerClientEvent("inventory:client:ItemBox", src, Core.Shared.Items[item], "add", amount)
            end
            return added == true
        end,

        removeItem = function(src, item, amount)
            local p = player(src)
            if not p then return false end
            local removed = p.Functions.RemoveItem(item, amount)
            if removed and Core.Shared.Items[item] then
                TriggerClientEvent("inventory:client:ItemBox", src, Core.Shared.Items[item], "remove", amount)
            end
            return removed == true
        end,

        getInventory = function(src)
            local p = player(src)
            local list = {}
            for _, it in pairs(p and p.PlayerData.items or {}) do
                if it and it.name then
                    list[#list + 1] = {
                        name = it.name, label = it.label, amount = it.amount or it.count or 0,
                        slot = it.slot, metadata = it.info, weight = it.weight,
                    }
                end
            end
            return list
        end,

        getItemLabel = function(item)
            local data = Core.Shared.Items[item]
            return data and data.label or item
        end,

        getItemWeight = function(item)
            local data = Core.Shared.Items[item]
            return data and data.weight or 0
        end,

        -- Veículos (tabela player_vehicles)
        giveVehicle = function(id, model, plate, opts)
            local license = FZ.DB.Scalar("SELECT license FROM players WHERE citizenid = ?", { id })
            FZ.DB.Insert(
                "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, '{}', ?, ?, 1)",
                { license, id, model, GetHashKey(model), plate, opts.garage or Config.VehicleDefaults.Garage }
            )
            return true
        end,

        hasVehicle = function(id, model)
            return FZ.DB.Scalar("SELECT 1 FROM player_vehicles WHERE citizenid = ? AND vehicle = ? LIMIT 1", { id, model }) ~= nil
        end,

        plateExists = function(plate)
            return FZ.DB.Scalar("SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1", { plate }) ~= nil
        end,

        -- Interface
        notify = function(src, kind, message, duration)
            TriggerClientEvent("QBCore:Notify", src, message, kind == "info" and "primary" or kind, duration)
        end,

        revive = function(src)
            TriggerClientEvent("hospital:client:Revive", src)
        end,
    }

    FZ.RegisterAdapter("framework", name, adapter)
    return adapter
end

build("qbcore", 20, "qb-core", function()
    local ok, core = pcall(function() return exports["qb-core"]:GetCoreObject() end)
    if ok and core then return core end
    -- QBCore antigo: objeto só pelo evento
    TriggerEvent("QBCore:GetObject", function(obj) core = obj end)
    return core
end)

-- Qbox
-- Prioridade maior: o qbx_core também responde como qb-core.

local qbox = build("qbox", 40, "qbx_core", function()
    -- O Qbox mantém a API do jogador do QBCore pela camada de compatibilidade (qb-core)
    local ok, core = pcall(function() return exports["qb-core"]:GetCoreObject() end)
    return ok and core or nil
end)

qbox.hasPermission = function(src, permission)
    if IsPlayerAceAllowed(src, permission) then return true end
    local ok, has = pcall(function() return exports.qbx_core:HasGroup(src, permission) end)
    return ok and has == true
end

qbox.notify = function(src, kind, message, duration)
    exports.qbx_core:Notify(src, message, kind, duration)
end
