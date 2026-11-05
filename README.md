<div align="center">

# 🌉 FrameZero Bridge

**One layer between the FrameZero scripts and your server.**

Write the script once and it runs on **ESX, QBCore, Qbox, vRP, vRPex, Creative** and more — the bridge
auto-detects the framework, inventory, garage, notification system, target, phone, police dispatch, and doorlock systems.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20vRP%20%C2%B7%20Creative-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/jZ3vTmdjU7)

[![Ler em Português](https://img.shields.io/badge/Ler%20em%20Portugu%C3%AAs-5865F2?style=for-the-badge&logo=googletranslate&logoColor=white)](README.pt-BR.md)

</div>

---

## 🎯 What it's for

Every FrameZero script talks to your server through **one** unified API, instead of each script reimplementing support
for every framework, inventory, and notification system. You install the bridge once; the scripts just use the
global `framezero`. On most servers there is **nothing to configure** — everything in `config.lua` stays `"auto"`.

> Author: **piercer** · Current version: **1.5.0**

## 🚀 Installation

1. Put the `framezero_bridge` folder in `resources/`.
2. In your `server.cfg`, start the bridge **before** the scripts that depend on it:
   ```cfg
   ensure framezero_bridge
   ensure your_framezero_script
   ```
3. On most servers **nothing else is needed** — everything in `config.lua` stays `"auto"`. Only edit it to
   force something or if you run a custom server build.

## 🧩 Using it in your scripts

In your script's `fxmanifest.lua`, import the bridge:

```lua
shared_script "@framezero_bridge/import.lua"
```

Now the `framezero` global is available on the **server** and the **client**:

```lua
-- Server
framezero.Notify(source, "success", "Done!")
framezero.AddItem(source, "water", 2)
framezero.Dispatch({ code = "10-90", title = "Store Robbery", coords = vec3(100, 200, 30) })

-- Client
if framezero.Minigame("ps-circle", 2, 10) then
    framezero.Notify("success", "Hack completed!")
end
```

If your script runs right at boot, wait for the bridge to finish detecting the framework (inside a thread):

```lua
CreateThread(function()
    framezero.WaitReady()          -- optional: timeout in ms (default 15000)
    -- ... your code ...
end)
```

## 🖧 Server API

### Player
| Function | Returns |
|---|---|
| `GetPlayerId(src)` | character id (identifier/citizenid/passport), string |
| `GetSource(id)` | online source from the id |
| `GetPlayers()` | list of online sources |
| `GetName(src)` | character name |
| `GetGender(src)` | `"Male"` or `"Female"` |
| `IsPlayerDead(src)` | `bool` (whether player is dead or in coma) |
| `HasPermission(src, perm)` | `bool` (group/job/ACE, per framework) |
| `GetJob(src)` | `{ name, label, grade, gradeLabel, onDuty }` |
| `OnPlayerLoaded(cb)` / `OnPlayerUnloaded(cb)` | registers a `(src, id)` callback |

### Money — `account`: `"cash"` (default) · `"bank"` · `"dirty"`
`GetMoney(src, account)` · `AddMoney(src, amount, account)` · `RemoveMoney(src, amount, account)`

### Items — uses the detected inventory (ox, qs, etc.) or the framework's
`GetItemCount(src, item, metadata)` · `HasItem(src, item, amount, metadata)` ·
`CanCarry(src, item, amount, metadata)` · `AddItem(src, item, amount, metadata)` ·
`RemoveItem(src, item, amount, metadata)` · `GetInventory(src)` (list of
`{ name, label, amount, slot?, metadata?, weight? }`) · `GetItemLabel(item)` · `GetItemWeight(item)`

### Vehicles
`GeneratePlate()` · `GiveVehicle(target, model, opts)` (opts `{ plate?, garage?, type? }`, returns the plate or `false`) · `HasVehicle(target, model)`
> `target` = online source **or** character id.

### Interface
`Notify(src, kind, message, duration)` · `Prompt(src, title, placeholder)` (returns text or nil) ·
`Request(src, message, timeoutSeconds)` (Yes/No → bool) · `Revive(src, health)`
> `kind`: `success` · `error` · `warning` · `info` (also accepts `sucesso`/`erro`/`aviso`...).

### Phone 📱
`GetPhoneNumber(src)` · `SendMail(target, { subject, message, sender })` ·
`SendMessage(target, message, sender)` (SMS) · `PhoneNotify(src, { app, title, content })`
> `target` = source **or** number. Supports `lb-phone`, `qb-phone`, `smartphone`, `qs-smartphone`, `gksphone`, `npwd`, `yseries`, `roadphone`, `okokPhone`, `high-phone`.

### Police Dispatch & Doorlock 🚨
* `Dispatch(data)` — Triggers a police alert with auto-detection (`code`, `title`, `message`, `coords`, `jobs`, `blipText`, `time`).
* `SetDoorState(doorId, locked, options)` — Locks/unlocks doors on the server (`ox_doorlock`, `qb-doorlock`, `nui-doorlock`, `cd_doorlock`, `doors_creator`).

### Logs & Webhooks (Discord / Loki) 📋
* `LogDiscord(title, message, options)` — Batched Discord logging with rate-limit protection or immediate delivery (`options.immediate = true`).

### Callbacks & Database
`RegisterCallback(name, fn)` · `AwaitClient(src, name, timeout, ...)` · `DB` · `Info()`

---

## 🖥️ Client API

### Minigames & Hacking 🎮
Unified execution across 30+ popular FiveM minigames. Supports both synchronous (coroutine wait) and callback styles:
```lua
-- Synchronous:
local success = framezero.Minigame("ps-circle", 2, 10)

-- Or callback:
framezero.Minigame("rm-typinggame", function(success)
    print("Result:", success)
end)
```
* **ps-ui**: `ps-circle`, `ps-maze`, `ps-varhack`, `ps-thermite`, `ps-scrambler`
* **rm_minigames**: `rm-typinggame`, `rm-timedlockpick`, `rm-timedaction`, `rm-quicktimeevent`, `rm-combinationlock`, `rm-buttonmashing`, `rm-angledlockpick`, `rm-fingerprint`, `rm-circleClick`, `rm-hotwirehack`, `rm-hackerminigame`, `rm-safecrack`
* **bl_ui**: `bl-circlesum`, `bl-digitdazzle`, `bl-lightsout`, `bl-minesweeper`, `bl-pathfind`, `bl-printlock`, `bl-untangle`, `bl-wavematch`, `bl-wordwiz`
* **glitch-minigames**: `gl-firewall-pulse`, `gl-backdoor-sequence`, `gl-circuit-rhythm`, `gl-surge-override`, `gl-circuit-breaker`, `gl-data-crack`, `gl-brute-force`, `gl-var-hack`
* **Others**: `ox-skillcheck`, `memorygame-thermite`, `ran-memorycard`, `ran-openterminal`, `hacking-opengame`, `howdy-begin`, `sn-memorygame`, `sn-skillcheck`, `sn-thermite`, `sn-keypad`, `sn-colorpicker`

### Police Dispatch & Doorlock 🚨
* `Dispatch(data)` — Sends dispatch notifications from client (`cd_dispatch`, `ps-dispatch`, `qs-dispatch`, `linden_outlawalert` or framework fallback with sound & blip).
* `SetDoorState(doorId, locked, options)` — Updates door state from client.

### Safe Streaming & Smart Peds 🧍
* `AwaitLoad(checkFn, errorMsg, timeoutMs)` — Safely awaits conditions with timeouts to prevent hanging threads.
* `LoadModel(model, timeoutMs)` · `LoadAnim(dict, timeoutMs)` · `LoadPtfx(asset, timeoutMs)` — Load models, animation dictionaries, and particle effects with validation.
* `GetItemImage(item)` — Returns the `nui://` URL for an item's image based on the active inventory.
* `CreatePed(data)` — Spawns a ped with scenario, freeze, invincibility, and cleanup on resource stop.
* `CreatePedAtPoint(data)` — **Proximity-based smart spawner**: automatically creates the NPC when the player is within range (`distance`) and despawns when leaving, saving memory and FPS.

### Interface
`Notify(kind, message, duration)` · `Progress(label, duration, opts)` (returns `true` if it completed;
opts `{ canCancel, disableControls, disableMove, disableCar }`) · `ShowText(text)` · `HideText()`

### Target
`AddSphere(id, coords, radius, options)` · `AddModel(id, models, options)` · `RemoveTarget(id)`

Each `option`: `{ label, icon?, distance?, onSelect = function(entity) end, canInteract? = function(entity) end }`.
Works with **ox_target**, **qb-target**, your **own** target (see custom) or fallback to on-screen text + the **E** key.

### Callbacks & Player
`TriggerCallback(name, timeoutMs, ...)` · `RegisterCallback(name, fn)` · `OnPlayerLoaded(cb)` · `IsLoaded()` · `GetGender()` · `Info()`

---

## 🧰 Supported systems (auto-detected)

| Type | Options |
|---|---|
| **Framework** | ESX · QBCore · Qbox · vRP · vRPex · Creative (all versions) · tnet · ndcore · oxcore · standalone |
| **Inventory** | ox_inventory · qs-inventory · qs-inventory-pro · tnet_inventory · codem-inventory · core_inventory · ak47_inventory · (framework's) |
| **Garage** | nation-garages · qbx_vehicles · (framework's) |
| **Notification** | ox_lib · okokNotify · mythic_notify · (framework's) |
| **Target** | ox_target · qb-target · custom · none |
| **Progress** | ox_lib · framezero |
| **Phone** | lb-phone · qb-phone · smartphone · qs-smartphone · qs-smartphone-pro · gksphone · npwd · yseries · yflip-phone · roadphone · okokPhone · high-phone |
| **Dispatch** | cd_dispatch · ps-dispatch · qs-dispatch · linden_outlawalert · framework fallback |
| **Doorlock** | ox_doorlock · qb-doorlock · nui-doorlock · cd_doorlock · doors_creator |
| **Minigames** | ps-ui · bl_ui (9 games) · rm_minigames (12 games) · glitch-minigames (8 games) · ox-skillcheck · memorygame · sn-hacking · ran · howdy |

---

## ⚙️ Configuration (`config.lua`)

Everything is `"auto"` by default. Main options:

```lua
Config.Locale    = "pt-br"   -- log language
Config.Debug     = false     -- shows in the console which adapter handled each call
Config.Framework = "auto"    -- force: esx · qbcore · qbox · vrp · tnet · ndcore · oxcore · standalone
Config.Inventory = "auto"
Config.Vehicles  = "auto"
Config.Notify    = "auto"
Config.Target    = "auto"
Config.Progress  = "auto"
Config.Dispatch  = "auto"
Config.Doorlock  = "auto"
Config.Phone     = "auto"
Config.PhoneSender = "FrameZero"

-- Webhook & Audit Logging
Config.Logger = {
    discord = {
        webhook       = "",
        name          = "FrameZero Logs",
        avatar        = "",
        color         = 3447003,
        flushInterval = 15,
    }
}
```

## 🧱 Modified base? Use `custom/`

Files under `custom/` are **never overwritten** by bridge updates.

**Override any API function** (`custom/server.lua` or `custom/client.lua`):

```lua
framezero.Custom.GiveVehicle = function(target, model, opts)
    local id = framezero.API.GetPlayerId(target) or tostring(target)
    exports["my_garage"]:AddVehicle(id, model, opts and opts.plate)
    return opts and opts.plate
end
```

## 📄 License

© PIERCER / FrameZero. All rights reserved.

<div align="center">

**[PIERCER13](https://github.com/PIERCER13)** · Discord **@piercer** · [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)

</div>
