local Vector3 = GLOBAL.Vector3
local STRINGS = GLOBAL.STRINGS
local RECIPETABS = GLOBAL.RECIPETABS
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH

Assets =
{
	Asset("ATLAS", "images/inventoryimages/zy_trashcan.xml"),
	Asset("ATLAS", "minimap/zy_trashcan.xml"),
	Asset("IMAGE", "minimap/zy_trashcan.tex"),
	Asset("ANIM", "anim/ui_zy_trashcan_5x5.zip"),
}
AddMinimapAtlas("minimap/zy_trashcan.xml")

PrefabFiles =
{
	"zy_trashcan"
}

STRINGS.NAMES.ZY_TRASHCAN = "垃圾焚烧桶"
STRINGS.RECIPE_DESC.ZY_TRASHCAN = "放进去燃烧吧"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ZY_TRASHCAN = "居家必备之良桶~！"
---------------
local zy_trashcan = AddRecipe("zy_trashcan", {Ingredient("cutstone", 3), Ingredient("goldnugget", 4), Ingredient("charcoal", 4)}, RECIPETABS.TOWN, TECH.NONE, "zy_trashcan_placer",1, nil, nil, nil,"images/inventoryimages/zy_trashcan.xml","zy_trashcan.tex")

---------------
local AIP_ACTION = env.AddAction("AIP_ACTION", "Operate", function(act)

	local doer = act.doer
	local target = act.target

	if target.components.aipc_action ~= nil then
		target.components.aipc_action:DoAction(doer)
		return true
	end
	return false
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_ACTION, "doshortaction"))
---------------

local params = {}
local containers = { MAXITEMSLOTS = 0 }


local containers = GLOBAL.require "containers"
local old_widgetsetup = containers.widgetsetup

function containers.widgetsetup(container, prefab, data)
	local pref = prefab or container.inst.prefab

	-- Hook
	local containerParams = params[pref]
	if containerParams then
		for k, v in pairs(containerParams) do
			container[k] = v
		end
		container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
		return
	end

	return old_widgetsetup(container, prefab, data)
end

params.zy_trashcan =
{
	widget =
	{
		slotpos ={ },
		animbank = "ui_zy_trashcan_5x5",
		animbuild = "ui_zy_trashcan_5x5",
        pos = Vector3(55, 160, 0),
        side_align_tip = 160,
		buttoninfo =
		{
			text = "烧掉",
			position = Vector3(0, -225, 0),
		}
	},
	acceptsstacks = true,
	type = "chest",
}

for y = 3, -1, -1 do
	for x = -1, 3 do
		table.insert(params.zy_trashcan.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80 , 0))
	end
end

--------------------
function params.zy_trashcan.itemtestfn(container, item, slot)
	if item:HasTag("irreplaceable") then
		return false
	end
		return true
end

function params.zy_trashcan.widget.buttoninfo.fn(inst)
	if inst.components.container ~= nil then
		GLOBAL.BufferedAction(inst.components.container.opener, inst, AIP_ACTION):Do()
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, AIP_ACTION.code, inst, AIP_ACTION.mod_name)
	end
end

function params.zy_trashcan.widget.buttoninfo.validfn(inst)
	return inst.replica.container ~= nil
end

for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end
------------------
AddPrefabPostInit("researchlab2", function(inst)
	if inst and GLOBAL.TheNet:GetIsServer() then
		inst:AddComponent("trader")
		inst.components.trader.acceptnontradable=true
		inst.components.trader:SetAcceptTest(function(inst, item)
		-- if item:HasTag("irreplaceable") then
			-- return false
		-- end
			if item:HasTag("backpack") then
				return true
			else return false
				--return item and not item:HasTag("irreplaceable")
			end
		end)

		inst.components.trader.onaccept = function(inst, giver, item)
			inst.AnimState:PlayAnimation("use")
			inst.AnimState:PushAnimation("idle")
	        if not inst.SoundEmitter:PlayingSound("sound") then
                inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl2_run", "sound")
				inst:DoTaskInTime(1.5, function() inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl2_ding") end)
            end
		end
	end
end)