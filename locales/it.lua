Locales = Locales or {}

Locales["it"] = {
    started = "v%s avviata · framework: ^5%s^0 · inventario: ^5%s^0 · veicoli: ^5%s^0 · notifiche: ^5%s^0",
    adapter_unknown = "L'adattatore '%s' per %s non esiste. Controlla le opzioni in config.lua.",
    adapter_none = "Nessun %s rilevato. Uso '%s'.",
    adapter_failed = "Impossibile avviare l'adattatore %s '%s'.",
    vrp_missing = "lib/utils.lua non trovato nella risorsa '%s'.",
    vrp_function_missing = "La funzione vRP '%s' non esiste in questa base. Modificala in custom/server.lua.",
    vrp_flavor = "Base vRP rilevata: ^5%s^0 (%d funzioni trovate).",
    db_missing = "Nessun driver MySQL trovato (oxmysql, mysql-async o ghmattimysql).",
    not_supported = "'%s' non è supportato da '%s'. Implementalo in custom/server.lua.",
    update_available = "Nuova versione disponibile: ^2%s^0 (hai la %s). Scaricala dal Discord dello store.",
    start_order = "Avvia il bridge DOPO il framework nel server.cfg (es.: ensure %s prima di ensure framezero_bridge).",
    rate_limited = "Troppe richieste dal giocatore %s; ignorate.",

    prompt_title = "Scrivi",
    prompt_confirm = "Conferma",
    prompt_cancel = "Annulla",
    request_title = "Richiesta",
    accept = "Accetta",
    decline = "Rifiuta",
    keymap_accept = "Accetta richiesta",
    keymap_decline = "Rifiuta richiesta",
    interact = "Premi ~INPUT_CONTEXT~ per %s",
}
