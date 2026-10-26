Locales = Locales or {}

Locales["pl"] = {
    started = "v%s uruchomiona · framework: ^5%s^0 · ekwipunek: ^5%s^0 · pojazdy: ^5%s^0 · powiadomienia: ^5%s^0",
    adapter_unknown = "Adapter '%s' dla %s nie istnieje. Sprawdź opcje w config.lua.",
    adapter_none = "Nie wykryto %s. Używam '%s'.",
    adapter_failed = "Nie udało się uruchomić adaptera %s '%s'.",
    vrp_missing = "Nie znaleziono lib/utils.lua w zasobie '%s'.",
    vrp_function_missing = "Funkcja vRP '%s' nie istnieje w tej bazie. Dostosuj ją w custom/server.lua.",
    vrp_flavor = "Wykryto bazę vRP: ^5%s^0 (znaleziono %d funkcji).",
    db_missing = "Nie znaleziono sterownika MySQL (oxmysql, mysql-async lub ghmattimysql).",
    not_supported = "'%s' nie jest obsługiwane przez '%s'. Zaimplementuj to w custom/server.lua.",
    update_available = "Dostępna nowa wersja: ^2%s^0 (masz %s). Pobierz ją na Discordzie sklepu.",
    start_order = "Uruchom bridge PO frameworku w server.cfg (np. ensure %s przed ensure framezero_bridge).",
    rate_limited = "Zbyt wiele żądań od gracza %s; ignoruję.",

    prompt_title = "Wpisz",
    prompt_confirm = "Potwierdź",
    prompt_cancel = "Anuluj",
    request_title = "Prośba",
    accept = "Akceptuj",
    decline = "Odrzuć",
    keymap_accept = "Akceptuj prośbę",
    keymap_decline = "Odrzuć prośbę",
    interact = "Naciśnij ~INPUT_CONTEXT~, aby %s",
}
