PrefabFiles = {
    "LongSword",
    'ktnfx'
}

GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

  local loc = require "languages/loc"
  local lan = loc and loc.GetLanguage and loc.GetLanguage()
  if lan == LANGUAGE.CHINESE_S or lan == LANGUAGE.CHINESE_S_RAIL then
    MOD_KTN_LANGUAGE_SETTING = true
  else
    MOD_KTN_LANGUAGE_SETTING = nil
  end
  GLOBAL.MOD_KTN_LANGUAGE_SETTING = MOD_KTN_LANGUAGE_SETTING


   Assets =
{
	  Asset("SOUNDPACKAGE", "sound/longsword.fev"),
    Asset("SOUND", "sound/longsword.fsb"),

	Asset("ANIM", "anim/nadao.zip"),
  Asset("ANIM", "anim/nadao_pst.zip"),
  Asset("ANIM", "anim/nadao_extra.zip"),
  Asset("ANIM", "anim/nadao_dlz.zip"),
  Asset("ANIM", "anim/nadao_qrz.zip"),
  Asset("ANIM", "anim/evade.zip"),

	Asset("ANIM", "anim/qrc.zip"),
  Asset("ANIM", "anim/sharpness.zip"),

	Asset("ANIM", "anim/hx_fx.zip"),
  Asset("ANIM", "anim/qr_fx.zip"),

    Asset("ATLAS", "images/inventoryimages/LongSword.xml"),

}

    local function checkkey(key)
      if key == 'LCTRL' then return KEY_LCTRL
      elseif key == 'LSHIFT' then return KEY_LSHIFT
      elseif key == 'TAB' then return KEY_TAB
      elseif key == 'RALT' then return KEY_RALT
      elseif key == 'SPACE' then return KEY_SPACE
      elseif key == 'MOUSE5' then return 1006
      elseif key == 'MOUSE4' then return 1005
        elseif key then return key:lower():byte()
      end
    end


        TUNING.KTNDAMAGE = 34

        -- Katana Info
        STRINGS.NAMES.LONGSWORD = (MOD_KTN_LANGUAGE_SETTING and '太刀')or "Long Sword"
        STRINGS.RECIPE_DESC.LONGSWORD = (MOD_KTN_LANGUAGE_SETTING and '勇气之征')or "Journey of nerve"
        STRINGS.CHARACTERS.GENERIC.DESCRIBE.LONGSWORD = (MOD_KTN_LANGUAGE_SETTING and '我看到了崭新的世界')or "I see a brand new world"

        STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.SHARPEN = 
        {
         NEEDEQUIP = (MOD_KTN_LANGUAGE_SETTING and '我需要装备它')or "I have to equip it",
         }

local function AddRecipe3(name, ...)
  local r = env.AddCharacterRecipe(name, ...)
  return function(params)
    for k,v in pairs(params)do
      r[k] = v
    end
  end
end
local I = Ingredient
AddRecipe3("longsword", {Ingredient("redgem", 6), Ingredient("goldnugget", 9), Ingredient("nightsword", 1),Ingredient("dragon_scales", 2)}, TECH.SCIENCE_TWO, {atlas = "images/inventoryimages/LongSword.xml", image = "LongSword.tex"}, {"WEAPONS"})

        GLOBAL.KEYTYPE = GetModConfigData("KTN_KEYTYPE")
        GLOBAL.KTN_JSZHAN = checkkey(GetModConfigData("KTN_JSZHAN"))
        GLOBAL.KTN_KTNATK = checkkey(GetModConfigData("KTN_KTNATK"))
        GLOBAL.KTN_HKDL = checkkey(GetModConfigData("KTN_HKDL"))
                GLOBAL.KTN_HKJH = checkkey(GetModConfigData("KTN_HKJH"))
                        GLOBAL.KTN_HKJQ = checkkey(GetModConfigData("KTN_HKJQ"))
                                GLOBAL.KTN_HKTC = checkkey(GetModConfigData("KTN_HKTC"))
        if type(KEYTYPE) == "number" then
        GLOBAL.KTN_KEYQR = 61
        GLOBAL.KTN_SPACE = 57
        GLOBAL.KTN_KEYLK = 60
        GLOBAL.KTN_KEYZW = 12
        else
        GLOBAL.KTN_KEYQR = checkkey(GetModConfigData("KTN_KEYQR"))
        GLOBAL.KTN_KEYZW = checkkey(GetModConfigData("KTN_KEYZW"))
        GLOBAL.KTN_KEYLK = checkkey(GetModConfigData("KTN_KEYLK"))
        GLOBAL.KTN_SPACE = checkkey(GetModConfigData("KTN_SPACE"))
        end


local SHARPEN = Action({priority = 99})
SHARPEN.id = "SHARPEN"
SHARPEN.str = MOD_KTN_LANGUAGE_SETTING and "打磨" or "Whet"
SHARPEN.fn = function(act)
    if act.doer.components.inventory then
        --local fuel = act.doer.components.inventory:RemoveItem(act.invobject)
        if act.target.components.sharpness ~= nil then
          if (act.target.components.equippable ~= nil and act.target.components.equippable:IsEquipped()) then
           act.target.components.sharpness:DoSharp(act.doer,act.invobject)
           return true
         else return false,"NEEDEQUIP" end
        end
    end
end
AddAction(SHARPEN)

AddComponentAction("USEITEM", "tradable" , function(inst, doer, target, actions)
          if inst and target and doer and target:HasTag("Ktn_Sharpness") and (inst.prefab == "redgem" or inst.prefab == "goldnugget") then 
            table.insert(actions, ACTIONS.SHARPEN)
          end
end) 

AddStategraphActionHandler("wilson",ActionHandler(ACTIONS.SHARPEN, "give"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.SHARPEN, "give")) 


modimport("scripts/ktnqrc.lua")
modimport("scripts/ktnsg.lua")


