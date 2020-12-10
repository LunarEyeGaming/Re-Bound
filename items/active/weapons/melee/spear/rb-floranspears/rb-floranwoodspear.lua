require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  animator.setGlobalTag("directives", "")
  animator.setGlobalTag("bladeDirectives", "")

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  self.primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(self.primaryAbility)

  self.altAbility = getAltAbility()
  self.weapon:addAbility(self.altAbility)

  self.weapon:init()

  self.altAbility.dpsMultiplier = self.altAbility.dpsMultiplier or 1.0
  self.activeBaseDps = self.primaryAbility.baseDps * self.altAbility.dpsMultiplier
  self.inactiveBaseDps = self.primaryAbility.baseDps
  self.inactiveDamageConfig = self.primaryAbility.damageConfig
  self.activeDamageConfig = sb.jsonMerge(self.primaryAbility.damageConfig, self.altAbility.newDamageConfig or {})

  storage.active = (storage.active ~= nil) or false
  self.primaryAbility.animKeyPrefix = ""
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)

  setActive(self.altAbility.active)
end

function uninit()
  self.weapon:uninit()
end

function setActive(active)
  if storage.active ~= active then
    storage.active = active
    if storage.active then
      self.primaryAbility.animKeyPrefix = "active"
      self.primaryAbility.damageConfig = self.activeDamageConfig
      self.primaryAbility.baseDps = self.activeBaseDps
      self.primaryAbility:calculateDamage()
    else
      self.primaryAbility.animKeyPrefix = ""
      self.primaryAbility.damageConfig = self.inactiveDamageConfig
      self.primaryAbility.baseDps = self.inactiveBaseDps
      self.primaryAbility:calculateDamage()
    end
  end
end
