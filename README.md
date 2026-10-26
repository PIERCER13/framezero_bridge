# FRAMEZERO BRIDGE
Resource multi-framework dos scripts da **FrameZero**. Instala uma vez e todos os scripts da loja rodam no seu framework.

**Frameworks:** ESX (Legacy e 1.x) · QBCore (novo e antigo) · Qbox · vRP · vRPex · Creative (v5, v6, Network, Enchanted e bases modificadas) · tnet · ND_Core · ox_core
**Inventários:** ox_inventory · qs-inventory · tnet_inventory · codem-inventory · core_inventory · ak47_inventory · padrão do framework
**Garagens:** nation-garages · qbx_vehicles · tabela padrão do framework
**Extras:** ox_lib (notificação, progresso, texto) · okokNotify · mythic_notify · ox_target · qb-target · target próprio

## INSTALÇÃO
1. Coloque a pasta `framezero_bridge` em `resources`.
2. No `server.cfg`, **depois** do framework e do banco e **antes** dos scripts FrameZero:
   ```
   ensure oxmysql
   ensure vrp            # ou es_extended, qb-core, qbx_core
   ensure framezero_bridge
   ```
3. Ligue o servidor. No console aparece o que foi detectado:
   ```
   [framezero] bridge by piercer
   [framezero] v1.0.0 iniciada · framework: vrp · vrpex · inventário: framework · veículos: nation-garages
   ```

Não é preciso editar o `fxmanifest` nem descomentar `@vrp/lib/utils.lua`: a bridge carrega a lib do vRP sozinha e lê os arquivos do `vrp` para descobrir quais funções a sua base tem.

## CONFIGURAÇÃO
Tudo em `config.lua`. Em geral nada precisa mudar (`"auto"` em tudo). Ajustes comuns:

| Opção | Para quê |
|---|---|
| `Config.Framework` | Forçar um framework se a detecção errar |
| `Config.Vrp.NotifyStyle` | `vrpex` ("sucesso") · `creative` ("verde") · `enchanted` |
| `Config.Vrp.CashItem` | Item de dinheiro no Creative (`dollars`) |
| `Config.DirtyMoney` | Conta ou item de dinheiro sujo |
| `Config.Target` | `custom` para usar o seu target (veja abaixo) |

## Base modificada? Use `custom/`

`custom/server.lua` e `custom/client.lua` **nunca são substituídos** nas atualizações. Qualquer função da API pode ser trocada:

```lua
-- custom/server.lua
framezero.Custom.GiveVehicle = function(target, model, opts)
    local id = framezero.API.GetPlayerId(target) or tostring(target)
    local plate = (opts and opts.plate) or framezero.API.GeneratePlate()
    exports["minha_garagem"]:AddVehicle(id, model, plate)
    return plate
end
```

### Target próprio

```lua
-- custom/client.lua
framezero.CustomTarget = {
    addSphere = function(id, coords, radius, options) --[[ seu target ]] end,
    addModel  = function(id, models, options) --[[ opcional ]] end,
    remove    = function(id) --[[ seu target ]] end,
}
```

---

## Para desenvolvedores

```lua
-- fxmanifest.lua do script
shared_script "@framezero_bridge/import.lua"
```

### Servidor

| Função | Retorno |
|---|---|
| `framezero.GetPlayerId(src)` | id do personagem (string): identifier · citizenid · user_id |
| `framezero.GetSource(id)` / `framezero.GetPlayers()` | source / lista de sources |
| `framezero.GetName(src)` / `framezero.GetJob(src)` | nome / `{ name, label, grade, onDuty }` |
| `framezero.HasPermission(src, perm)` | grupo, permissão, job ou ACE |
| `framezero.GetMoney(src, conta)` | conta: `cash` · `bank` · `dirty` |
| `framezero.AddMoney(src, valor, conta)` / `RemoveMoney` | `true`/`false` |
| `framezero.GetItemCount(src, item)` / `HasItem(src, item, qtd)` | número / bool |
| `framezero.AddItem(src, item, qtd, metadata)` / `RemoveItem` / `CanCarry` | bool |
| `framezero.GetInventory(src)` | `{ name, label, amount, slot?, metadata? }[]` |
| `framezero.GiveVehicle(src ou id, modelo, { plate?, garage? })` | placa ou `false` |
| `framezero.HasVehicle(src ou id, modelo)` | bool |
| `framezero.Notify(src, tipo, msg, ms)` | tipo: `success` · `error` · `warning` · `info` |
| `framezero.Prompt(src, título, placeholder)` | texto ou `nil` |
| `framezero.Request(src, msg, segundos)` | `true` se aceitou (teclas Y/N) |
| `framezero.Revive(src)` | - |
| `framezero.OnPlayerLoaded(fn(src, id))` / `OnPlayerUnloaded(fn(src))` | - |
| `framezero.RegisterCallback(nome, fn(src, ...))` | o cliente chama com `TriggerCallback` |
| `framezero.DB.Query/Single/Scalar/Insert/Update(sql, params)` | oxmysql · mysql-async · ghmattimysql |
| `framezero.Info()` | framework, inventário, garagem e variante vRP detectados |

### Cliente

| Função | Retorno |
|---|---|
| `framezero.Notify(tipo, msg, ms)` | - |
| `framezero.Progress(texto, ms, { canCancel? })` | `true` se completou |
| `framezero.ShowText(texto)` / `HideText()` | - |
| `framezero.AddSphere(id, coords, raio, opções)` / `AddModel(id, modelos, opções)` / `RemoveTarget(id)` | - |
| `framezero.TriggerCallback(nome, timeoutMs, ...)` | resposta do servidor |
| `framezero.OnPlayerLoaded(fn)` | - |

Opções de target: `{ label, icon?, distance?, onSelect = function(entity) end, canInteract? = function(entity) end }`.

### Exemplo

```lua
-- server
framezero.RegisterCallback("fz_farm:craft", function(src)
    if not framezero.RemoveItem(src, "polvora", 5) then
        framezero.Notify(src, "error", "Você precisa de 5 pólvoras.")
        return false
    end
    framezero.AddItem(src, "municao_pistola", 30)
    return true
end)

-- client
framezero.AddSphere("fz_farm:mesa", vec3(452.1, -980.2, 30.6), 1.5, {
    {
        label = "Fabricar munição",
        icon = "fas fa-hammer",
        onSelect = function()
            if framezero.Progress("Fabricando munição", 5000, { canCancel = true }) then
                local ok = framezero.TriggerCallback("fz_farm:craft")
                if ok then framezero.Notify("success", "Munição fabricada!") end
            end
        end,
    },
})
```

---

Dúvida ou bug? Abre um ticket no Discord da FrameZero.
