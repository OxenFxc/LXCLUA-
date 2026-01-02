local _M = {}
local bindClass = luajava.bindClass
local Typeface = bindClass "android.graphics.Typeface"
local VERSION = bindClass "android.os.Build$VERSION"
local Spannable = bindClass "android.text.Spannable"
local SpannableString = bindClass "android.text.SpannableString"
local ForegroundColorSpan = bindClass "android.text.style.ForegroundColorSpan"
local AbsoluteSizeSpan = bindClass "android.text.style.AbsoluteSizeSpan"
local TypefaceSpan = bindClass "android.text.style.TypefaceSpan"
local TITLE_ID = 99

function _M.setHeaderTitle(popup, str)
  local str = SpannableString(str)
  str.setSpan(
  ForegroundColorSpan(Colors.colorPrimary), -- 设置颜色
  0, #str, Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
  str.setSpan(
  AbsoluteSizeSpan(dp2px(16)), -- 微调字号
  0, #str, Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
  if VERSION.SDK_INT >= 29 then -- Android Q 开始可以使用 Typeface 对象
    str.setSpan(
    TypefaceSpan(Typeface.DEFAULT_BOLD),
    0, #str, Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
  end
  popup.Menu.add(TITLE_ID, TITLE_ID, 0, str)
  popup.Menu.setGroupEnabled(TITLE_ID, false) -- 禁止点击 item
end

return _M