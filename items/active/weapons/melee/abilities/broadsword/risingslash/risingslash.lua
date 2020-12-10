require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/rb-weaponutil.lua"

RisingSlash = WeaponAbility:new()

function RisingSlash:init()
  self:reset()
  self.idleStance = self:getGlobalStance("idle")

  self.cooldownTimer = self.cooldownTime
end

function RisingSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    and self.fireMode == "alt"
    and not status.statPositive("activeMovementAbilities")
    and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.windup)
  end
end

function RisingSlash:windup()
  local stance = self.stances.windup
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  animator.setGlobalTag("directives", "?flipx")

  local progress = 0
  util.wait(stance.duration, function()
    if stance.shouldInterpolate then
      RBWepUtil.lerpStance(self.idleStance, stance, progress)
      progress = math.min(1.0, progress + (self.dt / stance.duration))
    end
    return status.resourceLocked("energy")
  end)

  if self.stances.preslash then
    self:setState(self.preslash)
  else
    self:setState(self.slash)
  end
end

function RisingSlash:preslash()
  local stance = self.stances.preslash
  local preStance = self.stances.windup
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  if stance.shouldInterpolate then
    RBWepUtil.animateStance(preStance, stance, stance.duration, self.dt)
  else
    util.wait(stance.duration)
  end

  self:setState(self.slash)
end

function RisingSlash:slash()
  self.weapon:setStance(self.stances.slash)
  self.weapon:updateAim()

  animator.setAnimationState("risingSwoosh", "slash")
  animator.playSound("upswing")

  util.wait(self.stances.slash.duration, function()
    if math.abs(world.gravity(mcontroller.position())) > 0 then
      mcontroller.controlApproachYVelocity(self.dashSpeed, self.dashControlForce)
    end

    local damageArea = partDamageArea("risingSwoosh")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)

  self.cooldownTimer = self.cooldownTime
  self:setState(self.freeze)
end

function RisingSlash:getGlobalStance(stance)
  for _, ability in pairs(self.weapon.abilities) do
    if ability.stances[stance] then
      return ability.stances[stance]
    end
  end
end

function RisingSlash:freeze()
  local stance = self.stances.freeze
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  util.wait(stance.duration, function()
    mcontroller.setVelocity({0,0})
  end)

  if stance.shouldInterpolateEnd then
    RBWepUtil.animateStance(stance, self.idleStance, stance.resetDuration, self.dt)
  end
end

function RisingSlash:reset()
  animator.setGlobalTag("directives", "")
  status.clearPersistentEffects("weaponMovementAbility")
end

function RisingSlash:uninit()
  self:reset()
end
