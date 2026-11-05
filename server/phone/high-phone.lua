-- high-phone

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

framezero.RegisterAdapter("phone", "high-phone", {
    priority = 22,
    detect = function() return framezero.IsStarted("high-phone") end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            if exports["high-phone"] and exports["high-phone"].getPlayerPhoneNumber then
                return exports["high-phone"]:getPlayerPhoneNumber(src)
            end
            return nil
        end, nil)
    end,

    sendMail = function(_number, data, src)
        return safe(function()
            local account = src and exports["high-phone"]:getPlayerMailAccount(src)
            if account and account.address then
                exports["high-phone"]:sendMail({
                    sender = data.sender or Config.PhoneSender or "FrameZero",
                    recipients = { account.address },
                    subject = data.subject or "Notificação",
                    content = data.message,
                    attachments = {},
                })
                return true
            end
            return false
        end, false)
    end,
})
