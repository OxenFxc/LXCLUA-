local _M = {}
local bindClass = luajava.bindClass
local Activity = bindClass "android.app.Activity"
local Context = bindClass "android.content.Context"
local json = require "cjson"

local function dump(val, indent)
  indent = indent or 0
  local prefix = string.rep("  ", indent)

  if type(val) == "table" then
    local pieces = {}
    table.insert(pieces, "{")

    -- 先打印数组部分，保持顺序
    for i, v in ipairs(val) do
      table.insert(pieces, prefix .. "  " .. dump(v, indent + 1) .. ",")
    end

    -- 再打印哈希部分（键值对）
    for k, v in pairs(val) do
      -- 跳过已经在 ipairs 里处理过的数组键
      if type(k) ~= "number" or k < 1 or k > #val or math.floor(k) ~= k then
        table.insert(pieces,
          prefix .. "  " .. "[" .. dump(k, 0) .. "] = " .. dump(v, indent + 1) .. ",")
      end
    end

    table.insert(pieces, prefix .. "}")
    return table.concat(pieces, "\n")
  else
    return type(val) == "string" and string.format("%q", val) or tostring(val)
  end
end

-- 写入数据（支持Table/普通类型）
function _M.set(key, value)
  if not key then
    return
  end

  local sp = activity.getSharedPreferences("SharedPref", 0)
  local editor = sp.edit()

  -- 处理不同类型的值
  if type(value) == "table" then
    local jsonStr = json.encode(value)
    if jsonStr then
      editor.putString(key, dump(value))
--      print(jsonStr)
      editor.apply()
      return true
     else
      return false
    end
   elseif type(value) == "string" then
    editor.putString(key, value)
   elseif type(value) == "boolean" then
    editor.putBoolean(key, value)
   elseif type(value) == "number" then
    editor.putString(key, tostring(value))
   else
    return false
  end

  editor.apply()
  return true
end


-- 公共参数校验函数
local function checkParams(key)
  return activity.getSharedPreferences("SharedPref", 0)
end

-- 读取字符串
function _M.getString(key)
  local sp = checkParams(key)
  local strValue = sp.getString(key, nil)
  return strValue
end

-- 读取布尔值
function _M.getBoolean(key, defaultValue)
  if not key then
    return defaultValue or false
  end

  local sp = activity.getSharedPreferences("SharedPref", 0)
  return sp.getBoolean(key, defaultValue or false) -- 直接使用 getBoolean 方法
end

-- 读取数字
function _M.getNumber(key)
  local sp = checkParams(key)
  if not sp then return defaultValue end
  local strValue = sp.getString(key, nil)
  return tonumber(strValue)
end

-- 读取Table
function _M.getTable(key)
  local sp = checkParams(key)
  local strValue = sp.getString(key, nil)
  if not strValue then
    return
  end
  local tableValue = load("return " .. strValue)()
  return tableValue
end

-- 移除指定键值
function _M.remove(key)
  if not key then
    return
  end
  local sp = activity.getSharedPreferences("SharedPref", 0)
  local editor = sp.edit()
  editor.remove(key)
  editor.apply()
  return true
end

-- 清空所有数据
function _M.clear()
  local sp = activity.getSharedPreferences("SharedPref", 0)
  local editor = sp.edit()
  editor.clear()
  editor.apply()
  return true
end

return _M