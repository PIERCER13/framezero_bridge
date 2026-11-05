-- roadphone

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

framezero.RegisterAdapter("phone", "roadphone", {
    priority = 22,
    detect = function() return framezero.IsStarted("roadphone") end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            if exports["roadphone"] and exports["roadphone"].getNumber then
                return exports["roadphone"]:getNumber(src)
            end
            return nil
        end, nil)
    end,

    sendMail = function(_number, data)
        return safe(function()
            exports["roadphone"]:sendMail({
                sender = data.sender or Config.PhoneSender or "FrameZero",
                subject = data.subject or "Notificação",
                message = data.message,
            })
            return true
        end, false)
    end,
})
