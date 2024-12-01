---@diagnostic disable: lowercase-global
name = "英雄联盟武器"
description = [[目前更新武器：
前期武器：【多兰之刃】【多兰之盾】【萃取】【黑曜石锋刃】【铁刺鞭】【提亚马特】【耀光】
战士武器：【黑色切割者】【破败王者之刃】【神圣分离者】【破舰者】【巨型九头蛇】【渴血战斧】
【挺进破坏者】
护甲装备：【狂徒铠甲】【霸王血铠】【恶魔之拥】
法术武器：【纳什之牙】【瑞莱的冰晶节杖】【峡谷制造者】
特殊装备：【多兰之戒】【女神之泪】【心之钢】【三相之力】
]]
author = "艾趣44，zzzzzzzs，醨，LAN，HPMY，C"
forumthread = ""
priority = 0
api_version = 6
api_version_dst = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
hamlet_compatible = false
all_clients_require_mod = true
icon_atlas = "modicon.xml"
icon = "modicon.tex"
server_filter_tags = {}
version = "3.5.4"
local configuration = {
    {
        name = "gallopbreakermusic",
        label = "Hullbreaker Music",
        default = true,
        hover = "gallopbreakermusic_hover",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false}
        }
    }, 
    {
        name = "bloodaxe_health",
        label = "Thirsting Slash Health Delta",
        default = 3,
        hover = "bloodaxe_health_hover",
        options = {
            {description = "-3", data = -3},
            {description = "3", data = 3},
            {description = "5", data = 5},
            {description = "8", data = 8},
        }
    }, 
    {name = "divide_heartsteel",default = true, hover = "", options = {}}, 
    {
        name = "limit_lol_heartsteel",
        label = "heartsteel limit",
        default = true,
        hover = "limit_lol_heartsteel_hover",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false}
        }
    }, {
        name = "limit_lol_heartsteel_transform_scale",
        label = "heartsteel scale limit",
        default = 1,
        hover = "limit_lol_heartsteel_transform_scale_hover",
        options = {
            {description = "无", data = 0},
            {description = "40%", data = 1},
            {description = "无限", data = 2},
        }
    },
    {
        name = "limit_lol_heartsteel_equipslot",
        label = "heartsteel equipslot",
        default = 1,
        hover = "limit_lol_heartsteel_equipslot_hover",
        options = {
            {description = "项链", data = 1}, 
            {description = "身体", data = 2}
        }
    },
    {
        name = "limit_lol_heartsteel_blueprint_dropby",
        label = "heartsteel blueprint itemdrop",
        default = 2,
        hover = "limit_lol_heartsteel_blueprint_dropby_hover",
        options = {
            {description = "普通克劳斯", data = 1}, 
            {description = "狂暴克劳斯", data = 2}
        }
    }

}

