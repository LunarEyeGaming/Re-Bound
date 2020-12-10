require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"
require "/items/active/weapons/rb-weaponutil.lua"

TravelingSlash = WeaponAbility:new()

function TravelingSlash:init()
  self.idleStance = self:getGlobalStance("idle")
  self.cooldownTimer = self.cooldownTime
end

function TravelingSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.windup)
  end
end

function TravelingSlash:windup()
  local stance = self.stances.windup
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  if stance.shouldInterpolate then
    RBWepUtil.animateStance(self.idleStance, stance, stance.duration, self.dt)
  else
    util.wait(stance.duration)
  end

  if self.stances.preslash then
    self:setState(self.preslash)
  else
    self:setState(self.fire)
  end
end

function TravelingSlash:preslash()
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

function TravelingSlash:fire()
  local stance = self.stances.fire
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
  local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self:damageAmount()
  }
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)

  animator.playSound(self:slashSound())

  util.wait(stance.duration)
  self.cooldownTimer = self.cooldownTime
  if stance.shouldInterpolateEnd then
    RBWepUtil.animateStance(stance, self.idleStance, stance.resetDuration, self.dt)
  end
end

function TravelingSlash:getGlobalStance(stance)
  for _, ability in pairs(self.weapon.abilities) do
    if ability.stances[stance] then
      return ability.stances[stance]
    end
  end
end

function TravelingSlash:slashSound()
  return self.weapon.elementalType.."TravelSlash"
end

function TravelingSlash:aimVector()
  return {mcontroller.facingDirection(), 0}
end

function TravelingSlash:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function TravelingSlash:uninit()
end