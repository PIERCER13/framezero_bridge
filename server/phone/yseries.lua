-- yseries & yflip-phone

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

local isFlip = function() return framezero.IsStarted("yflip-phone") end

framezero.RegisterAdapter("phone", "yseries", {
    priority = 24,
    detect = function()
        return framezero.IsStarted("yseries") or framezero.IsStarted("yflip-phone")
    end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            if isFlip() then
                local id = framezero.API.GetPlayerId(src)
                return exports["yflip-phone"]:GetPhoneNumberByIdentifier(id)
            end
            if exports["yseries"] and exports["yseries"].GetPhoneNumber then
                return exports["yseries"]:GetPhoneNumber(src)
            end
            return nil
        end, nil)
    end,

    sendMail = function(number, data, src)
        return safe(function()
            if isFlip() then
                exports["yflip-phone"]:SendMail({
                    title = data.subject or "Notificação",
                    sender = "system",
                    senderDisplayName = data.sender or Config.PhoneSender or "FrameZero",
                    content = data.message,
                }, "phoneNumber", number)
                return true
            end
            if exports["yseries"] then
                local mail = {
                    title = data.subject or "Notificação",
                    sender = "system@framezero.local",
                    senderDisplayName = data.sender or Config.PhoneSender or "FrameZero",
                    content = data.message,
                    actions = {},
                    attachments = {},
                }
                if src then
                    exports["yseries"]:SendMail(mail, "source", src)
                else
                    exports["yseries"]:SendMail(mail, "phoneNumber", number)
                end
                return true
            end
            return false
        end, false)
    end,
})
