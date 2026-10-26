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
