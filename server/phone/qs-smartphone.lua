-- qs-smartphone & qs-smartphone-pro (Quasar Store)

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

local isPro = function() return framezero.IsStarted("qs-smartphone-pro") end
local resourceName = function() return isPro() and "qs-smartphone-pro" or "qs-smartphone" end

framezero.RegisterAdapter("phone", "qs-smartphone", {
    priority = 25,
    detect = function()
        return framezero.IsStarted("qs-smartphone") or framezero.IsStarted("qs-smartphone-pro")
    end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            local res = resourceName()
            if exports[res] and exports[res].GetPhoneNumber then
                return exports[res]:GetPhoneNumber(src)
            end
            local framework = framezero.Active.framework
            if framework and framework.name == "qbcore" then
                local QB = exports["qb-core"]:GetCoreObject()
                local p = QB.Functions.GetPlayer(src)
                return p and p.PlayerData and p.PlayerData.charinfo and p.PlayerData.charinfo.phone
            end
            return nil
        end, nil)
    end,

    sendMail = function(number, data)
        return safe(function()
            local mailData = {
                sender = data.sender or Config.PhoneSender or "FrameZero",
                subject = data.subject or "Notificação",
                message = data.message,
                button = {},
            }
            if isPro() then
                TriggerEvent("phone:sendNewMail", mailData)
            else
                TriggerEvent("qs-smartphone:server:sendNewMail", mailData)
            end
            return true
        end, false)
    end,

    sendMessage = function(number, message, sender, src)
        return safe(function()
            local res = resourceName()
            if exports[res] and exports[res].SendPhoneMessage then
                exports[res]:SendPhoneMessage(number, message)
                return true
            end
            return false
        end, false)
    end,
})
