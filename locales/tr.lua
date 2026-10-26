Locales = Locales or {}

Locales["tr"] = {
    started = "v%s başlatıldı · framework: ^5%s^0 · envanter: ^5%s^0 · araçlar: ^5%s^0 · bildirim: ^5%s^0",
    adapter_unknown = "%s için '%s' adaptörü yok. config.lua içindeki seçenekleri kontrol et.",
    adapter_none = "%s bulunamadı. '%s' kullanılıyor.",
    adapter_failed = "%s adaptörü '%s' başlatılamadı.",
    vrp_missing = "'%s' kaynağında lib/utils.lua bulunamadı.",
    vrp_function_missing = "vRP fonksiyonu '%s' bu altyapıda yok. custom/server.lua içinde düzenle.",
    vrp_flavor = "vRP altyapısı bulundu: ^5%s^0 (%d fonksiyon bulundu).",
    db_missing = "MySQL sürücüsü bulunamadı (oxmysql, mysql-async veya ghmattimysql).",
    not_supported = "'%s', '%s' tarafından desteklenmiyor. custom/server.lua içinde uygula.",
    update_available = "Yeni sürüm mevcut: ^2%s^0 (sendeki %s). Mağazanın Discord'undan indir.",
    start_order = "Bridge'i server.cfg içinde framework'ten SONRA başlat (örn: ensure %s, sonra ensure framezero_bridge).",
    rate_limited = "%s oyuncusundan çok fazla istek; yok sayılıyor.",

    prompt_title = "Yaz",
    prompt_confirm = "Onayla",
    prompt_cancel = "İptal",
    request_title = "İstek",
    accept = "Kabul et",
    decline = "Reddet",
    keymap_accept = "İsteği kabul et",
    keymap_decline = "İsteği reddet",
    interact = "%s için ~INPUT_CONTEXT~ tuşuna bas",
}
