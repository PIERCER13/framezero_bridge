Locales = Locales or {}

Locales["ru"] = {
    started = "v%s запущена · фреймворк: ^5%s^0 · инвентарь: ^5%s^0 · транспорт: ^5%s^0 · уведомления: ^5%s^0",
    adapter_unknown = "Адаптер '%s' для %s не существует. Проверьте настройки в config.lua.",
    adapter_none = "%s не найден. Используется '%s'.",
    adapter_failed = "Не удалось запустить адаптер %s '%s'.",
    vrp_missing = "lib/utils.lua не найден в ресурсе '%s'.",
    vrp_function_missing = "Функции vRP '%s' нет в этой базе. Настройте её в custom/server.lua.",
    vrp_flavor = "Обнаружена база vRP: ^5%s^0 (найдено функций: %d).",
    db_missing = "Драйвер MySQL не найден (oxmysql, mysql-async или ghmattimysql).",
    not_supported = "'%s' не поддерживается '%s'. Реализуйте в custom/server.lua.",
    update_available = "Доступна новая версия: ^2%s^0 (у вас %s). Скачайте её в Discord магазина.",
    start_order = "Запускайте bridge ПОСЛЕ фреймворка в server.cfg (например: ensure %s перед ensure framezero_bridge).",
    rate_limited = "Слишком много запросов от игрока %s; игнорируется.",

    prompt_title = "Введите",
    prompt_confirm = "Подтвердить",
    prompt_cancel = "Отмена",
    request_title = "Запрос",
    accept = "Принять",
    decline = "Отклонить",
    keymap_accept = "Принять запрос",
    keymap_decline = "Отклонить запрос",
    interact = "Нажмите ~INPUT_CONTEXT~, чтобы %s",
}
