--[[
  Re:bound Mod Script -- Weapon Util
  This script includes utility functions for weapon scripts.
]]

RBWepUtil = {}

-- Animates the transition from one stance to another through linear interpolation.
function RBWepUtil.animateStance(startStance, endStance, duration, dt)
  local progress = 0
  util.wait(duration, function()
    RBWepUtil.lerpStance(startStance, endStance, progress)
    progress = math.min(1.0, progress + (dt / duration))
  end)
end

-- Applies the linear interpolation operation to weapon offset, weapon rotation, and arm rotation.
function RBWepUtil.lerpStance(startStance, endStance, progress)
  local stance = RBWepUtil.getLerpStance(startStance, endStance, progress)
  self.weapon.weaponOffset = stance.weaponOffset

  self.weapon.relativeWeaponRotation = util.toRadians(stance.weaponRotation)
  self.weapon.relativeArmRotation = util.toRadians(stance.armRotation)
end

-- Returns a stance with linear interpolation applied to it.
function RBWepUtil.getLerpStance(startStance, endStance, progress)
  local startWeaponOffset = startStance.weaponOffset or {0,0}
  local endWeaponOffset = endStance.weaponOffset or {0,0}

  local stance = {}
  stance.weaponOffset = {interp.linear(progress, startWeaponOffset[1], endWeaponOffset[1]), interp.linear(progress, startWeaponOffset[2], endWeaponOffset[2])}
  stance.weaponRotation = interp.linear(progress, startStance.weaponRotation, endStance.weaponRotation)
  stance.armRotation = interp.linear(progress, startStance.armRotation, endStance.armRotation)
  return stance
end