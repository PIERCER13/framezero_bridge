# Changelog

## 1.3.0
- Licença por token: a chave fica no resource `framezero_token` (ou num `token.lua` dentro do próprio script), não mais no config
- `framezero.License.Protect(resource[, key][, onFail])` resolve a chave sozinho (token local -> framezero_token)
- Licença presa em IP + porta: o script informa a porta do servidor (`netPort`), então a mesma licença não valida em vários servidores na mesma máquina

## 1.2.1
- Novos idiomas: polonês, turco, holandês e chinês

## 1.2.0
- API passa a se chamar `framezero`: `exports.framezero_bridge:GetFramezero()` (global `framezero` com o import.lua)
- Novos idiomas: francês, alemão, italiano e russo
- Comentários do código revisados

## 1.1.0
- Novos frameworks: tnet, ND_Core e ox_core
- ESX 1.x e QBCore antigo
- Novos inventários: tnet_inventory, codem-inventory, core_inventory e ak47_inventory
- Notificações okokNotify e mythic_notify detectadas sozinhas
- Target próprio pelo custom/client.lua

## 1.0.0
- Primeira versão
- ESX, QBCore, Qbox, vRP, vRPex e Creative detectados sozinhos
- Lê as funções do vrp, então funciona em bases modificadas
- ox_inventory, qs-inventory, nation-garages e qbx_vehicles
- Pasta custom/ para adaptar a base
