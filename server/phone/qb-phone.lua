-- qb-phone — número via qb-core (charinfo.phone).
-- OBS: o envio de e-mail do qb-phone é por SOURCE/evento e muda entre versões,
-- então não vem pronto aqui; se precisar, implemente sendMail em custom/server.lua.

local function safe(fn, fb)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return fb
end

framezero.RegisterAdapter("phone", "qb-phone", {
    priority = 10,
    detect = function() return framezero.IsStarted("qb-phone") end,
    init = function() return true end,

    getNumber = function(src)
        return safe(function()
            local QB = exports["qb-core"]:GetCoreObject()
            local p = QB.Functions.GetPlayer(src)
            return p and p.PlayerData and p.PlayerData.charinfo and p.PlayerData.charinfo.phone
        end, nil)
    end,
})
