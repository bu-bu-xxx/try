local isCh = locale == "zh" or locale == "zhr"--是否为中文
name = isCh and "太刀" or "LongSword"
description = isCh and "我想成为一个合格的猎人" or "I want to be a qualified hunter"
author = "I 4C U"
version = "1.7"
forumthread = ""
api_version = 10


icon_atlas = "modicon.xml"
icon = "modicon.tex"


dst_compatible = true
all_clients_require_mod = true

local KEY_A = 65
local keyslist = {}
local string = "" 
for i = 1, 26 do
	local ch = string.char(KEY_A + i - 1)
	keyslist[i] = {description = ch, data = ch}
    keyslist[27] = {description = "LCTRL", data = "LCTRL"}
    keyslist[28] = {description = "TAB", data = "TAB"}
    keyslist[29] = {description = "RALT", data = "RALT"}
    keyslist[30] = {description = "SPACE", data = "SPACE"}
    keyslist[31] = {description = "LSHIFT", data = "LSHIFT"}
    keyslist[32] = {description = isCh and "无_" or "None_", data = false}
    keyslist[33] = {description = isCh and "鼠标侧键前" or "Mouse side front button", data = "MOUSE5"}
    keyslist[34] = {description = isCh and "鼠标侧键后" or "Mouse side rear button", data = "MOUSE4"}
end

local function Subtitle(name)
	return {
		name = name,
		label = name,
		options = { {description = "", data = false}, },
		default = false,
	}
end

configuration_options = isCh and

{
		Subtitle("选择操作模式"),
	{
		name = "KTN_KEYTYPE",
		label = "键位",
		hover = " 即使从未玩过怪物猎人,仍推荐使用'鼠标和键盘'",
		options = 	   {{description = "仅键盘", data = false},
						{description = "鼠标和键盘", data = true},
					    {description = "手柄", data = 1}
					   },
		default = true,
	},  
		Subtitle("按键调整"),
    {
		name = "KTN_KEYQR",
		label = "气刃斩",
		hover = " 默认鼠标侧键前",
		options = keyslist,
		default = "MOUSE5",
	},    
	{
		name = "KTN_KEYZW",
		label = "磨刀",
		hover = " 默认 Z",
		options = keyslist,
		default = "Z",
	}, 
	{
		name = "KTN_KEYATK",
		label = "默认攻击键",
		hover = " 默认 F. 仅在 仅键盘 有效",
		options = keyslist,
		default = "F",
	}, 
	{
		name = "KTN_SPACE",
		label = "替换空格键",
		hover = " 默认 Space.",
		options = keyslist,
		default = "SPACE",
	},      
	Subtitle("额外的快捷键"),
	{
		name = "KTN_KEYLK",
		label = "锁住太刀按键",
		hover = "强烈推荐,使太刀的按键短暂失效 以便右键CTRL正常交互",
		options = keyslist,
		default = false,
	},
			{
		name = "KTN_JSZHAN",
		label = "一键袈裟斩",
		hover = "'仅键盘'模式需要设定,否则无法使用袈裟斩",
		options = keyslist,
		default = false,
	}, 
	--[[
		{
		name = "KTN_HKDL",
		label = "一键登龙",
		hover = " 对于两种操纵模式, 更容易用出登龙",
		options = keyslist,
		default = false,
	}, 
		{
		name = "KTN_HKJH",
		label = "一键居合",
		hover = " 对于两种操纵模式, 更容易用出居合",
		options = keyslist,
		default = false,
	}, 
	    {
		name = "KTN_HKJQ",
		label = "一键见切",
		hover = " 对于两种操纵模式, 更容易用出见切",
		options = keyslist,
		default = false,
	}, 
        {
		name = "KTN_HKTC",
		label = "一键突刺",
		hover = " 对于两种操纵模式, 更容易用出突刺",
		options = keyslist,
		default = false,
	}, --]]
 } or 
{
	Subtitle("Select Operating Mode"),
		{
		name = "KTN_KEYTYPE",
		label = "How to control Longsword",
		hover = " Though u had never played MHW,'mouse and keyboard' is still recommended",
		options = 	   {{description = "keyboard only", data = false},
						{description = "mouse and keyboard", data = true},
					    {description = "Controller", data = 1}
					   },
		default = true,
	},  
	Subtitle("Keys Adjustment"),
    {
		name = "KTN_KEYQR",
		label = "Spirit Blade",
		hover = " Default Side mouse front.",
		options = keyslist,
		default = "MOUSE5",
	},    
	{
		name = "KTN_KEYZW",
		label = "Whet",
		hover = " Default Z",
		options = keyslist,
		default = "Z",
	}, 
	{
		name = "KTN_KEYATK",
		label = "Default Attack",
		hover = " Default F. DontStarve's Attack Key",
		options = keyslist,
		default = "F",
	}, 
	{
		name = "KTN_SPACE",
		label = "Replace spacebar",
		hover = " Default Space. Set a key to instead SPACE",
		options = keyslist,
		default = "SPACE",
	}, 
		Subtitle("Extra HotKey"),
		{
		name = "KTN_KEYLK",
		label = "Lock",
		hover = " Disable all Longsword's keyboard , So that right mouse to interact normally",
		options = keyslist,
		default = false,
	},
		{
		name = "KTN_JSZHAN",
		label = "Fade Slash shortcut key",
		hover = " In keyboardOnly option, set a key to use shortcut, vaild for both options",
		options = keyslist,
		default = false,
	},      
	--[[
		{
		name = "KTN_HKDL",
		label = "Spirit Thrust shortcut key",
		hover = " For both control ways, easier to use SpiritThrust",
		options = keyslist,
		default = false,
	}, 
		{
		name = "KTN_HKJH",
		label = "Special Sheathe shortcut key",
		hover = " For both control ways, easier to use SpecialSheathe",
		options = keyslist,
		default = false,
	}, 
	    {
		name = "KTN_HKJQ",
		label = "ForeSight Slash shortcut key",
		hover = " For both control ways, easier to use ForesightSlash",
		options = keyslist,
		default = false,
	}, 
        {
		name = "KTN_HKTC",
		label = "Thrust shortcut key",
		hover = " For both control ways, easier to use thrust",
		options = keyslist,
		default = false,
	}, --]]
 }

 bugtracker_config = {
 	email = "eclipsehugh@gmail.com",
 	upload_client_log = true
 }