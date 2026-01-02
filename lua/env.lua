require "import"
-- 初始化绑定类
local bindClass = luajava.bindClass
local WindowManager = bindClass "android.view.WindowManager"
local View = bindClass "android.view.View"
local ColorStateList = bindClass "android.content.res.ColorStateList"
local MaterialAlertDialogBuilder = bindClass "com.google.android.material.dialog.MaterialAlertDialogBuilder"
local ClipData = bindClass "android.content.ClipData"
local Context = bindClass "android.content.Context"
local LayoutTransition = bindClass "android.animation.LayoutTransition"
local Color = bindClass "android.graphics.Color"
local TypedValue = bindClass "android.util.TypedValue"
local GradientDrawable = bindClass "android.graphics.drawable.GradientDrawable"
local Configuration = bindClass "android.content.res.Configuration"
local DynamicColors = bindClass "com.google.android.material.color.DynamicColors"
local DynamicColorsOptions = bindClass "com.google.android.material.color.DynamicColorsOptions"
local SQLiteHelper = bindClass "com.difierline.lua.luaappx.utils.SQLiteHelper"(activity)
local AesUtil = bindClass "com.difierline.lua.luaappx.utils.AesUtil"
local SharedPrefUtil = require "utils.SharedPrefUtil"

MDC_R = bindClass "com.google.android.material.R"
R = bindClass "com.difierline.lua.luaappx.R"
AndroidX_R = bindClass "androidx.appcompat.R"

-- 加载自定义模块
Colors = require "Colors"
Colors.colorError = 0xFFFF0000
MyToast = require "utils.MyToast"
res = require "utils.StringUtil"

local UiUtil = require "utils.UiUtil"
dp2px = UiUtil.dp2px

local themes = {
  "Blue",
  "Green"
}

-- 返回值：true 表示系统处于夜间模式
 function isDark()
  local mode = activity.getResources().getConfiguration().uiMode
  & Configuration.UI_MODE_NIGHT_MASK
  return mode == Configuration.UI_MODE_NIGHT_YES
end

-- 获取主题模式：2=总是深色, 3=总是浅色, 1=跟随系统
local function getThemeMode()
  return activity.getSharedData("theme_light_dark") or 1
end

-- 获取主题后缀，根据深色模式设置返回正确的主题名称
local function getThemeSuffix()
  local themeMode = getThemeMode()

  if themeMode == 2 then
    return "_Dark"
  elseif themeMode == 3 then
    return ""
  else
    return isDark() and "_Dark" or ""
  end
end

-- 设置主题
local themeSuffix = getThemeSuffix()
local themeColor = activity.getSharedData("theme_color") or 1

switch themeColor
 case 3
  if themeSuffix == "_Dark" then
    activity.setTheme(R.style.Theme_Material3_Blue_Dark_NoActionBar)
  else
    activity.setTheme(R.style.Theme_Material3_Blue_NoActionBar)
  end
  local builder = DynamicColorsOptions.Builder()
  builder.setContentBasedSource(activity.getSharedData("colorpicker") or 0xFF2196F3)
  DynamicColors.applyToActivityIfAvailable(activity, builder.build())
 default
  local themeName = themes[themeColor] or "Blue"
  activity.setTheme(R.style["Theme_Material3_" .. themeName .. themeSuffix .. "_NoActionBar"])
end

if activity.getSharedData("eyedropper_variant") then
  DynamicColors.applyToActivityIfAvailable(activity)
end

function setStatus()
  local EdgeToEdge = luajava.bindClass"androidx.activity.EdgeToEdge"
  local Build = bindClass "android.os.Build"
  EdgeToEdge.enable(this)
  if Build.VERSION.SDK_INT >= 30 then
    activity.getWindow().setNavigationBarContrastEnforced(false)
  end
  if activity.getSharedData("collapse_toolbar") then
    activity.getWindow().setStatusBarColor(Colors.colorSurfaceContainer)
  end
end

-- 提取颜色配置到常量表
local THEME_COLORS = {
  DARK = {
    ripple = 0x31FFFFFF,
    outline = 0x31EEEEEE,
    scrollTrack = 0xFF4A4644,
    scrollThumbPressed = 0xFF8D878D,
    scrollThumb = 0x99777278
  },
  LIGHT = {
    ripple = 0x31000000,
    outline = 0xFFEEEEEE,
    scrollTrack = 0xFFE8E1DD,
    scrollThumbPressed = 0xFF969194,
    scrollThumb = 0x99A19DA4
  }
}

