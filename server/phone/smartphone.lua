-- smartphone (jesters-lab) — o celular usado no servidor STYLE.
--
-- O smartphone NÃO expõe export de número do telefone nem app de e-mail, então
-- getNumber/sendMail ficam "não suportados" (a API avisa uma vez). O que ele
-- oferece e usamos aqui é o SMS: o servidor dispara o evento do próprio
-- smartphone no client do jogador:  TriggerClientEvent('smartphone:createSMS', src, sender, msg)
--
-- Outros recursos do smartphone (WhatsApp, PayPal, faturas, Tor) têm exports de
-- servidor próprios e os scripts podem chamá-los direto, ex.:
--   exports.smartphone:createWhatsappMessage(sender, target, content)
--   exports.smartphone:getPaypalBalance(user_id) / addPaypalBalance(user_id, v)
-- Esses são específicos do smartphone e ficam fora da API genérica de celular.

framezero.RegisterAdapter("phone", "smartphone", {
    priority = 20, -- abaixo do lb-phone (30)
    detect = function() return framezero.IsStarted("smartphone") end,
    init = function() return true end,

    -- SMS: criado no celular do jogador (precisa do source online).
    -- sender aparece como remetente do SMS (ex.: "0800" ou um nome curto).
    sendMessage = function(_number, message, sender, src)
        if not src then return false end -- sem source online não dá pra criar o SMS
        TriggerClientEvent("smartphone:createSMS", src, tostring(sender or "FrameZero"), tostring(message))
        return true
    end,

    -- getNumber / sendMail / notify: o smartphone não expõe export de servidor
    -- para isso. Se a jesters-lab adicionar, é só implementar aqui.
})
