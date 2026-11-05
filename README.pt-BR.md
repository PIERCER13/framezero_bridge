<div align="center">

# 🌉 FrameZero Bridge

**Uma camada única entre os scripts FrameZero e o seu servidor.**

Escreva o script uma vez e ele roda em **ESX, QBCore, Qbox, vRP, vRPex, Creative** e mais — a bridge
detecta automaticamente o framework, inventário, garagem, sistema de notificação, target, celular, dispatch e doorlock ativos.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20vRP%20%C2%B7%20Creative-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/jZ3vTmdjU7)

[![Read in English](https://img.shields.io/badge/Read%20in%20English-5865F2?style=for-the-badge&logo=googletranslate&logoColor=white)](README.md)

</div>

---

## 🎯 Para que serve

Cada script da FrameZero conversa com o seu servidor através de **uma** API, em vez de cada um reinventar suporte
a cada framework, inventário e sistema de notificação. Você instala a bridge uma vez; os scripts usam apenas a
global `framezero`. Na maioria dos servidores não há **nada para configurar** — tudo no `config.lua` fica como `"auto"`.

> Autor: **piercer** · Versão atual: **1.5.0**

## 🚀 Instalação

1. Coloque a pasta `framezero_bridge` em `resources/`.
2. No seu `server.cfg`, inicie a bridge **antes** dos scripts que dependem dela:
   ```cfg
   ensure framezero_bridge
   ensure seu_script_framezero
   ```
3. Na maioria dos servidores **nada mais é necessário** — tudo no `config.lua` já vem em `"auto"`. Só mexa para
   forçar alguma opção específica ou caso utilize uma base fortemente modificada.

## 🧩 Usando nos seus scripts

No `fxmanifest.lua` do seu script, importe a bridge:

```lua
shared_script "@framezero_bridge/import.lua"
```

A global `framezero` fica disponível no **servidor** e no **cliente**:

```lua
-- Servidor
framezero.Notify(source, "success", "Pronto!")
framezero.AddItem(source, "water", 2)
framezero.Dispatch({ code = "10-90", title = "Assalto a Loja", coords = vec3(100, 200, 30) })

-- Cliente
if framezero.Minigame("ps-circle", 2, 10) then
    framezero.Notify("success", "Hacking concluído!")
end
```

Se o seu script executa no momento do boot do servidor, aguarde a bridge concluir a detecção (dentro de uma thread):

```lua
CreateThread(function()
    framezero.WaitReady()          -- opcional: timeout em ms (padrão 15000)
    -- ... seu código ...
end)
```

## 🖧 API de Servidor

### Jogador
| Função | Retorno |
|---|---|
| `GetPlayerId(src)` | id do personagem (identifier/citizenid/passaporte), string |
| `GetSource(id)` | source online a partir do id |
| `GetPlayers()` | lista de sources online |
| `GetName(src)` | nome do personagem |
| `GetGender(src)` | `"Male"` ou `"Female"` |
| `IsPlayerDead(src)` | `bool` (se o jogador está morto/em coma) |
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
> `target` = source **ou** número. Suporta `lb-phone`, `qb-phone`, `smartphone`, `qs-smartphone`, `gksphone`, `npwd`, `yseries`, `roadphone`, `okokPhone`, `high-phone`.

### Alerta Policial (Dispatch) & Trancas (Doorlock) 🚨
* `Dispatch(data)` — Emite chamada policial unificada (`code`, `title`, `message`, `coords`, `jobs`, `blipText`, `time`).
* `SetDoorState(doorId, locked, options)` — Tranca/destranca portas no servidor (`ox_doorlock`, `qb-doorlock`, `nui-doorlock`, `cd_doorlock`, `doors_creator`).

### Logs & Auditoria (Discord / Loki) 📋
* `LogDiscord(title, message, options)` — Envia logs com buffer e lote inteligente (anti-rate limit do Discord) ou imediato (`options.immediate = true`).

### Callbacks e Banco de Dados
`RegisterCallback(name, fn)` · `AwaitClient(src, name, timeout, ...)` · `DB` · `Info()`

---

## 🖥️ API de Cliente

### Minigames & Hacking 🎮
Executa mais de 30 minigames populares sob uma mesma interface. Suporta chamada síncrona (espera o resultado) ou com callback:
```lua
-- Síncrono:
local venceu = framezero.Minigame("ps-circle", 2, 10)

-- Ou com callback:
framezero.Minigame("rm-typinggame", function(sucesso)
    print("Resultado:", sucesso)
end)
```
* **ps-ui**: `ps-circle`, `ps-maze`, `ps-varhack`, `ps-thermite`, `ps-scrambler`
* **rm_minigames**: `rm-typinggame`, `rm-timedlockpick`, `rm-timedaction`, `rm-quicktimeevent`, `rm-combinationlock`, `rm-buttonmashing`, `rm-angledlockpick`, `rm-fingerprint`, `rm-circleClick`, `rm-hotwirehack`, `rm-hackerminigame`, `rm-safecrack`
* **bl_ui**: `bl-circlesum`, `bl-digitdazzle`, `bl-lightsout`, `bl-minesweeper`, `bl-pathfind`, `bl-printlock`, `bl-untangle`, `bl-wavematch`, `bl-wordwiz`
* **glitch-minigames**: `gl-firewall-pulse`, `gl-backdoor-sequence`, `gl-circuit-rhythm`, `gl-surge-override`, `gl-circuit-breaker`, `gl-data-crack`, `gl-brute-force`, `gl-var-hack`
* **Outros**: `ox-skillcheck`, `memorygame-thermite`, `ran-memorycard`, `ran-openterminal`, `hacking-opengame`, `howdy-begin`, `sn-memorygame`, `sn-skillcheck`, `sn-thermite`, `sn-keypad`, `sn-colorpicker`

### Alerta Policial (Dispatch) & Trancas (Doorlock) 🚨
* `Dispatch(data)` — Aciona o sistema policial ativo no cliente (`cd_dispatch`, `ps-dispatch`, `qs-dispatch`, `linden_outlawalert` ou fallback com som e blip).
* `SetDoorState(doorId, locked, options)` — Atualiza estado da porta a partir do cliente.

### Streaming Seguro & Peds Inteligentes 🧍
* `AwaitLoad(checkFn, errorMsg, timeoutMs)` — Aguarda condição com timeout seguro (evita loops infinitos).
* `LoadModel(model, timeoutMs)` · `LoadAnim(dict, timeoutMs)` · `LoadPtfx(asset, timeoutMs)` — Carregam recursos com verificação de integridade e timeout.
* `GetItemImage(item)` — Retorna a URL `nui://` da imagem do item de acordo com o inventário rodando no servidor.
* `CreatePed(data)` — Spawna ped com congelamento, cenário, invulnerabilidade e limpeza automática ao parar a resource.
* `CreatePedAtPoint(data)` — **Spawn inteligente por proximidade**: o ped só é criado na memória quando o jogador entra no raio configurado (`distance`) e é removido ao se afastar, economizando FPS e memória de streaming.

### Interface
`Notify(kind, message, duration)` · `Progress(label, duration, opts)` (retorna `true` se completou;
opts `{ canCancel, disableControls, disableMove, disableCar }`) · `ShowText(text)` · `HideText()`

### Target
`AddSphere(id, coords, radius, options)` · `AddModel(id, models, options)` · `RemoveTarget(id)`

Cada `option`: `{ label, icon?, distance?, onSelect = function(entity) end, canInteract? = function(entity) end }`.
Funciona com **ox_target**, **qb-target**, target **próprio** (ver custom) ou fallback de texto na tela + tecla **E**.

### Callbacks e Jogador
`TriggerCallback(name, timeoutMs, ...)` · `RegisterCallback(name, fn)` · `OnPlayerLoaded(cb)` · `IsLoaded()` · `GetGender()` · `Info()`

---

## 🧰 Sistemas suportados (detecção automática)

| Tipo | Opções |
|---|---|
| **Framework** | ESX · QBCore · Qbox · vRP · vRPex · Creative (todas as versões) · tnet · ndcore · oxcore · standalone |
| **Inventário** | ox_inventory · qs-inventory · qs-inventory-pro · tnet_inventory · codem-inventory · core_inventory · ak47_inventory · (do framework) |
| **Garagem** | nation-garages · qbx_vehicles · (do framework) |
| **Notificação** | ox_lib · okokNotify · mythic_notify · (do framework) |
| **Target** | ox_target · qb-target · custom · none |
| **Progresso** | ox_lib · framezero |
| **Celular** | lb-phone · qb-phone · smartphone (jesters-lab) · qs-smartphone · qs-smartphone-pro · gksphone · npwd · yseries · yflip-phone · roadphone · okokPhone · high-phone |
| **Dispatch** | cd_dispatch · ps-dispatch · qs-dispatch · linden_outlawalert · framework fallback |
| **Doorlock** | ox_doorlock · qb-doorlock · nui-doorlock · cd_doorlock · doors_creator |
| **Minigames** | ps-ui · bl_ui (9 jogos) · rm_minigames (12 jogos) · glitch-minigames (8 jogos) · ox-skillcheck · memorygame · sn-hacking · ran · howdy |

---

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
Config.Dispatch  = "auto"
Config.Doorlock  = "auto"
Config.Phone     = "auto"
Config.PhoneSender = "FrameZero"

-- Logs e Webhooks
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

## 🧱 Base modificada? Use `custom/`

Arquivos dentro de `custom/` **nunca são sobrescritos** em atualizações da bridge.

**Sobrescreva qualquer função da API** (`custom/server.lua` ou `custom/client.lua`):

```lua
framezero.Custom.GiveVehicle = function(target, model, opts)
    local id = framezero.API.GetPlayerId(target) or tostring(target)
    exports["minha_garagem"]:AddVehicle(id, model, opts and opts.plate)
    return opts and opts.plate
end
```

## 📄 Licença

© PIERCER / FrameZero. Todos os direitos reservados.

<div align="center">

**[PIERCER13](https://github.com/PIERCER13)** · Discord **@piercer** · [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)

</div>
