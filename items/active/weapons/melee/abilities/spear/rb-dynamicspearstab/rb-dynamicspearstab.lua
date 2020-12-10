require "/scripts/interp.lua"
require "/items/active/weapons/rb-weaponutil.lua"

-- Dynamic spear stab attack
-- Reconstructs MeleeSlash to support multiple variations of the "fire" state.
DynamicSpearStab = WeaponAbility:new()

function DynamicSpearStab:init()

  self.energyUsage = self.energyUsage or 0

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self:cooldownTime()

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end

  self.animKeyPrefix = self.animKeyPrefix or ""
  
  self:calculateDamage()
end

-- Ticks on every update regardless if this is the active ability
function DynamicSpearStab:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    self:setState(self.windup)
  end
end

-- State: windup
function DynamicSpearStab:windup()
  local stance = self.stances.windup
  local preStance = self.stances.idle
  self.weapon:setStance(stance)

  if stance.hold then
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
      coroutine.yield()
    end
  else
    if stance.shouldInterpolate then
      RBWepUtil.animateStance(preStance, stance, stance.duration, self.dt)
    else
      util.wait(stance.duration)
    end
  end

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end

  if self.stances.preslash then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

-- State: preslash
-- brief frame in between windup and fire
function DynamicSpearStab:preslash()
  local stance = self.stances.preslash
  local preStance = self.stances.windup
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  if stance.shouldInterpolate then
    RBWepUtil.animateStance(preStance, stance, stance.duration, self.dt)
  else
    util.wait(stance.duration)
  end

  self:setState(self.fire)
end

-- State: fire
function DynamicSpearStab:fire()
  local stance = self.stances.fire
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  local animStateKey = self.animKeyPrefix .. "fire"
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)
  animator.burstParticleEmitter(self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh")

  util.wait(self.stances.fire.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  self.cooldownTimer = self:cooldownTime()

  if self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.allowHold ~= false then
    self:setState(self.hold)
    return
  end
  
  if stance.shouldInterpolateEnd then
    RBWepUtil.animateStance(stance, self.stances.idle, stance.resetDuration, self.dt)
  end
end

function DynamicSpearStab:cooldownTime()
  return self.fireTime - self.stances.windup.duration - self.stances.fire.duration
end

function DynamicSpearStab:uninit()
  self.weapon:setDamage()
end

function DynamicSpearStab:hold()
  local startAimAngle = self.weapon.aimAngle
  self.weapon:setStance(self.stances.hold)
  self.weapon:updateAim()

  if self.stances.hold.shouldInterpolate then
    local progress = 0
    util.wait(self.stances.hold.adjustTime, function()
      local stance = RBWepUtil.getLerpStance(self.stances.fire, self.stances.hold, progress)
      local goalAimAngle = interp.linear(progress, startAimAngle, self.weapon.aimAngle)  -- self.relativeArmRotation = -self.aimAngle + stanceRotation + goalAimAngle
      stance.armRotation = util.toRadians(stance.armRotation) - self.weapon.aimAngle + goalAimAngle

      self.weapon.weaponOffset = stance.weaponOffset
      self.weapon.relativeWeaponRotation = util.toRadians(stance.weaponRotation)
      self.weapon.relativeArmRotation = stance.armRotation

      progress = math.min(1.0, progress + (self.dt / self.stances.hold.adjustTime))
    end)
  end

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.holdDamageConfigMerged, damageArea)
    coroutine.yield()
  end

  if self.stances.hold.shouldInterpolateEnd then
    RBWepUtil.animateStance(self.stances.hold, self.stances.idle, self.stances.hold.resetDuration, self.dt)
  end

  self.cooldownTimer = self:cooldownTime()
end

function DynamicSpearStab:calculateDamage()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime
  self.holdDamageConfigMerged = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfigMerged.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
end
