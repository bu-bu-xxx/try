C:\Users\77911\Documents\Klei\DoNotStarveTogether\863489714\Cluster_2\Caves\modoverrides.lua
以及
C:\Users\77911\Documents\Klei\DoNotStarveTogether\863489714\Cluster_5\Master\modoverrides.lua
这个是mod的配置文件，Caves是洞穴，master是世界，需要copy这个文件，cluster应该是存档编号，，所以先在自己的电脑搞个新存档，配置好后，把上面两个配置文件发给我


E:\SteamLibrary\steamapps\workshop\content\322330
这个是游戏的mod源文件，可以通过steam浏览本地文件找到，然后全部压缩，发给我。
（我不确定，是否会默认全部开启，还是配置了的mod才会开启，所以筛选哪些需要开的mod发给我）


然后大功告成，其实我已经开了一些你之前配置过的mod，如果需要补充的不多，其实手动复制粘贴也挺快

2730837741   bicycle
1909012147  smusher

Master and Caves/modoverrides.lua  

["workshop-1909012147"]={ configuration_options={ Language="chinese" }, enabled=true },

  ["workshop-2730837741"]={
    configuration_options={
      MOTOBIKE_CHARCOAL_RATE=1,
      MOTOBIKE_DROP_CAN_ON_EXIT=false,
      MOTOBIKE_FUEL_RATE=1,
      MOTOBIKE_HEAT_RATE=1 
    },
    enabled=true 
  },

  ["workshop-2376883615"]={
    configuration_options={
      AIRPLANE_EASYLANDING=false,
      AIRPLANE_EASYRECIPE=false,
      AIRPLANE_FUELRATE=1,
      AIRPLANE_UNBREAKABLE=true 
    },
    enabled=true 
  },
	
