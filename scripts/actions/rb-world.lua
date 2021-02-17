-- param position
-- param layer
-- output hueShift

function rb_materialHueShift(args, board)
  if args.position == nil then return false end
  return true, {hueShift = world.materialHueShift(args.position, args.layer)}
end