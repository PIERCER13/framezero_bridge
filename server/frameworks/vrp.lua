-- Um adaptador só para toda a família vRP. Cada operação tem uma
-- lista de nomes possíveis; vale o primeiro que existe nesta base
-- (ver server/core/vrp.lua).

local vRP, vRPclient
local fn = {}       -- operação → nome da função nesta base
local flavor

-- Nomes conhecidos de cada operação, do vRP clássico ao Creative mais novo
local NAMES = {
    id         = { "getUserId", "Passport" },
    source     = { "getUserSource", "userSource", "Source" },
    users      = { "getUsers", "userList", "Players" },
    identity   = { "getUserIdentity", "userIdentity", "Identity" },
    permission = { "hasPermission", "HasPermission", "HasGroup", "hasGroup" },
    jobGroup   = { "getUserGroupByType" },
    itemAmount = { "getInventoryItemAmount", "itemAmount", "ItemAmount", "InventoryItemAmount" },
    takeItem   = { "tryGetInventoryItem", "TakeItem", "RemoveItem" },
    giveItem   = { "giveInventoryItem", "GiveItem", "GenerateItem" },
    inventory  = { "getInventory", "userInventory", "Inventory" },
    weight     = { "getInventoryWeight", "inventoryWeight", "InventoryWeight" },
    maxWeight  = { "getInventoryMaxWeight", "getWeight", "GetWeight" },
    itemWeight = { "getItemWeight", "itemWeight", "ItemWeight" },
    itemName   = { "itemNameList", "getItemName", "itemName", "ItemName" },
    getMoney   = { "getMoney" },
    pay        = { "tryPayment", "paymentFull", "PaymentFull" },
    giveMoney  = { "giveMoney" },
    getBank    = { "getBankMoney", "GetBank", "getBank" },
    giveBank   = { "giveBankMoney", "GiveBank", "addBank" },
    setBank    = { "setBankMoney" },
    payBank    = { "tryWithdraw", "PaymentBank", "paymentBank" },
    revive     = { "Revive" },
}

local warned = {}
local function call(op, ...)
    local name = fn[op]
    if not name then
        if not warned[op] then
            warned[op] = true
            framezero.Log("warn", framezero.L("vrp_function_missing"), table.concat(NAMES[op] or { op }, " / "))
        end
        return nil
    end
    return vRP[name](...)
end

local function uid(src)
    return call("id", src)
end

-- Algumas bases devolvem a quantidade como tabela { quantidade, nome_completo }
local function amountOf(value)
    if type(value) == "table" then return tonumber(value[1] or value.amount) or 0 end
    return tonumber(value) or 0
end

local cashIsItem = function() return fn.getMoney == nil end

