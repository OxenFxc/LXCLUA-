local _M = {}
local bindClass = luajava.bindClass
local ZipFile = bindClass "java.util.zip.ZipFile"
local BitmapFactory = bindClass "android.graphics.BitmapFactory"
local File = bindClass "java.io.File"
local LuaUtil = bindClass "com.difierline.lua.LuaUtil"
local Calendar = bindClass "android.icu.util.Calendar"
local BufferedReader = bindClass "java.io.BufferedReader"
local FileInputStream = bindClass "java.io.FileInputStream"
local InputStreamReader = bindClass "java.io.InputStreamReader"
local StringBuffer = bindClass "java.lang.StringBuffer"
local BufferedWriter = bindClass "java.io.BufferedWriter"
local FileWriter = bindClass "java.io.FileWriter"
local PathUtil = require "utils.PathUtil"
local cjson = require "cjson"

-- 解析项目清单文件
local function parseManifest(manifestPath)
  if not _M.isExist(manifestPath) then return end
  local success, content = pcall(_M.read, manifestPath)
  if not success then return end
  local v = cjson.decode(content)
  local application = v.application
  if not v then return end
  return {
    label = application.label or "No label.",
    version = v.versionName or "No versionName.",
  }
end

function _M.checkBackup()
  local backup = File(PathUtil.media_backup_path .. "/" .. os.date("%Y-%m-%d"))
  if not backup.exists() then
    backup.mkdirs()
  end
end

function _M.create(path,content)
  local file = File(path)
  if not file.exists() then
    file.createNewFile()
    _M.write(path, content)
  end
end

function _M.read(filePath)
  local text = StringBuffer()
  local fin = FileInputStream(filePath)
  local reader = InputStreamReader(fin)
  local buffReader = BufferedReader(reader)
  local text_line = buffReader.readLine()
  text.append(text_line)
  if text_line == nil then
    buffReader.close()
    return ""
   else
    while (text_line ~= nil)
      text_line = buffReader.readLine()
      if text_line ~= nil then
        text.append("\n")
        text.append(text_line)
      end
    end
    buffReader.close()
    return text.toString()
  end
end

function _M.write(path, content)
  -- 尝试打开文件
  local file, err = io.open(path, "w")
  if not file then
    return false, err -- 打开失败时返回错误
  end

  -- 尝试写入内容
  local success, writeErr = file:write(content)
  if not success then
    file:close() -- 写入失败时关闭文件
    return false, writeErr
  end

  -- 成功写入后关闭文件
  file:close()
  return true
end

function _M.getBitmapFromZip(zipFilePath, imageFilePath)
  local bitmap = nil
  local zipFile = ZipFile(zipFilePath)
  local entry = zipFile.getEntry(imageFilePath)
  if entry == nil then
    return nil
  end
  local inputStream = zipFile.getInputStream(entry)
  bitmap = BitmapFactory.decodeStream(inputStream)
  inputStream.close()
  zipFile.close()
  return bitmap
end

function _M.isExist(path)
  local file = io.open(path, "r")
  if file ~= nil then
    io.close(file)
    return true
   else
    return false
  end
end

function _M.createDirectory(dirPath)
  local dirPath = File(dirPath)
  return (function() if not dirPath.exists() then
      return dirPath.mkdirs()
    end
  end)()
end

function _M.createFile(path)
  local file = io.open(path, 'w')
  file:write("")
  file:close()
  return file
end

function _M.zip(zipFilePath, destDirectory)
  return LuaUtil.zip(zipFilePath, destDirectory)
end

function _M.unzip(zipFilePath, destDirectory)
  return LuaUtil.unZip(zipFilePath, destDirectory)
end

function _M.copy(filePath, dest)
  return LuaUtil.copyDir(filePath, dest)
end

function _M.getFileExtension(path)
  return path:match(".+%.(%w+)$")
end

function _M.getFileNameWithoutExt(path)
  local fileName = path:match(".+/([^/]+)$") or path
  return fileName:match("(.+)%..+$") or fileName
end

function _M.rename(path, path2)
  return os.rename(path, path2)
end

function _M.getParent(path)
  return tostring(File(path).getParentFile())
end

function _M.isFile(path)
  return File(path).isFile()
end

function _M.isExists(path)
  return File(path).exists()
end

function _M.getName(path)
  return path:match(".+/(.+)$")
end

function _M.remove(path)
  return os.execute([[rm -rf "]] .. path .. [["]])
end

function _M.getFilelastTime(path)
  local f = File(path)
  local cal = Calendar.getInstance()
  local time = f.lastModified()
  cal.setTimeInMillis(time)
  return cal.getTime().toLocaleString()
end

function _M.isExist(path)
  local f = io.open(path,'r')
  if f ~= nil then
    io.close(f)
    return true
   else
    return false
  end
end

function _M.traversalProject()
  local PathUtil = require "utils.PathUtil"
  local lfs = require "lfs"
  local path = PathUtil.project_path
  local list = {}
  --检查路径是否存在且是目录
  local attr = lfs.attributes(path)
  if attr and attr.mode == "directory" then
    -- 遍历目录中的所有文件和子目录
    for file in lfs.dir(path) do
      if file ~= "." and file ~= ".." then -- 跳过 "." 和 ".."
        local filePath = path .. "/" .. file
        local fileAttr = lfs.attributes(filePath)
        if fileAttr and fileAttr.mode == "directory" then
          table.insert(list, filePath)
        end
      end
    end
  end
  return list
end

function _M.traversalTemplate()
  local PathUtil = require "utils.PathUtil"
  local lfs = require "lfs"
  local path = PathUtil.templates_path
  local list = {}
  -- 检查路径是否存在且是目录
  local attr = lfs.attributes(path)
  if attr and attr.mode == "directory" then
    -- 遍历目录中的所有文件和子目录
    for file in lfs.dir(path) do
      if file ~= "." and file ~= ".." then -- 跳过 "." 和 ".."
        local filePath = path .. "/" .. file
        local fileAttr = lfs.attributes(filePath)
        if fileAttr and fileAttr.mode == "file" then
          table.insert(list, filePath)
        end
      end
    end
  end
  return list
end

function _M.replaceFileString(path, str1, str2)
  local file = io.open(path, "r")
  local text = file:read("*all")
  file:close()
  text = text:gsub(str1, str2)
  file = io.open(path, "w")
  file:write(text)
  file:close()
end

function _M.backup(path)
  local e, info = pcall(parseManifest, path .. "/manifest.json")
  if e then
    local alppath = PathUtil.backup_path .. "/" .. info.label .. "_" .. tostring(info.version):gsub("%.", "_") .. "_" .. os.date("%y%m%d%H%M%S") .. ".alp"
    if _M.zip(path, PathUtil.backup_path)
      _M.rename(PathUtil.backup_path .. "/" .. _M.getName(path) .. ".zip", alppath)
      return alppath
     else
      return false
    end
   else
    return false
  end
end

return _M