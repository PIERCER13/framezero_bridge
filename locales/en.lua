Locales = Locales or {}

Locales["en"] = {
    started = "v%s started · framework: ^5%s^0 · inventory: ^5%s^0 · vehicles: ^5%s^0 · notify: ^5%s^0",
    adapter_unknown = "Adapter '%s' for %s does not exist. Check the options in config.lua.",
    adapter_none = "No %s detected. Using '%s'.",
    adapter_failed = "Failed to start %s adapter '%s'.",
    vrp_missing = "Could not find lib/utils.lua in resource '%s'.",
    vrp_function_missing = "vRP function '%s' does not exist in this base. Adjust it in custom/server.lua.",
    vrp_flavor = "vRP base detected: ^5%s^0 (%d functions found).",
    db_missing = "No MySQL driver found (oxmysql, mysql-async or ghmattimysql).",
    not_supported = "'%s' is not supported by '%s'. Implement it in custom/server.lua.",
    update_available = "New version available: ^2%s^0 (you have %s). Download it on the store Discord.",
    start_order = "Start the bridge AFTER the framework in server.cfg (e.g. ensure %s before ensure framezero_bridge).",
    rate_limited = "Too many requests from player %s; ignoring.",

    prompt_title = "Type",
    prompt_confirm = "Confirm",
    prompt_cancel = "Cancel",
    request_title = "Request",
    accept = "Accept",
    decline = "Decline",
    keymap_accept = "Accept request",
    keymap_decline = "Decline request",
    interact = "Press ~INPUT_CONTEXT~ to %s",
}
