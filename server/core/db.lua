-- Usa os exports do driver (oxmysql · mysql-async · ghmattimysql),
-- então não depende de @oxmysql/lib no fxmanifest.
-- Parâmetros: use "?" (posicional) ou "@nome" (nomeado).

FZ.DB = { prepared = {} }

local driver

local function detectDriver()
    for _, name in ipairs({ "oxmysql", "mysql-async", "ghmattimysql" }) do
        if FZ.IsStarted(name) then return name end
    end
end

local function await(run)
    local p = promise.new()
    run(function(result) p:resolve(result) end)
    return Citizen.Await(p)
end

-- kind: query · single · scalar · insert · update
local function execute(kind, sql, params)
    driver = driver or detectDriver()
    sql = FZ.DB.prepared[sql] or sql
    params = params or {}

    if driver == "oxmysql" then
        local ox = exports.oxmysql
        return await(function(cb) ox[kind](ox, sql, params, cb) end)

    elseif driver == "mysql-async" then
        local my = exports["mysql-async"]
        if kind == "scalar" then return await(function(cb) my:mysql_fetch_scalar(sql, params, cb) end) end
        if kind == "insert" then return await(function(cb) my:mysql_insert(sql, params, cb) end) end
        if kind == "update" then return await(function(cb) my:mysql_execute(sql, params, cb) end) end
        local rows = await(function(cb) my:mysql_fetch_all(sql, params, cb) end)
        if kind == "single" then return rows and rows[1] end
        return rows

    elseif driver == "ghmattimysql" then
        local gh = exports.ghmattimysql
        if kind == "scalar" then return await(function(cb) gh:scalar(sql, params, cb) end) end
        local result = await(function(cb) gh:execute(sql, params, cb) end)
        if kind == "single" then return result and result[1] end
        if kind == "insert" then return result and result.insertId end
        if kind == "update" then return result and result.affectedRows end
        return result
    end

    FZ.Log("error", FZ.L("db_missing"))
    return nil
end

function FZ.DB.Prepare(name, sql) FZ.DB.prepared[name] = sql return true end
function FZ.DB.Query(sql, params)  return execute("query", sql, params) end
function FZ.DB.Single(sql, params) return execute("single", sql, params) end
function FZ.DB.Scalar(sql, params) return execute("scalar", sql, params) end
function FZ.DB.Insert(sql, params) return execute("insert", sql, params) end
function FZ.DB.Update(sql, params) return execute("update", sql, params) end

-- Colunas de uma tabela (cache), usado para gravar em tabelas que variam entre bases.
local columnsCache = {}
function FZ.DB.Columns(tableName)
    if columnsCache[tableName] == nil then
        local rows = FZ.DB.Query(("SHOW COLUMNS FROM `%s`"):format(tableName:gsub("[^%w_]", ""))) or {}
        local set = {}
        for _, row in ipairs(rows) do set[row.Field] = true end
        columnsCache[tableName] = set
    end
    return columnsCache[tableName]
end

function FZ.DB.TableExists(tableName)
    local row = FZ.DB.Single("SHOW TABLES LIKE ?", { tableName })
    return row ~= nil
end
