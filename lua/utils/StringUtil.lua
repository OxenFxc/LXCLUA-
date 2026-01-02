local bindClass = luajava.bindClass
local File = bindClass "java.io.File"
local exists = io.isdir
local tconst = table.tconst
local luadir = activity.luaDir .. "/"
local Locale = bindClass "java.util.Locale"

-- 创建一个元表包装器
local function Meta(func)
  return setmetatable({}, { __index = func })
end

-- 读取文件内容
local function loadFile(path)
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    return content
  end
  return nil
end

-- 加载 Lua 文件并执行
local function loadLuaFile(path, env)
  local content = loadFile(path)
  if content then
    local chunk, err = load(content, "@" .. path, "bt", env or _G)
    if chunk then
      return chunk()
    else
      error(err)
    end
  end
  return nil
end

-- 加载 Lua 文件并合并到目标表中
local function loadTableFromLuaFile(filePath, destTable)
  local content = loadFile(filePath)
  if content then
    local chunk, err = load(content, "@" .. filePath, "bt", destTable)
    if chunk then
      chunk()
    else
      error(err)
    end
  end
end

-- 合并两个表
local function mergeTables(sourceTable, destTable)
  for k, v in pairs(sourceTable) do
    destTable[k] = v
  end
end

-- 初始化资源表
local res = {
  env = _G,
  language = Locale.getDefault().language,
  orientation = activity.resources.configuration.orientation,
  string = {},
}
-- 加载初始化字符串
loadTableFromLuaFile(luadir .. "res/string/init.lua", res.string)

-- 加载语言文件
local langFilePath = luadir .. "res/string/" .. res.language .. ".lua"
if not File(langFilePath).isFile() then
  res.defaultLanguage = loadLuaFile(luadir .. "res/string/default.lua")
  langFilePath = luadir .. "res/string/" .. res.defaultLanguage .. ".lua"
  
end
loadTableFromLuaFile(langFilePath, res.string)

-- 将字符串表设置为常量表
res.string = tconst(res.string)

return res