Locales = Locales or {}

Locales["nl"] = {
    started = "v%s gestart · framework: ^5%s^0 · inventaris: ^5%s^0 · voertuigen: ^5%s^0 · meldingen: ^5%s^0",
    adapter_unknown = "Adapter '%s' voor %s bestaat niet. Controleer de opties in config.lua.",
    adapter_none = "Geen %s gevonden. '%s' wordt gebruikt.",
    adapter_failed = "Kon adapter %s '%s' niet starten.",
    vrp_missing = "lib/utils.lua niet gevonden in resource '%s'.",
    vrp_function_missing = "vRP-functie '%s' bestaat niet in deze base. Pas het aan in custom/server.lua.",
    vrp_flavor = "vRP-base gevonden: ^5%s^0 (%d functies gevonden).",
    db_missing = "Geen MySQL-driver gevonden (oxmysql, mysql-async of ghmattimysql).",
    not_supported = "'%s' wordt niet ondersteund door '%s'. Implementeer het in custom/server.lua.",
    update_available = "Nieuwe versie beschikbaar: ^2%s^0 (jij hebt %s). Download hem in de Discord van de winkel.",
    start_order = "Start de bridge NA het framework in server.cfg (bijv. ensure %s vóór ensure framezero_bridge).",
    rate_limited = "Te veel verzoeken van speler %s; genegeerd.",

    prompt_title = "Typ",
    prompt_confirm = "Bevestigen",
    prompt_cancel = "Annuleren",
    request_title = "Verzoek",
    accept = "Accepteren",
    decline = "Weigeren",
    keymap_accept = "Verzoek accepteren",
    keymap_decline = "Verzoek weigeren",
    interact = "Druk op ~INPUT_CONTEXT~ om %s",
}