framezero.RegisterAdapter("framework", "vrp", {
    priority = 10,

    detect = function()
        return framezero.IsStarted(Config.Vrp.Resource)
    end,

    init = function()
        if not framezero.Vrp.Load() then return false end
        vRP, vRPclient = framezero.Vrp.server, framezero.Vrp.client
        for op, names in pairs(NAMES) do fn[op] = framezero.Vrp.Pick(table.unpack(names)) end
        flavor = framezero.Vrp.Flavor()
        framezero.Log("info", framezero.L("vrp_flavor"), flavor, framezero.Vrp.Count())

        -- vRP · vRPex
        AddEventHandler("vRP:playerSpawn", function(_, src, first) if first then framezero.Internal.PlayerLoaded(src) end end)
        AddEventHandler("vRP:playerLeave", function(_, src) framezero.Internal.PlayerUnloaded(src) end)
        -- Creative
        AddEventHandler("Connect", function(_, src) framezero.Internal.PlayerLoaded(src) end)
        AddEventHandler("Disconnect", function(_, src) framezero.Internal.PlayerUnloaded(src) end)
        return fn.id ~= nil
    end,

    flavor = function() return flavor end,
    -- Qual função da base atende cada operação (aparece no framezero.Info(), ajuda no suporte)
    functions = function() return fn end,

    -- Jogador
    getId = function(src)
        local id = uid(src)
        return id and tostring(id) or nil
    end,

    getSource = function(id)
        return call("source", tonumber(id))
    end,

    getPlayers = function()
        local list = {}
        for _, src in pairs(call("users") or {}) do
            if type(src) == "number" then list[#list + 1] = src end
        end
        return list
    end,

    getName = function(src)
        local identity = call("identity", uid(src))
        if type(identity) ~= "table" then return GetPlayerName(src) end
        local first = identity.name or identity.Name or ""
        local last = identity.firstname or identity.name2 or identity.Lastname or identity.lastname or ""
        return framezero.Trim(first .. " " .. last)
    end,

    hasPermission = function(src, permission)
        return call("permission", uid(src), permission) == true
    end,

    getJob = function(src)
        local group = fn.jobGroup and call("jobGroup", uid(src), "job")
        if not group or group == "" then return nil end
        return { name = group, label = group, grade = 0, onDuty = true }
    end,

    -- Dinheiro
    -- Creative guarda a carteira como item (Config.Vrp.CashItem)

    getMoney = function(src, acc)
        local id = uid(src)
        if acc == "bank" then return tonumber(call("getBank", id)) or 0 end
        if cashIsItem() then return amountOf(call("itemAmount", id, Config.Vrp.CashItem)) end
        return tonumber(call("getMoney", id)) or 0
    end,

    addMoney = function(src, amount, acc)
        local id = uid(src)
        if acc == "bank" then
            if fn.giveBank then call("giveBank", id, amount) return true end
            if fn.setBank then call("setBank", id, (tonumber(call("getBank", id)) or 0) + amount) return true end
            return false
        end
        if cashIsItem() then call("giveItem", id, Config.Vrp.CashItem, amount, true) return true end
        call("giveMoney", id, amount)
        return true
    end,

    removeMoney = function(src, amount, acc)
        local id = uid(src)
        if acc == "bank" then
            if fn.payBank then return call("payBank", id, amount) == true end
            local balance = tonumber(call("getBank", id)) or 0
            if balance < amount or not fn.setBank then return false end
            call("setBank", id, balance - amount)
            return true
        end
        if cashIsItem() then return call("takeItem", id, Config.Vrp.CashItem, amount, true) == true end
        return call("pay", id, amount) == true
    end,

    -- Itens
    getItemCount = function(src, item)
        return amountOf(call("itemAmount", uid(src), item))
    end,

    canCarry = function(src, item, amount)
        local id = uid(src)
        if not fn.weight or not fn.maxWeight or not fn.itemWeight then return id ~= nil end
        local weight = tonumber(call("weight", id)) or 0
        local max = tonumber(call("maxWeight", id)) or 0
        local each = tonumber(call("itemWeight", item)) or 0
        return weight + each * amount <= max
    end,

    addItem = function(src, item, amount)
        local id = uid(src)
        if not id then return false end
        local result = call("giveItem", id, item, amount, true)
        return result ~= false
    end,

    removeItem = function(src, item, amount)
        return call("takeItem", uid(src), item, amount, true) == true
    end,

    getInventory = function(src)
        local list = {}
        for key, it in pairs(call("inventory", uid(src)) or {}) do
            if type(it) == "table" then
                local name = it.item or it.name or key
                local amount = tonumber(it.amount or it.count) or 0
                if amount > 0 then
                    list[#list + 1] = { name = name, amount = amount, slot = tonumber(key), metadata = it.metadata }
                end
            end
        end
        return list
    end,

    getItemLabel = function(item)
        return (fn.itemName and call("itemName", item)) or item
    end,

    getItemWeight = function(item)
        return tonumber(fn.itemWeight and call("itemWeight", item)) or 0
    end,

    -- Veículos
    -- Sem sistema de garagem detectado: grava na tabela de veículos da
    -- base, descobrindo as colunas (vrp_user_vehicles · vehicles).

    giveVehicle = function(id, model, plate)
        for _, tableName in ipairs({ "vrp_user_vehicles", "vehicles" }) do
            if framezero.DB.TableExists(tableName) then
                local cols = framezero.DB.Columns(tableName)
                local idCol = (cols.user_id and "user_id") or (cols.Passport and "Passport") or (cols.passport and "passport")
                local modelCol = (cols.vehicle and "vehicle") or (cols.model and "model")
                local plateCol = (cols.plate and "plate") or (cols.vehicle_plate and "vehicle_plate")
                if idCol and modelCol then
                    local columns, values = { idCol, modelCol }, { tonumber(id) or id, model }
                    if plateCol then columns[3], values[3] = plateCol, plate end
                    local marks = ("?, "):rep(#columns):sub(1, -3)
                    framezero.DB.Insert(("INSERT INTO `%s` (%s) VALUES (%s)"):format(tableName, table.concat(columns, ", "), marks), values)
                    return true
                end
            end
        end
        return false
    end,

    hasVehicle = function(id, model)
        for _, tableName in ipairs({ "vrp_user_vehicles", "vehicles" }) do
            if framezero.DB.TableExists(tableName) then
                local cols = framezero.DB.Columns(tableName)
                local idCol = (cols.user_id and "user_id") or (cols.Passport and "Passport") or (cols.passport and "passport")
                local modelCol = (cols.vehicle and "vehicle") or (cols.model and "model")
                if idCol and modelCol then
                    local sql = ("SELECT 1 FROM `%s` WHERE %s = ? AND %s = ? LIMIT 1"):format(tableName, idCol, modelCol)
                    return framezero.DB.Scalar(sql, { tonumber(id) or id, model }) ~= nil
                end
            end
        end
        return false
    end,

    -- Interface
    notify = function(src, kind, message, duration)
        local style = Config.Vrp.NotifyStyle
        if style == "auto" then style = flavor == "vrpex" and "vrpex" or "creative" end

        if style == "vrpex" then
            local names = { success = "sucesso", error = "negado", warning = "aviso", info = "importante" }
            TriggerClientEvent("Notify", src, names[kind], message, duration)
        elseif style == "enchanted" then
            local colors = { success = "verde", error = "vermelho", warning = "amarelo", info = "azul" }
            TriggerClientEvent("Notify", src, "Notificação", message, colors[kind], duration)
        else
            local colors = { success = "verde", error = "vermelho", warning = "amarelo", info = "azul" }
            TriggerClientEvent("Notify", src, colors[kind], message, duration)
        end
    end,

    revive = function(src, health)
        if fn.revive then
            vRP[fn.revive](src, health or 400)
        elseif flavor == "creative" then
            vRPclient.revivePlayer(src, health or 400)
        else
            vRPclient.killGod(src)
            vRPclient.setHealth(src, health or 400)
        end
    end,
})
