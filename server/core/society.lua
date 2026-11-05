-- Módulo de Contas de Sociedades / Empresas / Facções (SocietyMoney)
-- Compatível com Renewed-Banking, qb-banking, qb-management, esx_addonaccount e vRP/Creative.

framezero = framezero or {}
framezero.Society = framezero.Society or {}

local function cleanJob(society)
    if type(society) ~= "string" then return "" end
    return society:gsub("^society_", "")
end

local function esxShared(name)
    local p, done = promise.new(), false
    local function finish(v)
        if done then return end
        done = true
        p:resolve(v)
    end
    TriggerEvent("esx_addonaccount:getSharedAccount", name, function(acc) finish(acc or false) end)
    SetTimeout(3000, function() finish(false) end)
    return Citizen.Await(p) or nil
end

function framezero.Society.GetMoney(society)
    local job = cleanJob(society)
    if job == "" then return 0 end

    -- 1. Renewed-Banking
    if framezero.IsStarted("Renewed-Banking") and exports["Renewed-Banking"].getAccountMoney then
        local ok, money = pcall(function() return exports["Renewed-Banking"]:getAccountMoney(job) end)
        if ok and money then return tonumber(money) or 0 end
    end

    -- 2. qb-banking
    if framezero.IsStarted("qb-banking") and exports["qb-banking"].GetAccountBalance then
        local ok, money = pcall(function() return exports["qb-banking"]:GetAccountBalance(job) end)
        if ok and money then return tonumber(money) or 0 end
    end

    -- 3. qb-management
    if framezero.IsStarted("qb-management") and exports["qb-management"].GetAccount then
        local ok, money = pcall(function() return exports["qb-management"]:GetAccount(job) end)
        if ok and money then return tonumber(money) or 0 end
    end

    -- 4. esx_addonaccount
    if framezero.IsStarted("esx_addonaccount") then
        local acc = esxShared("society_" .. job)
        if acc and acc.money then return tonumber(acc.money) or 0 end
    end

    -- 5. vRP / Creative (consulta banco ou srv_data)
    local balance = framezero.DB.Scalar("SELECT money FROM society_money WHERE society = ? LIMIT 1", { job })
    if balance then return tonumber(balance) or 0 end

    return 0
end

function framezero.Society.AddMoney(society, amount, reason)
    amount = framezero.PositiveInt(amount)
    if not amount or amount <= 0 then return false end
    local job = cleanJob(society)
    if job == "" then return false end

    -- 1. Renewed-Banking
    if framezero.IsStarted("Renewed-Banking") and exports["Renewed-Banking"].addAccountMoney then
        local ok, res = pcall(function() return exports["Renewed-Banking"]:addAccountMoney(job, amount) ~= false end)
        if ok and res then return true end
    end

    -- 2. qb-banking
    if framezero.IsStarted("qb-banking") and exports["qb-banking"].AddMoney then
        local ok, res = pcall(function() return exports["qb-banking"]:AddMoney(job, amount, reason or "FrameZero") ~= false end)
        if ok and res then return true end
    end

    -- 3. qb-management
    if framezero.IsStarted("qb-management") and exports["qb-management"].AddMoney then
        local ok, res = pcall(function() return exports["qb-management"]:AddMoney(job, amount) ~= false end)
        if ok and res then return true end
    end

    -- 4. esx_addonaccount
    if framezero.IsStarted("esx_addonaccount") then
        local acc = esxShared("society_" .. job)
        if acc and acc.addMoney then
            acc.addMoney(amount)
            return true
        end
    end

    -- 5. Fallback vRP / banco
    framezero.DB.Execute([[
        INSERT INTO society_money (society, money) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE money = money + VALUES(money)
    ]], { job, amount })
    return true
end

function framezero.Society.RemoveMoney(society, amount, reason)
    amount = framezero.PositiveInt(amount)
    if not amount or amount <= 0 then return false end
    local job = cleanJob(society)
    if job == "" then return false end

    -- Verifica saldo prévio para nunca negativar
    local current = framezero.Society.GetMoney(society)
    if current < amount then return false end

    -- 1. Renewed-Banking
    if framezero.IsStarted("Renewed-Banking") and exports["Renewed-Banking"].removeAccountMoney then
        local ok, res = pcall(function() return exports["Renewed-Banking"]:removeAccountMoney(job, amount) == true end)
        if ok and res then return true end
    end

    -- 2. qb-banking
    if framezero.IsStarted("qb-banking") and exports["qb-banking"].RemoveMoney then
        local ok, res = pcall(function() return exports["qb-banking"]:RemoveMoney(job, amount, reason or "FrameZero") == true end)
        if ok and res then return true end
    end

    -- 3. qb-management
    if framezero.IsStarted("qb-management") and exports["qb-management"].RemoveMoney then
        local ok, res = pcall(function() return exports["qb-management"]:RemoveMoney(job, amount) == true end)
        if ok and res then return true end
    end

    -- 4. esx_addonaccount
    if framezero.IsStarted("esx_addonaccount") then
        local acc = esxShared("society_" .. job)
        if acc and acc.removeMoney then
            acc.removeMoney(amount)
            return true
        end
    end

    -- 5. Fallback vRP / banco
    framezero.DB.Execute("UPDATE society_money SET money = money - ? WHERE society = ? AND money >= ?", { amount, job, amount })
    return true
end
