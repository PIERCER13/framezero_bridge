Locales = Locales or {}

Locales["de"] = {
    started = "v%s gestartet · Framework: ^5%s^0 · Inventar: ^5%s^0 · Fahrzeuge: ^5%s^0 · Benachrichtigung: ^5%s^0",
    adapter_unknown = "Adapter '%s' für %s existiert nicht. Prüfe die Optionen in config.lua.",
    adapter_none = "Kein %s erkannt. Verwende '%s'.",
    adapter_failed = "Adapter %s '%s' konnte nicht gestartet werden.",
    vrp_missing = "lib/utils.lua in Ressource '%s' nicht gefunden.",
    vrp_function_missing = "vRP-Funktion '%s' existiert in dieser Base nicht. Passe sie in custom/server.lua an.",
    vrp_flavor = "vRP-Base erkannt: ^5%s^0 (%d Funktionen gefunden).",
    db_missing = "Kein MySQL-Treiber gefunden (oxmysql, mysql-async oder ghmattimysql).",
    not_supported = "'%s' wird von '%s' nicht unterstützt. Implementiere es in custom/server.lua.",
    update_available = "Neue Version verfügbar: ^2%s^0 (du hast %s). Lade sie im Discord des Shops herunter.",
    start_order = "Starte die Bridge NACH dem Framework in der server.cfg (z. B. ensure %s vor ensure framezero_bridge).",
    rate_limited = "Zu viele Anfragen von Spieler %s; wird ignoriert.",

    prompt_title = "Eingabe",
    prompt_confirm = "Bestätigen",
    prompt_cancel = "Abbrechen",
    request_title = "Anfrage",
    accept = "Annehmen",
    decline = "Ablehnen",
    keymap_accept = "Anfrage annehmen",
    keymap_decline = "Anfrage ablehnen",
    interact = "Drücke ~INPUT_CONTEXT~, um %s",
}
