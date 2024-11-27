local L = locale ~= "zh" and locale ~= "zhr"

name = L and "Thumper" or "重击者"
author = "Albe (modification from Hornet)"

description = L and
[[
    · Thumper from Hamlet""Thumper from Hamlet
    · Can be used for large-scale tree felling
]]
or
[[
    · 来自哈姆雷特的重击者
    · 可用作大规模伐木
]]


version = "22.6.11" 
forumthread = ""
priority = 500

api_version = 10

dst_compatible = true
all_clients_require_mod = true 
dont_starve_compatible = false
reign_of_giants_compatible = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options = 
{
    L and 
    {
        name = "Language",
        label = "Language",
        hover = "Language setting", 
        options = 
        {
            {description = "English", data = "english"},
            {description = "中文", data = "chinese"},          
        },
        default = "english",
    }
    or
    {
        name = "Language",
        label = "语言",
        hover = "语言设置", 
        options = 
        {
            {description = "English", data = "english"},
            {description = "中文", data = "chinese"},          
        },
        default = "chinese",
    },
}