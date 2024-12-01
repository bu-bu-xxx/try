modimport("main/util")
-- modimport("main/strings")
modimport("main/assets")
modimport("main/modrpc")

if GLOBAL.TheNet:IsDedicated() then
    return
end

modimport("main/lolping")
modimport("main/muteping")