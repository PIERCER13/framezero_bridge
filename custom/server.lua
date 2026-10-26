-- framezero_bridge / custom/server.lua (ajustes do SEU servidor)
-- Base modificada? Garagem, inventário ou dinheiro diferentes?
-- Sobrescreva aqui qualquer função da API. Este arquivo nunca é
-- substituído pelas atualizações da bridge.
--
-- Funções disponíveis: GetPlayerId · GetSource · GetPlayers · GetName
-- HasPermission · GetJob · GetMoney · AddMoney · RemoveMoney
-- GetItemCount · HasItem · AddItem · RemoveItem · CanCarry · GetInventory
-- GetItemLabel · GetItemWeight · GiveVehicle · HasVehicle · GeneratePlate
-- Notify · Prompt · Request · Revive
--
-- Para chamar a implementação original dentro da sua, use FZ.API
-- (ela consulta FZ.Custom, então cuidado com recursão) ou FZ.Call.


-- Exemplo: entregar veículo numa garagem própria
--
-- FZ.Custom.GiveVehicle = function(target, model, opts)
--     local id = FZ.API.GetPlayerId(target) or tostring(target)
--     local plate = (opts and opts.plate) or FZ.API.GeneratePlate()
--     exports["minha_garagem"]:AddVehicle(id, model, plate)
--     return plate
-- end


-- Exemplo: dinheiro sujo como item com outro nome
--
-- FZ.Custom.GetMoney = function(src, account)
--     if account == "dirty" then return FZ.API.GetItemCount(src, "dinheiro_sujo") end
--     return FZ.Call("framework", "getMoney", src, account or "cash")
-- end


-- Exemplo: notificação própria
--
-- FZ.Custom.Notify = function(src, kind, message, duration)
--     TriggerClientEvent("minha_notify:show", src, kind, message, duration)
-- end