-- 颜色应用函数
local function applyColors(colors)
  colorRipple = colors.ripple
  colorOutline2 = colors.outline
  SCROLL_BAR_TRACK_COLOR = colors.scrollTrack
  SCROLL_BAR_THUMB_PRESSED_COLOR = colors.scrollThumbPressed
  SCROLL_BAR_THUMB_COLOR = colors.scrollThumb
end

-- 根据主题模式设置颜色变量（不返回模式值）
local function applyThemeColors()
  local themeMode = getThemeMode()

  if themeMode == 2 then
    applyColors(THEME_COLORS.DARK)
  elseif themeMode == 3 then
    applyColors(THEME_COLORS.LIGHT)
  else
    applyColors(isDark() and THEME_COLORS.DARK or THEME_COLORS.LIGHT)
  end
end

-- 获取主题模式值（供 setDefaultNightMode 使用）
local function getNightModeValue()
  local themeMode = getThemeMode()

  if themeMode == 2 then
    return 2 -- MODE_NIGHT_YES
  elseif themeMode == 3 then
    return 1 -- MODE_NIGHT_NO
  else
    return -1 -- MODE_NIGHT_FOLLOW_SYSTEM
  end
end

-- 主配置函数 - 返回 AppCompatDelegate 夜间模式常量
local function configureTheme()
  local themeMode = getThemeMode()

  if themeMode == 2 then
    applyColors(THEME_COLORS.DARK)
    return 2 -- MODE_NIGHT_YES

  elseif themeMode == 3 then
    applyColors(THEME_COLORS.LIGHT)
    return 1 -- MODE_NIGHT_NO

  else -- 默认跟随系统
    applyColors(isDark() and THEME_COLORS.DARK or THEME_COLORS.LIGHT)
    return -1 -- MODE_NIGHT_FOLLOW_SYSTEM
  end
end

-- 先设置颜色变量，确保布局加载时颜色已初始化
applyThemeColors()

-- 设置主题模式
bindClass("androidx.appcompat.app.AppCompatDelegate")
.setDefaultNightMode(getNightModeValue())

-- 获取涟漪效果的 Drawable
function getRipple(code, color)
  local attrs = {code and android.R.attr.selectableItemBackground or android.R.attr.selectableItemBackgroundBorderless}
  local ripple = activity.obtainStyledAttributes(attrs).getResourceId(0, 0)
  local drawable = activity.Resources.getDrawable(ripple)
  drawable.setColor(ColorStateList.valueOf(color or colorRipple))
  return drawable
end

function createCornerGradientDrawable(code, color, color2, top, bottom, stroke)
  return GradientDrawable()
  .setShape(0)
  .setColor(color)
  .setStroke(stroke or dp2px(2), color2)
  .setCornerRadii( {
    top, top,
    top, top,
    bottom, bottom,
    bottom, bottom
  })
end

-- 创建新的 LayoutTransition
function newLayoutTransition(code)
  local transition = LayoutTransition()
  -- 仅对可见性变化添加动画
  .enableTransitionType(LayoutTransition.CHANGING)
  .enableTransitionType(LayoutTransition.APPEARING)
  .enableTransitionType(LayoutTransition.DISAPPEARING)

  -- 只有当code为true时，才禁用指定的过渡类型
  if code then
    transition = transition
    .disableTransitionType(LayoutTransition.CHANGE_APPEARING)
    .disableTransitionType(LayoutTransition.CHANGE_DISAPPEARING)
  end

  -- 设置动画时长
  return transition.setDuration(250)
end

function fadeInStagger(options)
  for i, option in ipairs(options) do
    option.alpha = 0
    option.animate()
    .alpha(1)
    .setDuration(300)
    .setStartDelay(i * 50)
    .start()
  end
end

function getSQLite(count)
  local SQLite = luajava.astable(SQLiteHelper.getUser())
  return tostring(AesUtil.decryptFromBase64(SharedPrefUtil.getString("username") or "", tostring(SQLite[count])))
end

-- 显示错误对话框
function onError(title, message)
  MaterialAlertDialogBuilder(activity)
  .setTitle(tostring(title))
  .setMessage(tostring(message))
  .setPositiveButton(res.string.ok, nil)
  .setNegativeButton(res.string.copy, function()
    local cm = activity.getSystemService(Context.CLIPBOARD_SERVICE)
    cm.setPrimaryClip(ClipData.newPlainText("label", tostring(message)))
  end)
  .show()
end