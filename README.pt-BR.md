<div align="center">

# 🌉 FrameZero Bridge

**Uma camada única entre os scripts FrameZero e o seu servidor.**

Você escreve o script uma vez e ele roda em **ESX, QBCore, Qbox, vRP, vRPex, Creative** e mais — a bridge
detecta sozinha o framework, o inventário, a garagem, o sistema de notificação, o target e o celular.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20vRP%20%C2%B7%20Creative-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
[![Discord](https://img.shields.io/badge/Discord-entrar-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/jZ3vTmdjU7)

[![Read in English](https://img.shields.io/badge/Read%20in%20English-5865F2?style=for-the-badge&logo=googletranslate&logoColor=white)](README.md)

</div>

---

## 🎯 Para que serve

Todo script FrameZero conversa com o seu servidor por **uma só** API, em vez de cada um reimplementar suporte
a cada framework, inventário e sistema de notificação. Você instala a bridge uma vez; os scripts só usam a
global `framezero`. Na maioria dos servidores **não precisa configurar nada** — tudo no `config.lua` fica em `"auto"`.

> Autor: **piercer** · Versão atual: **1.4.0**

## 🚀 Instalação

1. Coloque a pasta `framezero_bridge` em `resources/`.
2. No seu `server.cfg`, inicie a bridge **antes** dos scripts que dependem dela:
   ```cfg
   ensure framezero_bridge
   ensure seu_script_framezero
   ```
3. Na maioria dos servidores **não precisa de mais nada** — tudo no `config.lua` fica em `"auto"`. Só mexa
   para forçar algo ou se tiver uma base modificada.

## 🧩 Como usar nos seus scripts

No `fxmanifest.lua` do seu script, importe a bridge:

```lua
shared_script "@framezero_bridge/import.lua"
```

Agora a global `framezero` está disponível no **servidor** e no **cliente**:

```lua
-- Servidor
framezero.Notify(source, "success", "Pronto!")
framezero.AddItem(source, "agua", 2)

-- Cliente
if framezero.Progress("Fabricando...", 5000) then
    framezero.Notify("success", "Concluído!")
end
```

Se o seu script roda logo no boot, espere a bridge terminar de detectar o framework (dentro de uma thread):

```lua
CreateThread(function()
    framezero.WaitReady()          -- opcional: timeout em ms (padrão 15000)
    -- ... seu código ...
end)
```

## 🖧 API de servidor

### Jogador
| Função | Retorno |
|---|---|
| `GetPlayerId(src)` | id do personagem (identifier/citizenid/passaporte), string |
| `GetSource(id)` | source online a partir do id |
| `GetPlayers()` | lista de sources online |
| `GetName(src)` | nome do personagem |
| `HasPermission(src, perm)` | `bool` (grupo/job/ACE, conforme o framework) |
| `GetJob(src)` | `{ name, label, grade, gradeLabel, onDuty }` |
| `OnPlayerLoaded(cb)` / `OnPlayerUnloaded(cb)` | registra callback `(src, id)` |

### Dinheiro — `account`: `"cash"` (padrão) · `"bank"` · `"dirty"`
`GetMoney(src, account)` · `AddMoney(src, amount, account)` · `RemoveMoney(src, amount, account)`

### Itens — usa o inventário detectado (ox, qs, etc.) ou o do framework
`GetItemCount(src, item, metadata)` · `HasItem(src, item, amount, metadata)` ·
`CanCarry(src, item, amount, metadata)` · `AddItem(src, item, amount, metadata)` ·
`RemoveItem(src, item, amount, metadata)` · `GetInventory(src)` (lista de
`{ name, label, amount, slot?, metadata?, weight? }`) · `GetItemLabel(item)` · `GetItemWeight(item)`

### Veículos
`GeneratePlate()` · `GiveVehicle(target, model, opts)` (opts `{ plate?, garage?, type? }`, retorna a placa ou `false`) · `HasVehicle(target, model)`
> `target` = source online **ou** id do personagem.

### Interface
`Notify(src, kind, message, duration)` · `Prompt(src, title, placeholder)` (retorna texto ou nil) ·
`Request(src, message, timeoutSeconds)` (Sim/Não → bool) · `Revive(src, health)`
> `kind`: `success` · `error` · `warning` · `info` (também aceita `sucesso`/`erro`/`aviso`...).

### Celular 📱
`GetPhoneNumber(src)` · `SendMail(target, { subject, message, sender })` ·
`SendMessage(target, message, sender)` (SMS) · `PhoneNotify(src, { app, title, content })`
> `target` = source **ou** número. O que o celular não suportar retorna nil/false e avisa uma vez.

### Callbacks e banco
`RegisterCallback(name, fn)` · `AwaitClient(src, name, timeout, ...)` · `DB` · `Info()`

## 🖥️ API de cliente

### Interface
`Notify(kind, message, duration)` · `Progress(label, duration, opts)` (retorna `true` se completou;
opts `{ canCancel, disableControls, disableMove, disableCar }`) · `ShowText(text)` · `HideText()`

### Target
`AddSphere(id, coords, radius, options)` · `AddModel(id, models, options)` · `RemoveTarget(id)`

Cada `option`: `{ label, icon?, distance?, onSelect = function(entity) end, canInteract? = function(entity) end }`.
Funciona com **ox_target**, **qb-target**, um target **próprio** (ver custom) ou, sem nenhum, cai num
fallback de texto na tela + tecla **E**.

### Callbacks e jogador
`TriggerCallback(name, timeoutMs, ...)` (chama um callback do servidor) ·
`RegisterCallback(name, fn)` (responde pedidos do servidor) · `OnPlayerLoaded(cb)` ·
`IsLoaded()` · `Info()`

## 🧰 Sistemas suportados (detecção automática)

| Tipo | Opções |
|---|---|
| **Framework** | ESX · QBCore · Qbox · vRP · vRPex · Creative · tnet · ndcore · oxcore · standalone |
| **Inventário** | ox_inventory · qs-inventory · tnet_inventory · codem-inventory · core_inventory · ak47_inventory · (do framework) |
| **Garagem** | nation-garages · qbx_vehicles · (do framework) |
| **Notificação** | ox_lib · okokNotify · mythic_notify · (do framework) |
| **Target** | ox_target · qb-target · custom · none |
| **Progresso** | ox_lib · framezero |
| **Celular** | **lb-phone** (completo) · **qb-phone** (número) · outros via adaptador (ver abaixo) |

## ⚙️ Configuração (`config.lua`)

Tudo em `"auto"` por padrão. Principais opções:

```lua
Config.Locale    = "pt-br"   -- idioma dos logs
Config.Debug     = false     -- mostra no console qual adaptador atendeu cada chamada
Config.Framework = "auto"    -- forçar: esx · qbcore · qbox · vrp · tnet · ndcore · oxcore · standalone
Config.Inventory = "auto"
Config.Vehicles  = "auto"
Config.Notify    = "auto"
Config.Target    = "auto"
Config.Progress  = "auto"
Config.Phone     = "auto"    -- auto · none · lb-phone · qb-phone · (seu adaptador)
Config.PhoneSender = "FrameZero"  -- remetente padrão dos e-mails/SMS

Config.Vrp = { Resource = "vrp", NotifyStyle = "auto", CashItem = "dollars" }
Config.DirtyMoney = { esx = { account = "black_money" }, qbcore = { item = "markedbills" }, ... }
Config.VehicleDefaults = { Garage = "pillboxgarage", Type = "car", PlatePrefix = "", PlateLength = 8 }
Config.Keys = { Accept = "Y", Decline = "N", Interact = 38 }
```

## 🧱 Base modificada? Use `custom/`

Os arquivos em `custom/` **nunca são sobrescritos** pelas atualizações.

**Sobrescrever qualquer função** da API (`custom/server.lua` ou `custom/client.lua`):

```lua
framezero.Custom.GiveVehicle = function(target, model, opts)
    local id = framezero.API.GetPlayerId(target) or tostring(target)
    exports["minha_garagem"]:AddVehicle(id, model, opts and opts.plate)
    return opts and opts.plate
end
```

## 📱 Adicionar um celular (ou outro adaptador)

A bridge escolhe o adaptador de maior **prioridade** cujo `detect()` é verdadeiro. Para adicionar um celular,
crie um arquivo em `server/phone/` (veja o modelo comentado em `server/phone/_custom.lua`) e registre:

```lua
framezero.RegisterAdapter("phone", "meu_celular", {
    priority = 20,
    detect   = function() return framezero.IsStarted("meu_celular") end,
    init     = function() return true end,

    getNumber   = function(src) ... end,                        -- número do telefone
    sendMail    = function(number, data) ... end,               -- { subject, message, sender }
    sendMessage = function(number, message, sender) ... end,    -- SMS
    notify      = function(src, data) ... end,                  -- { app, title, content }
})
```

Implemente só os métodos que o seu celular tiver — os que faltarem apenas retornam nil/false. O mesmo padrão
`RegisterAdapter(kind, name, def)` vale para `framework`, `inventory`, `vehicles`, etc.

> **Celulares já prontos:** `lb-phone` (número + e-mail, testado) e `qb-phone` (número).
> Para **smartphone**, **gksphone**, **qs-smartphone**, **roadphone** e outros, use o modelo em
> `server/phone/_custom.lua` com os exports da sua versão.

## 🩺 Diagnóstico

Com `Config.Debug = true`, o console mostra qual adaptador atendeu cada chamada.
`framezero.Info()` (servidor ou cliente) retorna o que foi detectado:

```lua
-- { version, framework, inventory, vehicles, phone, notify, vrpFlavor? }
```

## 📄 Licença

© PIERCER / FrameZero. Todos os direitos reservados.

<div align="center">

**[PIERCER13](https://github.com/PIERCER13)** · Discord **@piercer** · [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)

</div>
