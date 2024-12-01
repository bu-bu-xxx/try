-- 来源：棱镜Legion 1392778117\scripts\tools_legion.lua
-- [ 无视防御的攻击 ]--
local CalcDamage
local function GetResist_dtr(self, attacker, weapon, ...)
  local mult = 1
  if self.all_l_v ~= nil then
    mult = self.all_l_v
    if self.inst.flag_undefended_l == 1 then
      if mult < 1 then -- 大于1 是代表增伤。这里需要忽略的是减伤
        mult = 1
      end
    end
  end
  if self.GetResist_l_base ~= nil then
    local mult2 = self.GetResist_l_base(self, attacker, weapon, ...)
    if self.inst.flag_undefended_l == 1 then
      if mult2 < 1 then -- 大于1 是代表增伤。这里需要忽略的是减伤
        mult2 = 1
      end
    end
    mult = mult * mult2
  end
  return mult
end
local function RecalculateModifier_combat_l(inst)
  local m = inst._base
  for source, src_params in pairs(inst._modifiers) do
    for k, v in pairs(src_params.modifiers) do
      if v > 1 then -- 大于1 是代表增伤。这里需要忽略的是减伤
        m = inst._fn(m, v)
      end
    end
  end
  inst._modifier_l = m
end
local function UndefendedATK(target)
  if target.ban_l_undefended or -- 其他mod兼容：这个变量能防止被破防攻击
  target.prefab == "laozi" -- 无法伤害神话书说里的太上老君
  then return end

  local health = target.components.health

  if target.flag_undefended_l == nil then
    -- 修改物品栏护甲机制
    if target.components.inventory ~= nil and not target:HasTag("player") then -- 不改玩家的
      local ApplyDamage_old = target.components.inventory.ApplyDamage
      target.components.inventory.ApplyDamage =
        function(self, damage, attacker, weapon, spdamage, ...)
          if self.inst.flag_undefended_l == 1 then -- 虽然其中可能会有增伤机制，但太复杂了，不好改，直接原样返回吧
            return damage, spdamage
          end
          return ApplyDamage_old(self, damage, attacker, weapon, spdamage, ...)
        end
    end

    -- 修改战斗机制
    if target.components.combat ~= nil then
      local combat = target.components.combat
      local mult = combat.externaldamagetakenmultipliers
      local mult_Get = mult.Get
      local mult_SetModifier = mult.SetModifier
      local mult_RemoveModifier = mult.RemoveModifier
      mult.Get = function(self, ...)
        if self.inst.flag_undefended_l == 1 then
          return self._modifier_l or 1
        end
        return mult_Get(self, ...)
      end
      mult.SetModifier = function(self, ...)
        mult_SetModifier(self, ...)
        RecalculateModifier_combat_l(self)
      end
      mult.RemoveModifier = function(self, ...)
        mult_RemoveModifier(self, ...)
        RecalculateModifier_combat_l(self)
      end
      RecalculateModifier_combat_l(mult) -- 主动更新一次

      local GetAttacked_old = combat.GetAttacked
      combat.GetAttacked = function(self, ...)
        if self.inst.flag_undefended_l == 1 then
          local notblocked = GetAttacked_old(self, ...)
          self.inst.flag_undefended_l = 0
          if -- 攻击完毕，恢复其防御力
          self.inst.health_l_undefended ~= nil and self.inst.components.health ~=
            nil -- 不要判断死亡(玩家)
          then
            local healthcpt = self.inst.components.health
            local param = self.inst.health_l_undefended
            if param.absorb ~= nil and healthcpt.absorb == 0 then -- 说明被打后没变化，所以可以直接恢复
              healthcpt.absorb = param.absorb
            end
            if param.playerabsorb ~= nil and healthcpt.playerabsorb == 0 then
              healthcpt.playerabsorb = param.playerabsorb
            end
          end
          self.inst.health_l_undefended = nil
          return notblocked
        else
          return GetAttacked_old(self, ...)
        end
      end
    end

    -- 修改生命机制
    if health ~= nil then
      local mult2 = health.externalabsorbmodifiers
      local mult2_Get = mult2.Get
      mult2.Get = function(self, ...)
        if self.inst.flag_undefended_l == 1 then return 0 end
        return mult2_Get(self, ...)
      end

      if not target:HasTag("player") then -- 玩家无敌时，是不改的
        local IsInvincible_old = health.IsInvincible
        health.IsInvincible = function(self, ...)
          if self.inst.flag_undefended_l == 1 then return false end
          return IsInvincible_old(self, ...)
        end
      end
    end

    -- 修改位面实体机制
    if target.components.planarentity ~= nil then
      local AbsorbDamage_old = target.components.planarentity.AbsorbDamage
      target.components.planarentity.AbsorbDamage =
        function(self, damage, attacker, weapon, spdmg, ...)
          if self.inst.flag_undefended_l == 1 then
            local damage2, spdamage2 = AbsorbDamage_old(self, damage, attacker,
                                                        weapon, spdmg, ...)
            if damage2 < damage then -- 如果最终值小于之前的值，说明有减免，那就不准减免
              return damage, spdamage2
            else -- 兼容别的mod的逻辑
              return damage2, spdamage2
            end
          end
          return AbsorbDamage_old(self, damage, attacker, weapon, spdmg, ...)
        end
    end

    -- 修改防御的标签系数机制
    if target.components.damagetyperesist ~= nil and
      target.components.damagetyperesist.GetResist_l_base == nil then
      target.components.damagetyperesist.GetResist_l_base = target.components
                                                              .damagetyperesist
                                                              .GetResist
      target.components.damagetyperesist.GetResist = GetResist_dtr
    end
  end

  target.flag_undefended_l = 1
  if health ~= nil then
    local param = {}
    if health.absorb ~= 0 then
      param.absorb = health.absorb
      health.absorb = 0
    end
    if health.playerabsorb ~= 0 then
      param.playerabsorb = health.playerabsorb
      health.playerabsorb = 0
    end
    target.health_l_undefended = param
  end
