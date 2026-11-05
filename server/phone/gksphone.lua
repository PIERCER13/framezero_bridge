-- gksphone / gks-phone

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

local getRes = function()
    return framezero.IsStarted("gksphone") and "gksphone" or "gks-phone"
end

framezero.RegisterAdapter("phone", "gksphone", {
    priority = 22,
    detect = function()
        return framezero.IsStarted("gksphone") or framezero.IsStarted("gks-phone")
    end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            local res = getRes()
            if exports[res] and exports[res].GetPhoneNumber then
                return exports[res]:GetPhoneNumber(src)
            end
            return nil
        end, nil)
    end,

    sendMail = function(_number, data)
        return safe(function()
            local res = getRes()
            exports[res]:SendNewMail({
                sender = data.sender or Config.PhoneSender or "FrameZero",
                image = "/html/static/img/icons/mail.png",
                subject = data.subject or "Notificação",
                message = data.message,
            })
            return true
        end, false)
    end,
})
