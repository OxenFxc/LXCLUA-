local bindClass = luajava.bindClass
local ResourcesCompat = bindClass "androidx.core.content.res.ResourcesCompat"

if bindClass "android.os.Build".VERSION.SDK_INT >= 28

  local Spannable = bindClass "android.text.Spannable"
  local SpannableString = bindClass "android.text.SpannableString"
  local TypefaceSpan = bindClass "android.text.style.TypefaceSpan"

  return function(str)
    local string = SpannableString(str)
    string.setSpan(TypefaceSpan(ResourcesCompat.getFont(activity, R.font.josefin_sans)), 0, #string,Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
    return string
  end

 else

  return function(str)
    return str
  end

end