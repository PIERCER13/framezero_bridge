<div align="center">

# 🌉 FrameZero Bridge

**One layer between the FrameZero scripts and your server.**

Write the script once and it runs on **ESX, QBCore, Qbox, vRP, vRPex, Creative** and more — the bridge
auto-detects the framework, inventory, garage, notification system, target and phone that are running.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20vRP%20%C2%B7%20Creative-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/jZ3vTmdjU7)

[![Ler em Português](https://img.shields.io/badge/Ler%20em%20Portugu%C3%AAs-5865F2?style=for-the-badge&logo=googletranslate&logoColor=white)](README.pt-BR.md)

</div>

---

## 🎯 What it's for

Every FrameZero script talks to your server through **one** API, instead of each one reimplementing support
for every framework, inventory and notification system. You install the bridge once; the scripts just use the
global `framezero`. On most servers there is **nothing to configure** — everything in `config.lua` is `"auto"`.

> Author: **piercer** · Current version: **1.4.0**

## 🚀 Installation

1. Put the `framezero_bridge` folder in `resources/`.
2. In your `server.cfg`, start the bridge **before** the scripts that depend on it:
   ```cfg
   ensure framezero_bridge
   ensure your_framezero_script
   ```
3. On most servers **nothing else is needed** — everything in `config.lua` stays `"auto"`. Only touch it to
   force something or if you have a modified base.

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

-- Client
if framezero.Progress("Crafting...", 5000) then
    framezero.Notify("success", "Finished!")
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
> `target` = source **or** number. Anything the phone doesn't support returns nil/false and warns once.

### Callbacks & database
`RegisterCallback(name, fn)` · `AwaitClient(src, name, timeout, ...)` · `DB` · `Info()`

## 🖥️ Client API

### Interface
`Notify(kind, message, duration)` · `Progress(label, duration, opts)` (returns `true` if it completed;
opts `{ canCancel, disableControls, disableMove, disableCar }`) · `ShowText(text)` · `HideText()`

### Target
`AddSphere(id, coords, radius, options)` · `AddModel(id, models, options)` · `RemoveTarget(id)`

Each `option`: `{ label, icon?, distance?, onSelect = function(entity) end, canInteract? = function(entity) end }`.
Works with **ox_target**, **qb-target**, your **own** target (see custom) or, with none, falls back to
on-screen text + the **E** key.

### Callbacks & player
`TriggerCallback(name, timeoutMs, ...)` (calls a server callback) ·
`RegisterCallback(name, fn)` (answers server requests) · `OnPlayerLoaded(cb)` ·
`IsLoaded()` · `Info()`

## 🧰 Supported systems (auto-detected)

| Type | Options |
|---|---|
| **Framework** | ESX · QBCore · Qbox · vRP · vRPex · Creative · tnet · ndcore · oxcore · standalone |
| **Inventory** | ox_inventory · qs-inventory · tnet_inventory · codem-inventory · core_inventory · ak47_inventory · (framework's) |
| **Garage** | nation-garages · qbx_vehicles · (framework's) |
| **Notification** | ox_lib · okokNotify · mythic_notify · (framework's) |
| **Target** | ox_target · qb-target · custom · none |
| **Progress** | ox_lib · framezero |
| **Phone** | **lb-phone** (full) · **qb-phone** (number) · others via adapter (see below) |

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
Config.Phone     = "auto"    -- auto · none · lb-phone · qb-phone · (your adapter)
Config.PhoneSender = "FrameZero"  -- default sender for the e-mails/SMS

Config.Vrp = { Resource = "vrp", NotifyStyle = "auto", CashItem = "dollars" }
Config.DirtyMoney = { esx = { account = "black_money" }, qbcore = { item = "markedbills" }, ... }
Config.VehicleDefaults = { Garage = "pillboxgarage", Type = "car", PlatePrefix = "", PlateLength = 8 }
Config.Keys = { Accept = "Y", Decline = "N", Interact = 38 }
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

## 📱 Adding a phone (or another adapter)

The bridge picks the adapter with the highest **priority** whose `detect()` is true. To add a phone, create a
file in `server/phone/` (see the commented template in `server/phone/_custom.lua`) and register:

```lua
framezero.RegisterAdapter("phone", "my_phone", {
    priority = 20,
    detect   = function() return framezero.IsStarted("my_phone") end,
    init     = function() return true end,

    getNumber   = function(src) ... end,                        -- phone number
    sendMail    = function(number, data) ... end,               -- { subject, message, sender }
    sendMessage = function(number, message, sender) ... end,    -- SMS
    notify      = function(src, data) ... end,                  -- { app, title, content }
})
```

Implement only the methods your phone has — the missing ones just return nil/false. The same
`RegisterAdapter(kind, name, def)` pattern works for `framework`, `inventory`, `vehicles`, etc.

> **Ready-made phones:** `lb-phone` (number + e-mail, tested) and `qb-phone` (number).
> For **smartphone**, **gksphone**, **qs-smartphone**, **roadphone** and others, use the template in
> `server/phone/_custom.lua` with your version's exports.

## 🩺 Diagnostics

With `Config.Debug = true`, the console shows which adapter handled each call.
`framezero.Info()` (server or client) returns what was detected:

```lua
-- { version, framework, inventory, vehicles, phone, notify, vrpFlavor? }
```

## 📄 License

© PIERCER / FrameZero. All rights reserved.

<div align="center">

**[PIERCER13](https://github.com/PIERCER13)** · Discord **@piercer** · [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)

</div>
