---@diagnostic disable: lowercase-global

local function en_zh(en, zh)
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = en_zh("lol ping", "lol标记")
author = "Jerry"
description = ""

version = "1.0"
forumthread = ""
api_version = 10

dst_compatible = true
all_clients_require_mod = true
priority = -9999

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
    "lolping"
}

local keys = {"TAB","KP_0","KP_1","KP_2","KP_3","KP_4","KP_5","KP_6","KP_7","KP_8","KP_9","KP_PERIOD","KP_DIVIDE","KP_MULTIPLY","KP_MINUS","KP_PLUS","KP_ENTER","KP_EQUALS","MINUS","EQUALS","SPACE","ENTER",--[["ESCAPE",]]"HOME","INSERT","DELETE","END","PAUSE","PRINT","CAPSLOCK","SCROLLOCK","RSHIFT","LSHIFT","RCTRL","LCTRL","RALT","LALT","LSUPER","RSUPER","ALT","CTRL","SHIFT","BACKSPACE","PERIOD","SLASH","SEMICOLON","LEFTBRACKET","BACKSLASH","RIGHTBRACKET","TILDE","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","UP","DOWN","RIGHT","LEFT","PAGEUP","PAGEDOWN","0","1","2","3","4","5","6","7","8","9"}
local keylist = {}
for i = 1, #keys do
    keylist[i] = {description = keys[i], data = "KEY_" .. keys[i]}
end
keylist[#keylist + 1] = {description = en_zh("Default", "默认"), data = false}

configuration_options = {
    -- {
    --     name = "PingKey",
    --     hover = en_zh("Select down which key to display wheel(Disable it Alt or Ctrl)", "选择按住什么按键出现选择轮盘(禁用是Alt或者Ctrl)"),
    --     label = en_zh("Ping Key", "标记按键"),
    --     is_keylist = true,  -- Lazy Controls协议, 快速选择按键, Tony yyds
    --     options = keylist,
    --     default = false
    -- },
}