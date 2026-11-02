-- Base modificada? Garagem, inventário ou dinheiro diferentes?
-- Sobrescreva aqui qualquer função da API. Este arquivo nunca é
-- substituído pelas atualizações da bridge.
--
-- Funções disponíveis: GetPlayerId · GetSource · GetPlayers · GetName
-- HasPermission · GetJob · GetMoney · AddMoney · RemoveMoney
-- GetItemCount · HasItem · AddItem · RemoveItem · CanCarry · GetInventory
-- GetItemLabel · GetItemWeight · GiveVehicle · HasVehicle · GeneratePlate
-- Notify · Prompt · Request · Revive
-- GetPhoneNumber · SendMail · SendMessage · PhoneNotify
-- (adaptadores de celular novos: ver server/phone/_custom.lua)
--
-- Para chamar a implementação original dentro da sua, use framezero.API
-- (ela consulta framezero.Custom, então cuidado com recursão) ou framezero.Call.


-- Exemplo: entregar veículo numa garagem própria
--
-- framezero.Custom.GiveVehicle = function(target, model, opts)
--     local id = framezero.API.GetPlayerId(target) or tostring(target)
--     local plate = (opts and opts.plate) or framezero.API.GeneratePlate()
--     exports["minha_garagem"]:AddVehicle(id, model, plate)
--     return plate
-- end


-- Exemplo: dinheiro sujo como item com outro nome
--
-- framezero.Custom.GetMoney = function(src, account)
--     if account == "dirty" then return framezero.API.GetItemCount(src, "dinheiro_sujo") end
--     return framezero.Call("framework", "getMoney", src, account or "cash")
-- end


-- Exemplo: notificação própria
--
-- framezero.Custom.Notify = function(src, kind, message, duration)
--     TriggerClientEvent("minha_notify:show", src, kind, message, duration)
-- end


-- ===== Integração opcional: smartphone + bank (jesters-lab) =====
-- Helpers que só ativam se as resources "smartphone"/"bank" estiverem rodando.
-- Em servidor que não as tenha, cada função apenas retorna nil/false (pcall +
-- checagem), então é seguro deixar aqui. Use nos scripts como framezero.X(...).
-- user_id = id do personagem no framework (use framezero.GetPlayerId(src)).

local function sm() return exports["smartphone"] end
local function bk() return exports["bank"] end
local function try(fn, fb) local ok, r = pcall(fn); if ok and r ~= nil then return r end; return fb end

-- SMS no celular do jogador (atalho; o mesmo que framezero.SendMessage por source)
function framezero.API.SendSMS(src, message, sender)
    if not framezero.IsStarted("smartphone") then return false end
    TriggerClientEvent("smartphone:createSMS", src, tostring(sender or "FrameZero"), tostring(message))
    return true
end

-- WhatsApp: mensagem de 'sender' (número) para 'target' (número)
function framezero.API.SendWhatsapp(sender, target, content)
    if not framezero.IsStarted("smartphone") then return false end
    return try(function() sm():createWhatsappMessage(tostring(sender), tostring(target), tostring(content)); return true end, false)
end

-- PayPal (por user_id)
function framezero.API.GetPaypal(userId)
    if not framezero.IsStarted("smartphone") then return 0 end
    return tonumber(try(function() return sm():getPaypalBalance(userId) end, 0)) or 0
end
function framezero.API.AddPaypal(userId, amount)
    if not framezero.IsStarted("smartphone") then return false end
    return try(function() sm():addPaypalBalance(userId, amount); return true end, false)
end
function framezero.API.RemovePaypal(userId, amount)
    if not framezero.IsStarted("smartphone") then return false end
    return try(function() sm():delPaypalBalance(userId, amount); return true end, false)
end

-- Multas (bank do Jester). Extras opcionais: expiracao, jurosPorDia, metadata (veja a doc do bank).
function framezero.API.CreateFine(userId, desc, amount, ...)
    if not framezero.IsStarted("bank") then return false end
    local extra, n = { ... }, select("#", ...)
    return try(function() bk():createFine(userId, tostring(desc), amount, table.unpack(extra, 1, n)); return true end, false)
end
-- Retorna: temMultas (bool), total (number)
function framezero.API.HasFines(userId)
    if not framezero.IsStarted("bank") then return false end
    local ok, has, total = pcall(function() return bk():hasFines(userId) end)
    if not ok then return false end
    return has, total
end

-- Extrato no bank: kind = "income" (entrada) ou "outcome" (saída)
function framezero.API.BankTransaction(userId, kind, amount, label)
    if not framezero.IsStarted("bank") then return false end
    return try(function() bk():createTransaction(userId, kind, amount, tostring(label)); return true end, false)
end
