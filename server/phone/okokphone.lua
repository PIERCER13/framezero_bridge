-- okokPhone

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

framezero.RegisterAdapter("phone", "okokPhone", {
    priority = 22,
    detect = function() return framezero.IsStarted("okokPhone") end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            if exports.okokPhone and exports.okokPhone.getPhoneNumber then
                return exports.okokPhone:getPhoneNumber(src)
            end
            return nil
        end, nil)
    end,

    sendMail = function(_number, data, src)
        return safe(function()
            local email = src and exports.okokPhone:getEmailAddressFromSource(src)
            if email then
                exports.okokPhone:sendEmail({
                    sender = data.sender or Config.PhoneSender or "FrameZero",
                    recipients = { email },
                    subject = data.subject or "Notificação",
                    body = data.message,
                })
                return true
            end
            return false
        end, false)
    end,
})
