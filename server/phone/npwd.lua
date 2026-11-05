-- npwd

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

framezero.RegisterAdapter("phone", "npwd", {
    priority = 22,
    detect = function() return framezero.IsStarted("npwd") or framezero.IsStarted("npwd-phone") end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            if exports["npwd"] and exports["npwd"].getPhoneNumber then
                return exports["npwd"]:getPhoneNumber(src)
            end
            return nil
        end, nil)
    end,

    sendMail = function(_number, data)
        return safe(function()
            if exports["npwd"] and exports["npwd"].createNotification then
                exports["npwd"]:createNotification({
                    notisId = "npwd:emailNotification",
                    appId = "EMAIL",
                    content = data.message,
                    secondaryTitle = data.subject or "Email",
                    keepOpen = false,
                    duration = 5000,
                    path = "/email",
                })
                return true
            end
            return false
        end, false)
    end,
})
