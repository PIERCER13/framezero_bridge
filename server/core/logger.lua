-- Logger avançado com suporte a Discord Webhook (com buffer/batching anti-rate limit),
-- Loki e Grafana.

framezero = framezero or {}
framezero.Logger = {}

local cfg = {
    discord = {
        webhook = Config.Logger and Config.Logger.discord and Config.Logger.discord.webhook or "",
        name = Config.Logger and Config.Logger.discord and Config.Logger.discord.name or "FrameZero",
        avatar = Config.Logger and Config.Logger.discord and Config.Logger.discord.avatar or "",
        color = Config.Logger and Config.Logger.discord and Config.Logger.discord.color or 3447003,
        flushInterval = Config.Logger and Config.Logger.discord and Config.Logger.discord.flushInterval or 15, -- segundos
    },
    loki = Config.Logger and Config.Logger.loki or nil,
}

local discordBuffer = {}
local discordFlushScheduled = false

local function sendDiscordWebhook(webhookUrl, payload)
    PerformHttpRequest(webhookUrl, function(status, body, headers)
        if status < 200 or status >= 300 then
            framezero.Log("warn", "Discord webhook falhou (status %d)", status)
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

local function flushDiscord()
    discordFlushScheduled = false
    if #discordBuffer == 0 then return end

    local entries = discordBuffer
    discordBuffer = {}

    local url = cfg.discord.webhook
    if not url or url == "" then return end

    -- Agrupa em lotes de até 10 embeds (limite do Discord por mensagem)
    local batch = {}
    for _, entry in ipairs(entries) do
        batch[#batch + 1] = {
            title = entry.title,
            description = entry.message,
            color = entry.color or cfg.discord.color,
            footer = { text = os.date("%d/%m/%Y %H:%M:%S") },
        }
        if #batch == 10 then
            sendDiscordWebhook(url, {
                username = cfg.discord.name,
                avatar_url = cfg.discord.avatar,
                embeds = batch,
            })
            batch = {}
        end
    end

    if #batch > 0 then
        sendDiscordWebhook(url, {
            username = cfg.discord.name,
            avatar_url = cfg.discord.avatar,
            embeds = batch,
        })
    end
end

function framezero.Logger.LogDiscord(title, message, opts)
    opts = opts or {}
    local webhook = opts.webhook or cfg.discord.webhook
    if not webhook or webhook == "" then return end

    if opts.immediate then
        sendDiscordWebhook(webhook, {
            username = opts.name or cfg.discord.name,
            avatar_url = opts.avatar or cfg.discord.avatar,
            content = opts.tagEveryone and "@everyone" or nil,
            embeds = {{
                title = title,
                description = message,
                color = opts.color or cfg.discord.color,
                footer = { text = os.date("%d/%m/%Y %H:%M:%S") },
            }}
        })
        return
    end

    discordBuffer[#discordBuffer + 1] = {
        title = title,
        message = message,
        color = opts.color,
    }

    if not discordFlushScheduled then
        discordFlushScheduled = true
        SetTimeout((cfg.discord.flushInterval or 15) * 1000, flushDiscord)
    end
end