translation = {
    {
        matchLanguage = function(lang)
            return lang == "zh" or lang == "zht" or lang == "zhr" or lang ==
                       "chs" or lang == "cht"
        end,
        translateFunction = function(key)
            return translation[1].dict[key] or nil
        end,
        dict = {
            name = name,
            language = "语言",
            author = author,
            unusable = "不可用",
            description = description,
            version = "",
            ["Accord to the game"] = "跟随游戏设置",
            ["Set Language"] = "设置语言",
            No = "否",
            Yes = "是",
            Client = "客户端",
            gallopbreakermusic = "破舰者音乐",
            gallopbreakermusic_hover = "是否开启手持破舰者音乐",
            limit_lol_heartsteel = '层数限制',
            limit_lol_heartsteel_hover = '是:最大为400层\n否:无限制',
            limit_lol_heartsteel_transform_scale = '体型上限',
            limit_lol_heartsteel_transform_scale_hover = '不改变/40%/无限',
            limit_lol_heartsteel_equipslot = '栏位',
            limit_lol_heartsteel_equipslot_hover = '',
            limit_lol_heartsteel_blueprint_dropby = '蓝图掉落',
            limit_lol_heartsteel_blueprint_dropby_hover = '',
            divide_heartsteel = '心之钢配置',
bloodaxe_health="渴血战斧吸血",
bloodaxe_health_hover="",
        }
    }, {
        matchLanguage = function(lang) return lang == "en" end,
        dict = {
            name = name,
            description = description,
            version = [[]],
            author = author,
            gallopbreakermusic_hover = "Enable this and you will hear the music of Hullbreaker",
            limit_lol_heartsteel = 'Limit the number of Heartsteel layers',
            limit_lol_heartsteel_hover = 'Yes: Maximum 400 layers\nNo: No limit',
            limit_lol_heartsteel_transform_scale = 'Heartsteel change the size of the Player', 
            limit_lol_heartsteel_transform_scale_hover = 'No Change/40%/Infinite',
            limit_lol_heartsteel_equipslot = 'equipslot',
            limit_lol_heartsteel_equipslot_hover = '',
            limit_lol_heartsteel_blueprint_dropby = 'blueprint itemdrop',
            limit_lol_heartsteel_blueprint_dropby_hover = '',
            divide_heartsteel = 'HeartSteel Config',
bloodaxe_health_hover="",
        },
        translateFunction = function(key)
            return translation[2].dict[key] or key
        end
    }
}
local function makeConfigurations(conf, translate, baseTranslate, language)
    local index = 0
    local config = {}
    local function trans(str)
        return str and (translate(str) or baseTranslate(str)) or nil
    end

    local string = ""
    for i = 1, #conf do
        local v = conf[i]
        if not v.disabled then
            index = index + 1
            config[index] = {
                name = v.name or "",
                label = (v.label and translate(v.label)) or translate(v.name) or
                    trans(v.label or v.name),
                hover = v.name and v.name ~= "" and (v.hover and trans(v.hover)) or
                    nil,
                default = v.default,
                options = v.name and v.name ~= "" and
                    {{description = "", data = ""}} or nil,
                client = v.client
            }
            if v.unusable then
                config[index].label = config[index].label .. "[" ..
                                          trans("unusable") .. "]"
            end
            if v.key then
                if language == "zh" then
                    config[index].options = input_table_zh
                else
                    config[index].options = input_table_en
                end
                config[index].iskey = true
                config[index].default = config[index].default or 0
            elseif v.options then
                for j = 1, #v.options do
                    local opt = v.options[j]
                    config[index].options[j] = {
                        description = opt.description and trans(opt.description) or
                            "",
                        hover = opt.hover and trans(opt.hover) or "",
                        data = opt.data
                    }
                end
            end
        end
    end
    configuration_options = config
end

local function makeInfo(translation)
    local localName = translation("name")
    local localDescription = translation("description")
    local localVersionInfo = translation("version") or ""
    local localAuthor = translation("author")
    if localVersionInfo ~= "" then
        if not localDescription then localDescription = "" end
        localDescription = localVersionInfo .. "\n" .. localDescription
    end
    if localName then name = localName end
    if localAuthor then author = localAuthor end
    if localDescription then description = localDescription end
end

local function getLang()
    local lang = locale or "en"
    return lang
end

