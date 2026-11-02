-- smartphone (jesters-lab)

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

})
