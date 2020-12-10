require "/items/active/weapons/melee/meleeslash.lua"

-- Spear stab attack
-- Extends normal melee attack and adds a hold state
SpearStab = MeleeSlash:new()

function SpearStab:init()
  MeleeSlash.init(self)

  self.holdDamageConfig = sb.jsonMerge(self.damageConfig, self.holdDamageConfig)
  self.holdDamageConfig.baseDamage = self.holdDamageMultiplier * self.damageConfig.baseDamage
end

function SpearStab:fire()
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

  if self.fireMode == "primary" and self.allowHold ~= false then
    self:setState(self.hold)
    return
  end

  if stance.shouldInterpolateEnd then
    RBWepUtil.animateStance(stance, self.stances.idle, stance.resetDuration, self.dt)
  end
end

function SpearStab:hold()
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

  while self.fireMode == "primary" do
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.holdDamageConfig, damageArea)
    coroutine.yield()
  end

  if self.stances.hold.shouldInterpolateEnd then
    RBWepUtil.animateStance(self.stances.hold, self.stances.idle, self.stances.hold.resetDuration, self.dt)
  end

  self.cooldownTimer = self:cooldownTime()
end
