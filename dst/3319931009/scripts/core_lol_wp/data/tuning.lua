---@diagnostic disable: undefined-global, trailing-space

TUNING.MOD_LOL_WP = {
    REPAIR = { -- 修复耐久(finiteuse)相关
        LOL_WP_SHEEN = {
            MOONGLASS = .2, -- 使用玻璃碎片可以修复20%耐久
            MOONROCKNUGGET = .5, -- 月岩可以修复50%耐久。
        },
        LOL_WP_DIVINE = {
            GOLDNUGGET = .1,
            THULECITE = .5,
        },
        LOL_WP_TRINITY = {
            GOLDNUGGET = .1,
        },
        LOL_WP_S7_DORANBLADE = {
            FLINT = .2,
            GOLDNUGGET = .5,
        },
        LOL_WP_S7_OBSIDIANBLADE = {
            FLINT = .2,
        },
    },
    REPAIR_ARMOR = { -- 修理armor组件
        LOL_WP_OVERLORDBLOODARMOR = { -- 霸王血铠
            NIGHTMAREFUEL = .1,
            HORRORFUEL = .5,
        },
        LOL_WP_WARMOGARMOR = { -- 狂徒铠甲
            SHROOM_SKIN = .5,
            GREENGEM = .5,
            LIVINGLOG = .1,
        },
        LOL_WP_DEMONICEMBRACEHAT = { -- 恶魔之拥
            NIGHTMAREFUEL = .1, -- 噩梦燃料修复10%耐久
            HORRORFUEL = .5, -- 纯粹恐惧修复50%耐久。
        },
        LOL_WP_S7_DORANSHIELD = { -- 多兰之盾
            FLINT = .2,
            GOLDNUGGET = .5,
        },
    },
    SHEEN = { -- 耀光
        DMG = 51, -- 攻击力
        WALKSPEEDMULT = 1.1, -- 移速
        LIGHT_FALLOFF = .2,
        LIGHT_INTENSITY = .9,
        LIGHT_RADIUS = 1, -- 手持时会发出半径1的微弱光照。
        LIGHT_COLOR = {1,1,1}, -- RGB
        FINITEUSES = 300, -- 耐久
        CD = 2, -- [咒刃] 冷却时间2秒。
        DMGMULT_TO_SHADOW = 1.1, -- 对暗影阵营生物造成10%额外伤害。
        DMGMULT = 2, -- [咒刃] 攻击会触发- -次强化攻击，造成200%的伤害
    },
    DIVINE = { -- 神圣分离者
        DMG = 51, -- 攻击力
        WALKSPEEDMULT = 1.2, -- 移速
        LIGHT_FALLOFF = .2,
        LIGHT_INTENSITY = .9,
        LIGHT_RADIUS = 1.5, -- 手持时会发出半径2的微弱光照。
        LIGHT_COLOR = {251/255,232/255,16/255},
        FINITEUSES = 400, -- 耐久400 
        EFFICIENCY = 3, -- 工具效率
        ACTION_CONSUME = { -- 工具消耗耐久
            CHOP = 1,
            MINE = 1,
        },
        CD = 2, -- [咒刃] 冷却时间1.5秒。
        ATK_HEAL = 5, -- [咒刃]  触发时会回复5生命值
        DMGMULT_TO_SHADOW = 1.1, -- 对暗影阵营生物造成10%额外伤害。
        DMGMULT = 2.5, --  [咒刃] 攻击会触发一次强化攻击,造成250%的伤害，
        HOLY_DMG = .04, -- [神圣打击] 右键目标造成-次强化攻击，会造成目标最大生命值2%的额外物理伤害
        HOLY_HEAL = 15, -- [神圣打击] 并回复自身15点生命值
        HOLY_CD = 10, -- [神圣打击] 冷却10秒。
        RANGE = 1.2, -- 距离
    },
    TRINITY = { -- 三项
        DMG = 33,
        RANGE = 5,
        LIGHT_RADIUS = 2,
        DARPPERNESS = 3,
        WALKSPEEDMULT = 1.3,
        DMGMULT = 1.3,
        HEAL_INTERVAL = 10, -- /s
        HEAL_HP = 3, 
        DMG_WHEN_AMULET = 16,
        FINITEUSE = 800, -- 耐久
    },
    OVERLORDBLOOD = { -- 霸王血铠
        DARPPERNESS = -5, -- 穿戴掉san
        SHADOW_LEVEL = 4, -- 暗影等级
        DURABILITY = 2000, -- 耐久
        ABSORB = .9, -- 防御
        DEFEND_PLANAR = 25, -- 位面防御
        CD = 10, -- 骨甲效果cd
        AUTO_REPAIR = { -- 在耐久不足时会吸取玩家生命值恢复耐久
            START = .8,  -- 低于percent开始修复
            END = 1, -- 超过这个percent,停止修复
            INTERVAL = 5, -- 吸血间隔/s
            DRAIN = 10, -- 每次吸血
            INTERVAL_REPAIR = 5, -- 修复耐久间隔/s
            REPAIR = 20, -- 每次修复耐久
        },
        SKILL_MAXHP_TO_ATK = .05, -- 将玩家5%最大生命值转化为额外攻击力。
        SKILL_LOSTHP_TO_ATK = .1, -- 【报复】获得损失生命值10%的攻击力提升。
        WATERPROOF = .4, -- 防水
        BLUEPRINTDROP_CHANCE = { -- 蓝图掉落
            -- STALKER = 1,
            -- STALKER_FOREST = 1,
            STALKER_ATRIUM = 1,
        }
    },
    WARMOGARMOR = { -- 狂徒铠甲
        ABSORB = .6, -- 防御
        WALKSPEEDMULT = 1.05, -- 穿戴移速
        DARPPERNESS = 8, -- 穿戴san
        INSULATION = 120, -- 隔热
        WATERPROOF = .4, -- 防水
        HUNGERRATE = .6, -- 饥饿速率
        SKILL_HEART = { -- 被动：【狂徒之心】
            NO_TAKE_DMG_IN = 6, -- 秒内没收到伤害,
            HP_PERCENT_BELOW = .8, -- 血量低于百分比
            INTERVAL = 1, -- 每隔多少秒
            REGEN_PERCENT = .05, -- 回复自身最大生命的百分之多少
            WALKSPEEDMULT = .1, -- 额外增加10%移速
            RESUME = 1, -- 触发时会消耗多少耐久
        },
        SKILL_POISONFOG = { -- 主动：【真菌毒雾】
            CD = 10,
        },
        BLUEPRINTDROP_CHANCE = { -- 蓝图掉落   
            TOADSTOOL = .5, -- 普通毒菌蟾蜍50%掉落蓝图。
            TOADSTOOL_DARK = 1, -- 悲惨的毒菌蟾蜍100%掉落蓝图。
        },
        DURABILITY = 200, -- 耐久
    },
    DEMONICEMBRACEHAT = { -- 恶魔之拥 头盔
        LIGHT_RADIUS = 2, -- 光照半径
        WATERPROOF = .6, -- 防水
        ABSORB = .8, -- 防御
        DEFEND_PLANAR = 35, -- 位面防御，
        WHEN_MASKED = { -- 右键切换为面具时
            DARPPERNESS = -20,
        },
        SKILL_DARKCONVENANT = { -- 被动：【黑暗契约】
            TRANSFER_MAXHP_PERCENT = .05 -- 将玩家5%的最大生命值转化为额外的位面伤害。
        },
        SKILL_STARE = { -- 被动：【亚扎卡纳的凝视】
            CD = 10, -- 冷却
            MAXHP_PERCENT = .01 -- 对一名敌人造成伤害时，会造成相当于其1%最大生命值的额外位面伤害
        },
        SHADOW_LEVEL = 4,
        DARPPERNESS = -5,
        BLUEPRINTDROP_CHANCE = { -- 蓝图掉落
            STALKER_ATRIUM = 1, -- 远古织影者100%掉落蓝图。
        },
        DURABILITY = 2000, --  耐久
    },
    -- s7
    -- 萃取
    CULL = {
        DMG = 34, -- 攻击力
        ATK_REGEN = 2, -- 每次攻击回复自身2点生命值
        SKILL_SWEEP = { -- 主动：【收割
            CD = 5, -- 冷却时间
        },
        SKILL_LOOT = { -- 被动：【掠夺】
            GOLD_PERUNIT = 1, -- 每击杀一个单位会掉落1个金块
            FINISHED = 100, -- 累计击杀100个生物会爆掉(萃取 消失)
            GOLD_WHEN_FINISHED = 20, -- 掉落20个金块。
        },
    },
    -- 多兰之刃
    DORANBLADE = {
        DMG = 51, -- 攻击力
        DRAIN = 3, -- 吸血
        FINITEUSE = 200, -- 耐久
    },
    -- 多兰之戒
    DORANRING = {
        PLANAR_DMG_WHEN_EQUIP = 10, -- 佩戴时提供10点额外位面伤害。
        DAPPERNESS = 8, -- 佩戴时+8san/min。
    },
    -- 女神之泪
    TEARSOFGODDESS = {
        DAPPERNESS = 6,
        SKILL_SPELLFLOW = {
            NUM_PER_HIT = 1,
            SAN_LIMIT_PER_NUM = 1,
            SAN_LIMIT_MAX = 300,
            CD = 8,
        },
    },
    -- 黑曜石锋刃
    OBSIDIANBLADE = {
        DMG = 45, -- 攻击力
        DMGMULT_TO_NEUTRAL = 2, -- 攻击中立生物会造成双倍伤
        DRAIN = 6, -- 吸血
        SKILL_HUNTER = { -- 被动：【狩猎人】击杀生物后，会使掉落物中概率最高的掉落物额外掉落一个,,并使所有掉落物概率提高10%。
            CHANCE_UP = .1,
        },
        FINITEUSE = 200,
    },
    -- 多兰之盾
    DORANSHIELD = {
        DMG = 34, -- 伤害
        ABSORB = .8, -- 防御
        SKILL_RESTORE = { -- 被动：【复原力】手持时每5秒回复1生命值。
            INTERVAL = 5, -- 间隔
            REGEN = 1, -- 回复
        },
        SKILL_BLOCK = {
            REGEN_WHEN_SUCCESS = 6, -- 格挡成功时，会额外回复自身6点生命值。 
        },
        FINITEUSE = 400,
    }
}
