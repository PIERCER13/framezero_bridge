Locales = Locales or {}

Locales["es"] = {
    started = "v%s iniciada · framework: ^5%s^0 · inventario: ^5%s^0 · vehículos: ^5%s^0 · notificación: ^5%s^0",
    adapter_unknown = "El adaptador '%s' de %s no existe. Revisa las opciones en config.lua.",
    adapter_none = "Ningún %s detectado. Usando '%s'.",
    adapter_failed = "Error al iniciar el adaptador %s '%s'.",
    vrp_missing = "No encontré lib/utils.lua en el resource '%s'.",
    vrp_function_missing = "La función vRP '%s' no existe en esta base. Ajústala en custom/server.lua.",
    vrp_flavor = "Base vRP detectada: ^5%s^0 (%d funciones encontradas).",
    db_missing = "Ningún driver MySQL encontrado (oxmysql, mysql-async o ghmattimysql).",
    not_supported = "'%s' no es compatible con '%s'. Impleméntalo en custom/server.lua.",
    update_available = "Nueva versión disponible: ^2%s^0 (tienes %s). Descárgala en el Discord de la tienda.",
    start_order = "Inicia el bridge DESPUÉS del framework en server.cfg (ej.: ensure %s antes de ensure framezero_bridge).",
    rate_limited = "Demasiadas solicitudes del jugador %s; ignorando.",

    prompt_title = "Escribe",
    prompt_confirm = "Confirmar",
    prompt_cancel = "Cancelar",
    request_title = "Solicitud",
    accept = "Aceptar",
    decline = "Rechazar",
    keymap_accept = "Aceptar solicitud",
    keymap_decline = "Rechazar solicitud",
    interact = "Pulsa ~INPUT_CONTEXT~ para %s",
}
