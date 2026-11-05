fx_version "cerulean"
game "gta5"
lua54 "yes"

name "framezero_bridge"
author "piercer"
version "1.6.0"
description "FrameZero Bridge (ESX, QBCore, Qbox, vRP, vRPex, Creative)"

ui_page "web/index.html"

shared_scripts {
    "config.lua",
    "locales/*.lua",
    "shared/init.lua",
}

server_scripts {
    "server/core/*.lua",
    "server/frameworks/*.lua",
    "server/inventory/*.lua",
    "server/vehicles/*.lua",
    "server/phone/*.lua",
    "server/dispatch/*.lua",
    "server/doorlock/*.lua",
    "server/anticheat/*.lua",
    "server/api.lua",
    "custom/server.lua",
}

client_scripts {
    "client/core/*.lua",
    "client/frameworks/*.lua",
    "client/vehicles/*.lua",
    "client/dispatch/*.lua",
    "client/doorlock/*.lua",
    "client/minigames/*.lua",
    "client/streaming/*.lua",
    "client/anticheat/*.lua",
    "client/api.lua",
    "custom/client.lua",
}

files {
    "import.lua",
    "web/index.html",
    "web/style.css",
    "web/app.js",
}
