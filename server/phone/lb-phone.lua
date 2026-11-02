-- lb-phone — usa as exports oficiais do servidor (GetEquippedPhoneNumber, SendMail).
-- https://docs.lbphone.com/

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

local lb = function() return exports["lb-phone"] end

framezero.RegisterAdapter("phone", "lb-phone", {
    priority = 30,
    detect = function() return framezero.IsStarted("lb-phone") end,
    init = function() return true end,

    -- Número do telefone que o jogador está usando no momento.
    getNumber = function(src)
        return safe(function() return lb():GetEquippedPhoneNumber(src) end, nil)
    end,

    -- E-mail no app Mail. data = { subject, message, sender }
    sendMail = function(number, data)
        return safe(function()
            local id = lb():SendMail({
                to      = number,
                sender  = data.sender,
                subject = data.subject,
                content = data.message,
            })
            return id ~= nil and id ~= false
        end, false)
    end,
})
