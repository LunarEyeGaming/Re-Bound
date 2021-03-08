function init()
  self.queryRadius = 50
  self.maxDensity = 0.008
  
  self.maxProjectiles = math.pi * self.queryRadius ^ 2 * self.maxDensity
  
  self.shouldSpawn = true
end

function update()  
  local projectiles = world.entityQuery(mcontroller.position(), self.queryRadius, {includedTypes = {"projectile"}})
  world.debugText("%s / %s", #projectiles, self.maxProjectiles, mcontroller.position(), "green")
  if #projectiles > self.maxProjectiles then
    self.shouldSpawn = false
  end
end

function destroy()
  if self.shouldSpawn then
    projectile.processAction(projectile.getParameter("spawnAction"))
  end
end
