-- framezero_bridge / server/frameworks/esx.lua (ESX Legacy)

local ESX
local ACCOUNTS = { cash = "money", bank = "bank", dirty = "black_money" }

local function player(src)
    return ESX and ESX.GetPlayerFromId(src)
end

local function account(name)
    return ACCOUNTS[name] or name
end

FZ.RegisterAdapter("framework", "esx", {
    priority = 30,

    detect = function()
        return FZ.IsStarted("es_extended")
    end,

    init = function()
        local ok, shared = pcall(function() return exports["es_extended"]:getSharedObject() end)
        ESX = ok and shared or nil
        if not ESX then TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end) end

        AddEventHandler("esx:playerLoaded", function(src) FZ.Internal.PlayerLoaded(src) end)
        AddEventHandler("esx:playerDropped", function(src) FZ.Internal.PlayerUnloaded(src) end)
        return ESX ~= nil
    end,

    -- Jogador
    getId = function(src)
        local p = player(src)
        return p and p.identifier
    end,

    getSource = function(id)
        local p = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(id)
        if p then return p.source end
        for _, src in ipairs(ESX.GetPlayers()) do
            local xp = ESX.GetPlayerFromId(src)
            if xp and xp.identifier == id then return src end
        end
    end,

    getPlayers = function()
        local list = {}
        if ESX.GetExtendedPlayers then
            for _, p in pairs(ESX.GetExtendedPlayers()) do list[#list + 1] = p.source end
        else
            for _, src in ipairs(ESX.GetPlayers()) do list[#list + 1] = src end
        end
        return list
    end,

    getName = function(src)
        local p = player(src)
        if not p then return nil end
        return (p.getName and p.getName()) or p.get("firstName") or GetPlayerName(src)
    end,

    hasPermission = function(src, permission)
        local p = player(src)
        if not p then return false end
        if p.getGroup and p.getGroup() == permission then return true end
        return p.job ~= nil and p.job.name == permission
    end,

    getJob = function(src)
        local p = player(src)
        if not p or not p.job then return nil end
        return {
            name = p.job.name,
            label = p.job.label,
            grade = p.job.grade,
            gradeLabel = p.job.grade_label,
            onDuty = p.job.onDuty ~= false,
        }
    end,

    -- Dinheiro
    -- ESX antigo (1.1/1.2) guarda a carteira fora das contas: usa getMoney/addMoney nesse caso
    getMoney = function(src, acc)
        local p = player(src)
        if not p then return 0 end
        local data = p.getAccount(account(acc))
        if data then return data.money end
        if acc == "cash" and p.getMoney then return p.getMoney() end
        return 0
    end,

    addMoney = function(src, amount, acc)
        local p = player(src)
        if not p then return false end
        if not p.getAccount(account(acc)) and acc == "cash" and p.addMoney then
            p.addMoney(amount)
            return true
        end
        p.addAccountMoney(account(acc), amount)
        return true
    end,

    removeMoney = function(src, amount, acc)
        local p = player(src)
        if not p then return false end
        local data = p.getAccount(account(acc))
        if not data and acc == "cash" and p.getMoney then
            if p.getMoney() < amount then return false end
            p.removeMoney(amount)
            return true
        end
        if not data or data.money < amount then return false end
        p.removeAccountMoney(account(acc), amount)
        return true
    end,

    -- Itens (inventário padrão do ESX)
    getItemCount = function(src, item)
        local p = player(src)
        local data = p and p.getInventoryItem(item)
        return data and data.count or 0
    end,

    canCarry = function(src, item, amount)
        local p = player(src)
        return p ~= nil and (not p.canCarryItem or p.canCarryItem(item, amount))
    end,

    addItem = function(src, item, amount, metadata)
        local p = player(src)
        if not p or (p.canCarryItem and not p.canCarryItem(item, amount)) then return false end
        p.addInventoryItem(item, amount, metadata)
        return true
    end,

    removeItem = function(src, item, amount)
        local p = player(src)
        local data = p and p.getInventoryItem(item)
        if not data or data.count < amount then return false end
        p.removeInventoryItem(item, amount)
        return true
    end,

    getInventory = function(src)
        local p = player(src)
        local list = {}
        for _, it in pairs(p and p.getInventory() or {}) do
            local amount = it.count or it.amount or 0
            if amount > 0 then
                list[#list + 1] = { name = it.name, label = it.label, amount = amount, weight = it.weight }
            end
        end
        return list
    end,

    getItemLabel = function(item)
        if ESX.GetItemLabel then return ESX.GetItemLabel(item) or item end
        return (ESX.Items and ESX.Items[item] and ESX.Items[item].label) or item
    end,

    getItemWeight = function(item)
        return ESX.Items and ESX.Items[item] and ESX.Items[item].weight or 0
    end,

    -- Veículos (tabela owned_vehicles)
    giveVehicle = function(id, model, plate, opts)
        FZ.DB.Insert("INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, 1)", {
            id, plate, json.encode({ model = GetHashKey(model), plate = plate }), opts.type or Config.VehicleDefaults.Type,
        })
        return true
    end,

    hasVehicle = function(id, model)
        local hash = GetHashKey(model)
        for _, row in ipairs(FZ.DB.Query("SELECT vehicle FROM owned_vehicles WHERE owner = ?", { id }) or {}) do
            local data = json.decode(row.vehicle or "{}") or {}
            if data.model == hash then return true end
        end
        return false
    end,

    plateExists = function(plate)
        return FZ.DB.Scalar("SELECT 1 FROM owned_vehicles WHERE plate = ? LIMIT 1", { plate }) ~= nil
    end,

    -- Interface
    notify = function(src, kind, message, duration)
        TriggerClientEvent("esx:showNotification", src, message, kind == "warning" and "info" or kind, duration)
    end,

    revive = function(src)
        TriggerClientEvent("esx_ambulancejob:revive", src)
    end,
})
