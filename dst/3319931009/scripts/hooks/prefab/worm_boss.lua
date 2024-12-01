local done = false

AddPrefabPostInit("worm_boss", function(inst)
    if TheWorld.ismastersim then
        if not done then
            table.insert(LootTables["worm_boss"], { "nashor_tooth",  1.00 })
            done = true
        end
    end
end)