local SharedPrefUtil = require "utils.SharedPrefUtil"
local SQLiteHelper = luajava.bindClass "com.difierline.lua.luaappx.utils.SQLiteHelper"(activity)

-- 定义默认配置键值对
local defaultConfigs = {
  theme_color = 1,
  font_path = 1,
  fragment_animation = 1,
  theme_light_dark = 1,
  icon_load_mode = 1,
  check_for_updated = true,
  request_interception = true,
  is_sora = true,
  class_name_highlight = 0xFF6E81D9,
  local_variable_highlight = 0xFFAAAA88,
  keyword_highlight = 0xFFFF565E, 
  function_name_highlight = 0xFF2196F3,
  dividing_line_color = 0xEEEEEEEE,
  value_min = "20",
  value_max = "80",
}

-- 遍历配置项，统一设置默认值
for key, defaultValue in pairs(defaultConfigs) do
  if activity.getSharedData(key) == nil then
    activity.setSharedData(key, defaultValue)
  end
end

if type(activity.getSharedData("font_path")) == "string" then
  activity.setSharedData("font_path", 1)
end

if SharedPrefUtil.getString("token") or (not SharedPrefUtil.getBoolean("is_login")) then
  SharedPrefUtil.remove("token")
  SharedPrefUtil.set("username", "")
  SharedPrefUtil.remove("password")
  SQLiteHelper.setUser("", "", "")
  activity.showToast("请重新登录")
end