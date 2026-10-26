Locales = Locales or {}

Locales["fr"] = {
    started = "v%s démarrée · framework : ^5%s^0 · inventaire : ^5%s^0 · véhicules : ^5%s^0 · notification : ^5%s^0",
    adapter_unknown = "L'adaptateur '%s' pour %s n'existe pas. Vérifiez les options dans config.lua.",
    adapter_none = "Aucun %s détecté. Utilisation de '%s'.",
    adapter_failed = "Échec du démarrage de l'adaptateur %s '%s'.",
    vrp_missing = "lib/utils.lua introuvable dans la ressource '%s'.",
    vrp_function_missing = "La fonction vRP '%s' n'existe pas sur cette base. Ajustez-la dans custom/server.lua.",
    vrp_flavor = "Base vRP détectée : ^5%s^0 (%d fonctions trouvées).",
    db_missing = "Aucun driver MySQL trouvé (oxmysql, mysql-async ou ghmattimysql).",
    not_supported = "'%s' n'est pas pris en charge par '%s'. Implémentez-le dans custom/server.lua.",
    update_available = "Nouvelle version disponible : ^2%s^0 (vous avez %s). Téléchargez-la sur le Discord de la boutique.",
    start_order = "Démarrez le bridge APRÈS le framework dans server.cfg (ex. : ensure %s avant ensure framezero_bridge).",
    rate_limited = "Trop de requêtes du joueur %s ; ignorées.",

    prompt_title = "Saisir",
    prompt_confirm = "Confirmer",
    prompt_cancel = "Annuler",
    request_title = "Demande",
    accept = "Accepter",
    decline = "Refuser",
    keymap_accept = "Accepter la demande",
    keymap_decline = "Refuser la demande",
    interact = "Appuyez sur ~INPUT_CONTEXT~ pour %s",
}
