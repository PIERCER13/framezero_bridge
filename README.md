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

> Author: **piercer** · Current version: **1.6.0**

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
| `SetDuty(src, onDuty)` | `bool` (updates player on-duty / off-duty status) |
| `OnPlayerLoaded(cb)` / `OnPlayerUnloaded(cb)` | registers a `(src, id)` callback |

### Money — `account`: `"cash"` (default) · `"bank"` · `"dirty"`
`GetMoney(src, account)` · `AddMoney(src, amount, account)` · `RemoveMoney(src, amount, account)`

### Society & Gang Accounts 💼
* `GetSocietyMoney(societyName)` — Retrieves society account balance (`Renewed-Banking`, `qb-banking`, `qb-management`, `esx_addonaccount`, `vRP`).
* `AddSocietyMoney(societyName, amount)` — Deposits funds into society account.
* `RemoveSocietyMoney(societyName, amount)` — Withdraws funds from society account.

### Items & Stashes — uses the detected inventory (ox, qs, snt, etc.) or the framework's
* `GetItemCount(src, item, metadata)` · `HasItem(src, item, amount, metadata)` · `CanCarry(src, item, amount, metadata)` · `AddItem(src, item, amount, metadata)` · `RemoveItem(src, item, amount, metadata)` · `GetInventory(src)` · `GetItemLabel(item)` · `GetItemWeight(item)`
* `CloseInventory(src)` — Closes active inventory UI.
* `RegisterUsableItem(item, function(src) end)` — Registers a usable item across frameworks.
* **Shared Stashes (Storage/Safes):**
  * `RegisterStash(id, label, slots, maxWeight, owner)` — Registers or prepares a shared stash (`ox_inventory`, `qs-inventory`, `snt-inventory`).
  * `StashCount(id, item)` — Counts items inside the stash.
  * `StashAdd(id, item, count, metadata)` — Adds items into the stash.
  * `StashRemove(id, item, count, metadata)` — Removes items from the stash.

### Vehicles & Keys 🔑
* `GeneratePlate()` — Generates random or prefixed plate.
* `GiveVehicle(target, model, opts)` — Gives vehicle to player (opts `{ plate?, garage?, type?, keys? }`, automatic key giving enabled by default).
* `HasVehicle(target, model)` — Checks vehicle ownership.
* `GetVehicleOwner(plate)` — Returns unique identifier of owner (`citizenid`, `identifier`, or `user_id`).
* `GiveVehicleKeys(target, plate)` — Gives vehicle keys to online player (`qb-vehiclekeys`, `qbx_vehiclekeys`, `qs-vehiclekeys`, `wasabi_carlock`, `vRP`).
* `RemoveVehicleKeys(target, plate)` — Removes vehicle keys from online player.
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

### Anticheat Compatibility (Server) 🛡️
Prevents false bans by registering legitimate server-side actions:
`Anticheat.Teleport(src)` · `Anticheat.PedModel(src, model)` · `Anticheat.Entity(entity, model)` · `Anticheat.Weapon(src, hash, given)` · `Anticheat.Heal(src)` · `Anticheat.HasBypass(src)` · `Anticheat.Ban(src, reason)` · `Anticheat.Kick(src, reason)`

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

### Vehicle Keys (Client) 🔑
* `GiveVehicleKeys(plate)` — Grants vehicle keys locally on client.
* `RemoveVehicleKeys(plate)` — Removes vehicle keys locally on client.
* `HasVehicleKeys(plate)` — Checks if player has keys for the plate locally.

### Interface
`Notify(kind, message, duration)` · `Progress(label, duration, opts)` (returns `true` if it completed;
opts `{ canCancel, disableControls, disableMove, disableCar }`) · `ShowText(text)` · `HideText()` ·
`CloseInventory()` (closes any open inventory UI)

### Anticheat Compatibility (Client) 🛡️
Informs the active anticheat before executing minigames, cutscenes, or stealth actions:
`Anticheat.Teleport()` · `Anticheat.SetInvincible(on)` · `Anticheat.SetVisible(visible)` · `Anticheat.SetSpectating(on)` · `Anticheat.PedModel(model)` · `Anticheat.Spawn(kind, model)` · `Anticheat.Camera(cam)` · `Anticheat.CameraDestroyed(cam)` · `Anticheat.Weapon(hash, given)` · `Anticheat.Heal()` · `Anticheat.Revive()` · `Anticheat.ReleaseAll()`

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
| **Inventory & Stashes** | ox_inventory · snt-inventory-pro · snt-inventory · qs-inventory · qs-inventory-pro · tnet_inventory · codem-inventory · core_inventory · ak47_inventory · (framework's) |
| **Garages & Vehicle Keys** | qb-vehiclekeys · qbx_vehiclekeys · qs-vehiclekeys · wasabi_carlock · nation-garages · qs-advancedgarages · nn_garages · qbx_vehicles · (framework's) |
| **Societies / Banking** | Renewed-Banking · qb-banking · qb-management · esx_addonaccount · vRP/Creative |
| **Notification** | ox_lib · okokNotify · mythic_notify · (framework's) |
| **Target** | ox_target · qb-target · custom · none |
| **Progress** | ox_lib · framezero |
| **Anticheat** | FeloxAC · FiveGuard (Safe Events, VerifyToken & temporary bypasses) · none |
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

-- Security & API Limits
Config.MaxMoneyPerCall = 10000000 -- monetary limit per call
Config.MaxItemPerCall  = 10000    -- item count limit per call
Config.AllowedResources = nil     -- resource whitelist (nil = open)
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
