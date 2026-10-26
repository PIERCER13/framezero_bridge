-- Este arquivo nunca é substituído pelas atualizações da bridge.
-- Funções: Notify · Progress · ShowText · HideText · AddSphere
-- AddModel · RemoveTarget · TriggerCallback · OnPlayerLoaded


-- Target próprio
-- Usa o seu sistema de interação em todos os scripts FrameZero.
-- Com isto definido, Config.Target "auto" já escolhe o seu.
--
-- options = lista de { label, icon, distance, onSelect = function(entity) end, canInteract = function(entity) end }
--
-- framezero.CustomTarget = {
--     addSphere = function(id, coords, radius, options)
--         for i, opt in ipairs(options) do
--             exports["meu_target"]:AddZone(id .. ":" .. i, coords, radius, opt.label, opt.icon, function()
--                 opt.onSelect(nil)
--             end)
--         end
--     end,
--
--     addModel = function(id, models, options)
--         exports["meu_target"]:AddModels(id, models, options)
--     end,
--
--     remove = function(id)
--         exports["meu_target"]:Remove(id)
--     end,
-- }


-- Notificação própria
--
-- framezero.Custom.Notify = function(kind, message, duration)
--     exports["minha_notify"]:Show(kind, message, duration)
-- end


-- Barra de progresso própria
-- Precisa retornar true quando completar e false quando cancelar.
--
-- framezero.Custom.Progress = function(label, duration, opts)
--     return exports["meu_progress"]:Start(label, duration)
-- end
