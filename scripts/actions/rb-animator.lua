-- output list
function rb_updateBiomeHueShift(args, board)
  animator.setGlobalTag("biomehueshift", tostring(world.materialHueShift(mcontroller.position(), "background")))
  return true
end