local function generate()
    local lang = getLang()
    local localTranslation = translation[#translation].translateFunction
    local baseTranslation = translation[#translation].translateFunction
    for i = 1, #translation - 1 do
        local v = translation[i]
        if v.matchLanguage(lang) then
            localTranslation = v.translateFunction
            break
        end
    end
    makeInfo(localTranslation)
    makeConfigurations(configuration, localTranslation, baseTranslation, lang)
end

INPUT_MOUSE = {1002, 1003, 1004, 1005, 1006}
INPUT_KEY = {
    8, 9, 19, 32, 39, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
    59, 60, 61, 62, 91, 92, 93, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105,
    106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
    121, 122, 127, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267,
    268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282,
    283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 300,
    301, 302, 303, 304, 305, 306, 307, 308, 311, 312, 313, 314, 316, 319, 320,
    321, 322, 400, 401, 402
}
INPUT_MOUSE_NAMES_EN = {
    "Middle Mouse Button", "Mouse Scroll Up", "Mouse Scroll Down",
    "Mouse Button 4", "Mouse Button 5"
}
INPUT_MOUSE_NAMES_ZH = {
    "鼠标中键", "鼠标滚轮向上", "鼠标滚轮向下", "鼠标侧键4",
    "鼠标侧键5"
}
INPUT_KEY_NAMES_EN = {
    "Backspace", "Tab", "Pause", "Space", "'", ",", "-", ".", "/", "0", "1",
    "2", "3", "4", "5", "6", "7", "8", "9", "Semicolon", "<", "Equals", ">",
    "Left Bracket", "Backslash", "Right Bracket", "`", "A", "B", "C", "D", "E",
    "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
    "U", "V", "W", "X", "Y", "Z", "Delete", "Num 0", "Num 1", "Num 2", "Num 3",
    "Num 4", "Num 5", "Num 6", "Num 7", "Num 8", "Num 9", "Num .", "Num /",
    "Num *", "Num -", "Num +", "Num Enter", "KEY_KP_EQUALS", "Up", "Down",
    "Right", "Left", "Insert", "Home", "End", "Page Up", "Page Down", "F1",
    "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "F13",
    "F14", "F15", "Num Lock", "Caps Lock", "Scroll Lock", "Right Shift",
    "Left Shift", "Right Control", "Left Control", "Right Alt", "Left Alt",
    "Left Windows", "Right Windows", "Mode", "Compose", "Print Screen", "Menu",
    "Power", "Euro", "Undo", "Alt", "Control", "Shift"
}
INPUT_KEY_NAMES_ZH = {
    "退格键", "Tab", "Pause", "空格键", "'", ",", "-", ".", "/", "0", "1",
    "2", "3", "4", "5", "6", "7", "8", "9", ",", "<", "=", ">", "[", "\\", "]",
    "`", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "Delete",
    "小键盘0", "小键盘1", "小键盘2", "小键盘3", "小键盘4",
    "小键盘5", "小键盘6", "小键盘7", "小键盘8", "小键盘9",
    "小键盘.", "小键盘/", "小键盘*", "小键盘-", "小键盘+",
    "小键盘Enter", "小键盘=", "上方向键", "下方向键",
    "右方向键", "左方向键", "Insert", "Home", "End", "Page Up",
    "Page Down", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10",
    "F11", "F12", "F13", "F14", "F15", "Num Lock", "Caps Lock", "Scroll Lock",
    "右Shift键", "左Shift键", "右Ctrl键", "左Ctrl键", "右Alt键",
    "左Alt键", "左窗口键", "右窗口键", "Mode", "Compose",
    "Print Screen", "菜单键", "Power", "$", "Undo", "Alt", "Control", "Shift"
}
function GenerateModInfoTable()
    input_table_en = {{description = "Disabled", data = 0}}
    input_table_zh = {{description = "禁用", data = 0}}
    for i = 1, #INPUT_MOUSE do
        input_table_en[i + 1] = {
            description = INPUT_MOUSE_NAMES_EN[i],
            data = INPUT_MOUSE[i]
        }
        input_table_zh[i + 1] = {
            description = INPUT_MOUSE_NAMES_ZH[i],
            data = INPUT_MOUSE[i]
        }
    end
    local s = #input_table_en
    for i = 1, #INPUT_KEY do
        input_table_en[i + s] = {
            description = INPUT_KEY_NAMES_EN[i],
            data = INPUT_KEY[i]
        }
        input_table_zh[i + s] = {
            description = INPUT_KEY_NAMES_ZH[i],
            data = INPUT_KEY[i]
        }
    end
end
GenerateModInfoTable()
generate()
