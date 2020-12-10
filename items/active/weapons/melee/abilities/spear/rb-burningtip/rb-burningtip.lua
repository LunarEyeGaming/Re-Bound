require "/scripts/util.lua"

BurningTip = WeaponAbility:new()

function BurningTip:init()
  self.burnoutTag = self.burnoutTag or ""
  self.burnTimer = self.burnTime
  self.cooldownTimer = self.cooldownTime

  self.active = false
  animator.setPartTag("blade", "abilityDirectives", "")
  animator.setParticleEmitterActive("flame", false)
  animator.setParticleEmitterActive("flameweak", false)
  animator.setAnimationState("flame", "inactive")
  animator.setAnimationState("torch", "invisible")
end

function BurningTip:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  
  if self.active then
    if self.burnTimer < self.lowBurnTimeThreshold then
      animator.setParticleEmitterActive("flame", false)
    end
    self.burnTimer = math.max(0, self.burnTimer - self.dt)
    local progress = self.burnTimer / self.burnTime
    animator.setPartTag("blade", "abilityDirectives", "?fade=da5302=0.75")
  end
  
  if self.burnTimer == 0 then
    self:setState(self.burnout)
  end

  if fireMode == "alt"
      and not self.weapon.currentAbility
      and not self.active
      and self.cooldownTimer == 0
      and not status.resourceLocked("energy")
      and status.overConsumeResource("energy", self.energyCost) then
    self:setState(self.ignite)
  end
end

function BurningTip:ignite()
  animator.setAnimationState("torch", "visible")
  self.weapon:setStance(self.stances.preignite)
  animator.resetTransformationGroup("torch")
  animator.rotateTransformationGroup("torch", util.toRadians(self.stances.preignite.torchRotation or 0))
  util.wait(self.stances.preignite.duration)

  animator.playSound("ignite")
  self.active = true
  animator.setAnimationState("flame", "active")
  animator.setParticleEmitterActive("flame", true)
  animator.setParticleEmitterActive("flameweak", true)
  
  self.weapon:setStance(self.stances.ignite)
  animator.resetTransformationGroup("torch")
  animator.rotateTransformationGroup("torch", util.toRadians(self.stances.ignite.torchRotation or 0))
  util.wait(self.stances.ignite.duration)
  animator.setAnimationState("torch", "invisible")
end

function BurningTip:burnout()
  self.weapon:setStance(self.stances.idle)

  animator.playSound("burnout")
  self.active = false
  animator.setAnimationState("flame", "inactive")
  animator.setParticleEmitterActive("flame", false)
  animator.setParticleEmitterActive("flameweak", false)

  self.burnTimer = self.burnTime
  
  local progress = 0
  util.wait(self.burnoutTime, function()
    self:updateBurnoutTag(progress)
    progress = math.min(1.0, progress + (self.dt / self.burnoutTime))
  end)

  animator.setPartTag("blade", "abilityDirectives", "")
  self.cooldownTimer = self.cooldownTime
end

function BurningTip:updateBurnoutTag(progress)
  local burnoutValues = {}
  for i = 1, #self.burnoutStartValues do
    local burnoutValue = util.lerp(progress, self.burnoutStartValues[i], self.burnoutEndValues[i])
    table.insert(burnoutValues, burnoutValue)
  end
  local burnoutTag = string.format(self.burnoutTag, table.unpack(burnoutValues))
  animator.setPartTag("blade", "abilityDirectives", burnoutTag)
end

function BurningTip:uninit()

end