end
-- [ 判定 attacker 对于 target 的攻击力 ]--
-- 目前官方没有这样的单独计算 对象A 对于 对象B 能打出的伤害的单独逻辑，所以这里专门写个逻辑，需要不定期更新官方的逻辑
local SpDamageUtil = require("components/spdamageutil")
CalcDamage = function(attacker, target, weapon, projectile, stimuli, damage,
                      spdamage, pushevent)
  -- if weapon == nil then --这里不关注武器来源
  --     weapon = attacker.components.combat:GetWeapon()
  -- end
  local weapon_cmp = weapon ~= nil and weapon.components.weapon or nil
  if stimuli == nil then
    if weapon_cmp ~= nil and weapon_cmp.overridestimulifn ~= nil then
      stimuli = weapon_cmp.overridestimulifn(weapon, attacker, target)
    end
    if stimuli == nil and attacker.components.electricattacks ~= nil then
      stimuli = "electric"
    end
  end

  if pushevent then
    attacker:PushEvent("onattackother", {
      target = target,
      weapon = weapon,
      projectile = projectile,
      stimuli = stimuli
    })
  end

  local multiplier = 1
  if (stimuli == "electric" or
    (weapon_cmp ~= nil and weapon_cmp.stimuli == "electric")) and
    not (target:HasTag("electricdamageimmune") or
      (target.components.inventory ~= nil and
        target.components.inventory:IsInsulated())) then
    local elec_mult = weapon_cmp ~= nil and weapon_cmp.electric_damage_mult or
                        TUNING.ELECTRIC_DAMAGE_MULT
    local elec_wet_mult = weapon_cmp ~= nil and
                            weapon_cmp.electric_wet_damage_mult or
                            TUNING.ELECTRIC_WET_DAMAGE_MULT
    multiplier = elec_mult + elec_wet_mult *
                   (target.components.moisture ~= nil and
                     target.components.moisture:GetMoisturePercent() or
                     (target:GetIsWet() and 1 or 0))
  end

  local dmg, spdmg
  if damage == nil and spdamage == nil then -- 使用公用机制(获取 attacker 或 weapon 自己的数值)
    dmg, spdmg = attacker.components.combat:CalcDamage(target, weapon,
                                                       multiplier)
    return dmg, spdmg, stimuli
  end

  -- 使用这次专门的数值
  if target:HasTag("alwaysblock") then return 0, nil, stimuli end
  dmg = damage or 0
  if spdamage ~= nil then -- 由于 spdamage 是个表，我不想改动传参数据，所以这里新产生一个表
    spdmg = SpDamageUtil.MergeSpDamage({}, spdamage)
  end
  local self = attacker.components.combat
  local basemultiplier = self.damagemultiplier
  local externaldamagemultipliers = self.externaldamagemultipliers
  local damagetypemult = 1
  local bonus = self.damagebonus
  local playermultiplier = 1
  local isplayer = target ~= nil and target:HasTag("player")
  local pvpmultiplier = isplayer and attacker:HasTag("player") and
                          self.pvp_damagemod or 1
  local mount = nil

  if weapon ~= nil then
    playermultiplier = 1
    if attacker.components.damagetypebonus ~= nil then
      damagetypemult = attacker.components.damagetypebonus:GetBonus(target)
    end
    spdmg = SpDamageUtil.CollectSpDamage(attacker, spdmg)
  else
    playermultiplier = isplayer and self.playerdamagepercent or 1
    if attacker.components.rider ~= nil and attacker.components.rider:IsRiding() then
      mount = attacker.components.rider:GetMount()
      if mount ~= nil and mount.components.combat ~= nil then
        basemultiplier = mount.components.combat.damagemultiplier
        externaldamagemultipliers = mount.components.combat
                                      .externaldamagemultipliers
        bonus = mount.components.combat.damagebonus
        if mount.components.damagetypebonus ~= nil then
          damagetypemult = mount.components.damagetypebonus:GetBonus(target)
        end
        spdmg = SpDamageUtil.CollectSpDamage(mount, spdmg)
      else
        if attacker.components.damagetypebonus ~= nil then
          damagetypemult = attacker.components.damagetypebonus:GetBonus(target)
        end
        spdmg = SpDamageUtil.CollectSpDamage(attacker, spdmg)
      end

      local saddle = attacker.components.rider:GetSaddle()
      if saddle ~= nil and saddle.components.saddler ~= nil then
        dmg = dmg + saddle.components.saddler:GetBonusDamage()
        if saddle.components.damagetypebonus ~= nil then
          damagetypemult = damagetypemult *
                             saddle.components.damagetypebonus:GetBonus(target)
        end
        spdmg = SpDamageUtil.CollectSpDamage(saddle, spdmg)
      end
    else
      if attacker.components.damagetypebonus ~= nil then
        damagetypemult = attacker.components.damagetypebonus:GetBonus(target)
      end
      spdmg = SpDamageUtil.CollectSpDamage(attacker, spdmg)
    end
  end

  dmg = dmg * (basemultiplier or 1) * externaldamagemultipliers:Get() *
          damagetypemult * (multiplier or 1) * playermultiplier * pvpmultiplier *
          (self.customdamagemultfn ~= nil and
            self.customdamagemultfn(attacker, target, weapon, multiplier, mount) or
            1) + (bonus or 0)

  if spdmg ~= nil then
    multiplier = damagetypemult * pvpmultiplier
    if multiplier ~= 1 then spdmg = SpDamageUtil.ApplyMult(spdmg, multiplier) end
  end
  return dmg, spdmg, stimuli
end
local function DoUndefendedATK(attacker, target, weapon, instancemult,
                               mimic_attack)
  instancemult = instancemult or 1
  target = target or attacker.components.combat.target
  weapon = weapon or attacker.components.combat:GetWeapon()
  local dmg, spdmg, stimuli = CalcDamage(attacker, target, weapon, nil, nil,
                                         nil, nil, mimic_attack)
  dmg = dmg * instancemult
  UndefendedATK(target)
  target.components.combat:GetAttacked(attacker, dmg, weapon, stimuli, spdmg)
  if mimic_attack then
    if weapon ~= nil then
      weapon.components.weapon:OnAttack(attacker, target, nil)
    end
  end
end
return {
  CalcDamage = CalcDamage,
  UndefendedATK = UndefendedATK, -- 拦截一次攻击
  DoUndefendedATK = DoUndefendedATK -- 主动触发一次攻击
}
