require "/scripts/interp.lua"
require "/items/active/weapons/rb-weaponutil.lua"

-- Melee primary ability
MeleeSlash = WeaponAbility:new()

function MeleeSlash:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.energyUsage = self.energyUsage or 0

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self:cooldownTime()

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function MeleeSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    self:setState(self.windup)
  end
end

-- State: windup
function MeleeSlash:windup()
  local stance = self.stances.windup
  local preStance = self.stances.idle
  self.weapon:setStance(stance)

  if self.stances.windup.hold then
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
function MeleeSlash:preslash()
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
function MeleeSlash:fire()
  local stance = self.stances.fire
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  animator.setAnimationState("swoosh", "fire")
  animator.playSound(self.fireSound or "fire")
  animator.burstParticleEmitter((self.elementalType or self.weapon.elementalType) .. "swoosh")

  util.wait(stance.duration, function()
    local damageArea = partDamageArea("swoosh")
    self.weapon:setDamage(self.damageConfig, damageArea, self.fireTime)
  end)

  self.cooldownTimer = self:cooldownTime()

  if stance.shouldInterpolateEnd then
    RBWepUtil.animateStance(stance, self.stances.idle, stance.resetDuration, self.dt)
  end
end

function MeleeSlash:cooldownTime()
  return self.fireTime - self.stances.windup.duration - self.stances.fire.duration
end

function MeleeSlash:uninit()
  self.weapon:setDamage()
end
