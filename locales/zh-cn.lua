Locales = Locales or {}

Locales["zh-cn"] = {
    started = "v%s 已启动 · 框架: ^5%s^0 · 背包: ^5%s^0 · 载具: ^5%s^0 · 通知: ^5%s^0",
    adapter_unknown = "%s 的适配器 '%s' 不存在。请检查 config.lua 中的选项。",
    adapter_none = "未检测到 %s。使用 '%s'。",
    adapter_failed = "启动 %s 适配器 '%s' 失败。",
    vrp_missing = "在资源 '%s' 中找不到 lib/utils.lua。",
    vrp_function_missing = "此框架中不存在 vRP 函数 '%s'。请在 custom/server.lua 中调整。",
    vrp_flavor = "检测到 vRP 框架: ^5%s^0（找到 %d 个函数）。",
    db_missing = "未找到 MySQL 驱动（oxmysql、mysql-async 或 ghmattimysql）。",
    not_supported = "'%s' 不受 '%s' 支持。请在 custom/server.lua 中实现。",
    update_available = "有新版本: ^2%s^0（当前 %s）。请在商店的 Discord 下载。",
    start_order = "请在 server.cfg 中于框架之后启动 bridge（例如: 先 ensure %s 再 ensure framezero_bridge）。",
    rate_limited = "玩家 %s 请求过多，已忽略。",

    prompt_title = "输入",
    prompt_confirm = "确认",
    prompt_cancel = "取消",
    request_title = "请求",
    accept = "接受",
    decline = "拒绝",
    keymap_accept = "接受请求",
    keymap_decline = "拒绝请求",
    interact = "按 ~INPUT_CONTEXT~ %s",
}
