# FrameZero Bridge

Resource multi-framework dos scripts da **FrameZero**. Instala uma vez e todos os scripts da loja rodam no seu framework.

**Frameworks:** ESX (Legacy e 1.x) · QBCore (novo e antigo) · Qbox · vRP · vRPex · Creative (v5, v6, Network, Enchanted e bases modificadas) · tnet · ND_Core · ox_core
**Inventários:** ox_inventory · qs-inventory · tnet_inventory · codem-inventory · core_inventory · ak47_inventory · padrão do framework
**Garagens:** nation-garages · qbx_vehicles · tabela padrão do framework
**Extras:** ox_lib (notificação, progresso, texto) · okokNotify · mythic_notify · ox_target · qb-target · target próprio

---

## Instalação

1. Coloque a pasta `framezero_bridge` em `resources`.
2. No `server.cfg`, **depois** do framework e do banco e **antes** dos scripts FrameZero:
   ```
   ensure oxmysql
   ensure vrp            # ou es_extended, qb-core, qbx_core
   ensure framezero_bridge
   ensure fz_seu_script
   ```
3. Ligue o servidor. No console aparece o que foi detectado:
   ```
   [framezero] bridge by piercer
   [framezero] v1.0.0 iniciada · framework: vrp · vrpex · inventário: framework · veículos: nation-garages
   ```

Não é preciso editar o `fxmanifest` nem descomentar `@vrp/lib/utils.lua`: a bridge carrega a lib do vRP sozinha e lê os arquivos do `vrp` para descobrir quais funções a sua base tem.

## Configuração

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
FZ.Custom.GiveVehicle = function(target, model, opts)
    local id = FZ.API.GetPlayerId(target) or tostring(target)
    local plate = (opts and opts.plate) or FZ.API.GeneratePlate()
    exports["minha_garagem"]:AddVehicle(id, model, plate)
    return plate
end
```

### Target próprio

```lua
-- custom/client.lua
FZ.CustomTarget = {
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
| `Bridge.GetPlayerId(src)` | id do personagem (string): identifier · citizenid · user_id |
| `Bridge.GetSource(id)` / `Bridge.GetPlayers()` | source / lista de sources |
| `Bridge.GetName(src)` / `Bridge.GetJob(src)` | nome / `{ name, label, grade, onDuty }` |
| `Bridge.HasPermission(src, perm)` | grupo, permissão, job ou ACE |
| `Bridge.GetMoney(src, conta)` | conta: `cash` · `bank` · `dirty` |
| `Bridge.AddMoney(src, valor, conta)` / `RemoveMoney` | `true`/`false` |
| `Bridge.GetItemCount(src, item)` / `HasItem(src, item, qtd)` | número / bool |
| `Bridge.AddItem(src, item, qtd, metadata)` / `RemoveItem` / `CanCarry` | bool |
| `Bridge.GetInventory(src)` | `{ name, label, amount, slot?, metadata? }[]` |
| `Bridge.GiveVehicle(src ou id, modelo, { plate?, garage? })` | placa ou `false` |
| `Bridge.HasVehicle(src ou id, modelo)` | bool |
| `Bridge.Notify(src, tipo, msg, ms)` | tipo: `success` · `error` · `warning` · `info` |
| `Bridge.Prompt(src, título, placeholder)` | texto ou `nil` |
| `Bridge.Request(src, msg, segundos)` | `true` se aceitou (teclas Y/N) |
| `Bridge.Revive(src)` | - |
| `Bridge.OnPlayerLoaded(fn(src, id))` / `OnPlayerUnloaded(fn(src))` | - |
| `Bridge.RegisterCallback(nome, fn(src, ...))` | o cliente chama com `TriggerCallback` |
| `Bridge.DB.Query/Single/Scalar/Insert/Update(sql, params)` | oxmysql · mysql-async · ghmattimysql |
| `Bridge.Info()` | framework, inventário, garagem e variante vRP detectados |

### Cliente

| Função | Retorno |
|---|---|
| `Bridge.Notify(tipo, msg, ms)` | - |
| `Bridge.Progress(texto, ms, { canCancel? })` | `true` se completou |
| `Bridge.ShowText(texto)` / `HideText()` | - |
| `Bridge.AddSphere(id, coords, raio, opções)` / `AddModel(id, modelos, opções)` / `RemoveTarget(id)` | - |
| `Bridge.TriggerCallback(nome, timeoutMs, ...)` | resposta do servidor |
| `Bridge.OnPlayerLoaded(fn)` | - |

Opções de target: `{ label, icon?, distance?, onSelect = function(entity) end, canInteract? = function(entity) end }`.

### Exemplo

```lua
-- server
Bridge.RegisterCallback("fz_farm:craft", function(src)
    if not Bridge.RemoveItem(src, "polvora", 5) then
        Bridge.Notify(src, "error", "Você precisa de 5 pólvoras.")
        return false
    end
    Bridge.AddItem(src, "municao_pistola", 30)
    return true
end)

-- client
Bridge.AddSphere("fz_farm:mesa", vec3(452.1, -980.2, 30.6), 1.5, {
    {
        label = "Fabricar munição",
        icon = "fas fa-hammer",
        onSelect = function()
            if Bridge.Progress("Fabricando munição", 5000, { canCancel = true }) then
                local ok = Bridge.TriggerCallback("fz_farm:craft")
                if ok then Bridge.Notify("success", "Munição fabricada!") end
            end
        end,
    },
})
```

---

Dúvida ou bug? Abre um ticket no Discord da FrameZero.
