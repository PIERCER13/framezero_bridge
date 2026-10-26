-- framezero_bridge / config.lua
-- Na maioria dos servidores nada aqui precisa ser alterado:
-- a bridge detecta framework, inventário e garagem sozinha.

Config = {}

Config.Locale = "pt-br"         -- pt-br · en · es
Config.Debug  = false           -- mostra no console qual adaptador atendeu cada chamada

-- Atualizações
-- URL que responde {"version":"1.0.0"}. Vazio = não verifica.
Config.UpdateCheck = true
Config.UpdateUrl   = ""

-- Detecção
-- "auto" escolhe pelo que está rodando no servidor.
-- Coloque o nome para forçar um adaptador.
Config.Framework = "auto"       -- auto · esx · qbcore · qbox · vrp · tnet · ndcore · oxcore · standalone
Config.Inventory = "auto"       -- auto · framework · ox_inventory · qs-inventory · tnet_inventory · codem-inventory · core_inventory · ak47_inventory
Config.Vehicles  = "auto"       -- auto · framework · nation-garages · qbx_vehicles
Config.Notify    = "auto"       -- auto · framework · ox_lib · okokNotify · mythic_notify
Config.Target    = "auto"       -- auto · ox_target · qb-target · custom (o seu, em custom/client.lua) · none
Config.Progress  = "auto"       -- auto · ox_lib · framezero

-- vRP · vRPex · Creative
-- A bridge lê os arquivos do vrp para descobrir quais funções existem
-- (getUserId, Passport, HasGroup...). Funciona em bases modificadas.
Config.Vrp = {
    Resource    = "vrp",
    NotifyStyle = "auto",       -- auto · vrpex ("sucesso") · creative ("verde") · enchanted (título + cor)
    CashItem    = "dollars",    -- Creative guarda o dinheiro como item
}

-- Dinheiro sujo
-- Conta (ESX) ou item (demais frameworks)
Config.DirtyMoney = {
    esx    = { account = "black_money" },
    qbcore = { item = "markedbills" },
    qbox   = { item = "markedbills" },
    vrp    = { item = "dinheirosujo" },
}

-- Veículos
-- Usado quando nenhum sistema de garagem é detectado
Config.VehicleDefaults = {
    Garage      = "pillboxgarage",  -- QBCore · Qbox
    Type        = "car",            -- ESX
    PlatePrefix = "",               -- ex.: "FZ" → FZ123456
    PlateLength = 8,
}

-- Interface
Config.Keys = {
    Accept   = "Y",
    Decline  = "N",
    Interact = 38,              -- E (target sem ox_target/qb-target)
}

-- Segurança
-- Chamadas cliente → servidor por jogador, por segundo
Config.CallbackRateLimit = 20
