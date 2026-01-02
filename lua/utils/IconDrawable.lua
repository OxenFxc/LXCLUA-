local bindClass = luajava.bindClass 
local PorterDuffColorFilter = bindClass "android.graphics.PorterDuffColorFilter"
local PorterDuff = bindClass "android.graphics.PorterDuff"
local BitmapDrawable = bindClass "android.graphics.drawable.BitmapDrawable"
local Bitmap = bindClass "android.graphics.Bitmap"
local Matrix = bindClass "android.graphics.Matrix"
local TypedValue = bindClass "android.util.TypedValue"

return function(image, color, viewSizeDp)
  local colorFilter
  if color ~= "none" and color ~= 0 and color ~= nil then
    colorFilter = PorterDuffColorFilter(
    color or 0xff5f6368, PorterDuff.Mode.SRC_ATOP)
  end
  local bitmap = LuaBitmap
  .getLocalBitmap(activity.LuaDir .. "/res/drawable/" .. image .. ".png")
  local size = bitmap.Width
  local viewSizeDp = viewSizeDp or 24
  local r = activity.Resources.DisplayMetrics
  local scale = TypedValue.applyDimension(
  TypedValue.COMPLEX_UNIT_DIP, viewSizeDp, r) / size
  local matrix = Matrix()
  matrix.postScale(scale, scale)

  local bitmap = Bitmap.createBitmap(
  bitmap, 0, 0, size, size, matrix, true)
  return BitmapDrawable(activity.Resources, bitmap)
  .setColorFilter(colorFilter)
end