-- Catálogo unificado de Minigames & Hacks do FrameZero
-- Suporta mais de 30 minigames populares da comunidade FiveM.
-- Permite chamada com callback ou síncrona dentro de thread/corrotina:
--   local sucesso = framezero.Minigame("ps-circle", 2, 10)
--   framezero.Minigame("ps-circle", function(sucesso) ... end, 2, 10)

framezero = framezero or {}
framezero.Minigame = framezero.Minigame or {}

local GAMES = {
    -- ps-ui
    ["ps-circle"]    = function(cb, ...) exports["ps-ui"]:Circle(cb, ...) end,
    ["ps-maze"]      = function(cb, ...) exports["ps-ui"]:Maze(cb, ...) end,
    ["ps-varhack"]   = function(cb, ...) exports["ps-ui"]:VarHack(cb, ...) end,
    ["ps-thermite"]  = function(cb, ...) exports["ps-ui"]:Thermite(cb, ...) end,
    ["ps-scrambler"] = function(cb, ...) exports["ps-ui"]:Scrambler(cb, ...) end,

    -- memorygame
    ["memorygame-thermite"] = function(cb, blocks, incorrect, timeShow, timeLose)
        exports["memorygame"]:thermiteminigame(blocks or 10, incorrect or 3, timeShow or 7, timeLose or 10,
            function() cb(true) end,
            function() cb(false) end
        )
    end,

    -- ran-minigames
    ["ran-memorycard"]   = function(cb, ...) cb(exports["ran-minigames"]:MemoryCard(...)) end,
    ["ran-openterminal"] = function(cb, ...) cb(exports["ran-minigames"]:OpenTerminal(...)) end,

    -- hacking
    ["hacking-opengame"] = function(cb, duration, length, amount)
        exports["hacking"]:OpenHackingGame(duration or 30, length or 4, amount or 2, function(success) cb(success == true) end)
    end,

    -- howdy-hackminigame
    ["howdy-begin"] = function(cb, ...) cb(exports["howdy-hackminigame"]:Begin(...)) end,

    -- SN-Hacking
    ["sn-memorygame"]  = function(cb, ...) cb(exports["SN-Hacking"]:MemoryGame(...)) end,
    ["sn-skillcheck"]  = function(cb, ...) cb(exports["SN-Hacking"]:SkillCheck(...)) end,
    ["sn-thermite"]    = function(cb, ...) cb(exports["SN-Hacking"]:Thermite(...)) end,
    ["sn-keypad"]      = function(cb, ...) cb(exports["SN-Hacking"]:KeyPad(...)) end,
    ["sn-colorpicker"] = function(cb, ...) cb(exports["SN-Hacking"]:ColorPicker(...)) end,

    -- rm_minigames
    ["rm-typinggame"]       = function(cb, ...) cb(exports["rm_minigames"]:typingGame(...)) end,
    ["rm-timedlockpick"]    = function(cb, ...) cb(exports["rm_minigames"]:timedLockpick(...)) end,
    ["rm-timedaction"]      = function(cb, ...) cb(exports["rm_minigames"]:timedAction(...)) end,
    ["rm-quicktimeevent"]   = function(cb, ...) cb(exports["rm_minigames"]:quickTimeEvent(...)) end,
    ["rm-combinationlock"]  = function(cb, ...) cb(exports["rm_minigames"]:combinationLock(...)) end,
    ["rm-buttonmashing"]    = function(cb, ...) cb(exports["rm_minigames"]:buttonMashing(...)) end,
    ["rm-angledlockpick"]   = function(cb, ...) cb(exports["rm_minigames"]:angledLockpick(...)) end,
    ["rm-fingerprint"]      = function(cb, ...) cb(exports["rm_minigames"]:fingerPrint(...)) end,
    ["rm-circleClick"]      = function(cb, ...) cb(exports["rm_minigames"]:circleClick(...)) end,
    ["rm-hotwirehack"]      = function(cb, ...) cb(exports["rm_minigames"]:hotwireHack(...)) end,
    ["rm-hackerminigame"]   = function(cb, ...) cb(exports["rm_minigames"]:hackerMinigame(...)) end,
    ["rm-safecrack"]        = function(cb, ...) cb(exports["rm_minigames"]:safeCrack(...)) end,

    -- bl_ui
    ["bl-circlesum"]   = function(cb, ...) cb(exports["bl_ui"]:CircleSum(...)) end,
    ["bl-digitdazzle"] = function(cb, ...) cb(exports["bl_ui"]:DigitDazzle(...)) end,
    ["bl-lightsout"]   = function(cb, ...) cb(exports["bl_ui"]:LightsOut(...)) end,
    ["bl-minesweeper"] = function(cb, ...) cb(exports["bl_ui"]:MineSweeper(...)) end,
    ["bl-pathfind"]    = function(cb, ...) cb(exports["bl_ui"]:PathFind(...)) end,
    ["bl-printlock"]   = function(cb, ...) cb(exports["bl_ui"]:PrintLock(...)) end,
    ["bl-untangle"]    = function(cb, ...) cb(exports["bl_ui"]:Untangle(...)) end,
    ["bl-wavematch"]   = function(cb, ...) cb(exports["bl_ui"]:WaveMatch(...)) end,
    ["bl-wordwiz"]     = function(cb, ...) cb(exports["bl_ui"]:WordWiz(...)) end,

    -- glitch-minigames
    ["gl-firewall-pulse"]    = function(cb, ...) cb(exports["glitch-minigames"]:StartFirewallPulse(...)) end,
    ["gl-backdoor-sequence"] = function(cb, ...) cb(exports["glitch-minigames"]:StartBackdoorSequence(...)) end,
    ["gl-circuit-rhythm"]    = function(cb, ...) cb(exports["glitch-minigames"]:StartCircuitRhythm(...)) end,
    ["gl-surge-override"]    = function(cb, ...) cb(exports["glitch-minigames"]:StartSurgeOverride(...)) end,
    ["gl-circuit-breaker"]   = function(cb, ...) cb(exports["glitch-minigames"]:StartCircuitBreaker(...)) end,
    ["gl-data-crack"]        = function(cb, ...) cb(exports["glitch-minigames"]:StartDataCrack(...)) end,
    ["gl-brute-force"]       = function(cb, ...) cb(exports["glitch-minigames"]:StartBruteForce(...)) end,
    ["gl-var-hack"]          = function(cb, ...) cb(exports["glitch-minigames"]:StartVarHack(...)) end,

    -- ox_lib skillCheck fallback
    ["ox-skillcheck"] = function(cb, difficulty, keys)
        if framezero.IsStarted("ox_lib") then
            cb(exports.ox_lib:skillCheck(difficulty or { "easy", "easy" }, keys or { "1", "2", "3", "4" }) == true)
        else
            cb(true)
        end
    end,
}

--- Executa um minigame por nome.
-- Suporta chamada síncrona (se omitir o callback) ou com função de callback.
function framezero.ExecuteMinigame(gameType, ...)
    local args = { ... }
    local callback
    local startIdx = 1

    if type(args[1]) == "function" then
        callback = args[1]
        startIdx = 2
    end

    local cleanArgs = {}
    for i = startIdx, #args do
        cleanArgs[#cleanArgs + 1] = args[i]
    end

    local handler = GAMES[gameType]
    if not handler then
        framezero.Log("error", "Minigame '%s' não encontrado no catálogo.", tostring(gameType))
        if callback then callback(false) end
        return false
    end

    if callback then
        handler(callback, table.unpack(cleanArgs))
        return
    end

    -- Chamada síncrona
    local done = false
    local result = false
    handler(function(res)
        result = (res == true)
        done = true
    end, table.unpack(cleanArgs))

    while not done do
        Wait(50)
    end
    return result
end
