require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/zy_trashcan.zip"),

}

local  prefabs = 
{
    "collapse_small",
	"ash",
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
	    inst.AnimState:PlayAnimation("burn")
		inst.components.container:DropEverything()
		inst.AnimState:PushAnimation("closed", false)
		inst.components.container:Close()
    end
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("open")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
	end
end

local function onclose(inst)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("idle")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
	end
end

local function onbuilt(inst)
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/icebox_craft")
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function onBurnItems(inst)
	local hasItems = false
	local returnItems = {}

	if inst.components.aipc_action and inst.components.container then
		local ings = {}
		for k, item in pairs(inst.components.container.slots) do
			local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1
			local lootItem = "ash"

			returnItems[lootItem] = (returnItems[lootItem] or 0) + stackSize
			hasItems = true
		end
	end

	if hasItems then
		inst.AnimState:PlayAnimation("burn")
		inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")

		for prefab, prefabCount in pairs(returnItems) do
			local currentCount = prefabCount
			local loot = inst.components.lootdropper:SpawnLootPrefab(prefab)
			local lootMaxSize = 1

			if loot.components.stackable then
				lootMaxSize = loot.components.stackable.maxsize
			end
			loot:Remove()

			while(currentCount > 0)
			do
				local dropCount = math.min(currentCount, lootMaxSize)
				local dropLootItem = inst.components.lootdropper:SpawnLootPrefab(prefab)
				if dropLootItem.components.stackable then
					dropLootItem.components.stackable:SetStackSize(dropCount)
				end
				
				currentCount = currentCount - dropCount
			end
		end

		inst.components.container:Close()
		inst.components.container:DestroyContents()
	end
end


local function AcceptTest(inst, item)
	if item:HasTag("irreplaceable") or item.prefab == "ash" then
		return false, "INCINERATOR_NOT_BURN"
	end
	return true
end

local function OnGetItemFromPlayer(inst, giver, item)
	if item:HasTag("backpack") then
		inst.AnimState:PlayAnimation("burn")
		inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")
		item:Remove()

	end
	local lootItem = "ash"

	inst.components.lootdropper:SpawnLootPrefab(lootItem)

end


local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .4)

	inst.AnimState:SetBank("zy_trashcan")
	inst.AnimState:SetBuild("zy_trashcan")
	inst.AnimState:PlayAnimation("idle", false)

	inst:AddTag("structure")
    inst:AddTag("chest")

	inst.MiniMapEntity:SetIcon("zy_trashcan.tex")
	
	MakeSnowCoveredPristine(inst)	
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("zy_trashcan")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onBurnItems

	inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(5)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("trader")
	inst.components.trader:SetAbleToAcceptTest(AcceptTest)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader.acceptnontradable = true


	inst:AddComponent("inspectable")

	inst:ListenForEvent("onbuilt", onbuilt)
	
    MakeSnowCovered(inst)
    AddHauntableDropItemOrWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
	
    inst.OnSave = onsave 
    inst.OnLoad = onload

	return inst
end

return Prefab("zy_trashcan", fn, assets, prefabs),
	MakePlacer("zy_trashcan_placer", "zy_trashcan", "zy_trashcan", "idle")


