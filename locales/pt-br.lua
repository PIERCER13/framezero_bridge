-- framezero_bridge / locales/pt-br.lua

Locales = Locales or {}

Locales["pt-br"] = {
    started = "v%s iniciada · framework: ^5%s^0 · inventário: ^5%s^0 · veículos: ^5%s^0 · notificação: ^5%s^0",
    adapter_unknown = "Adaptador '%s' de %s não existe. Veja as opções no config.lua.",
    adapter_none = "Nenhum %s detectado. Usando '%s'.",
    adapter_failed = "Falha ao iniciar o adaptador %s '%s'.",
    vrp_missing = "Não encontrei lib/utils.lua no resource '%s'.",
    vrp_function_missing = "A função vRP '%s' não existe nesta base. Ajuste em custom/server.lua.",
    vrp_flavor = "Base vRP detectada: ^5%s^0 (%d funções encontradas).",
    db_missing = "Nenhum driver MySQL encontrado (oxmysql, mysql-async ou ghmattimysql).",
    not_supported = "'%s' não é suportado por '%s'. Implemente em custom/server.lua.",
    update_available = "Nova versão disponível: ^2%s^0 (você usa %s). Baixe no Discord da loja.",
    start_order = "Inicie a bridge DEPOIS do framework no server.cfg (ex.: ensure %s antes de ensure framezero_bridge).",
    rate_limited = "Muitas requisições do jogador %s; ignorando.",

    prompt_title = "Digite",
    prompt_confirm = "Confirmar",
    prompt_cancel = "Cancelar",
    request_title = "Solicitação",
    accept = "Aceitar",
    decline = "Recusar",
    keymap_accept = "Aceitar solicitação",
    keymap_decline = "Recusar solicitação",
    interact = "Pressione ~INPUT_CONTEXT~ para %s",
}
