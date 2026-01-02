local _M = {}
local bindClass = luajava.bindClass
local TimeUnit = bindClass "java.util.concurrent.TimeUnit"
local Dispatcher = bindClass "okhttp3.Dispatcher"
local RequestBody = bindClass "okhttp3.RequestBody"
local MediaType = bindClass "okhttp3.MediaType"
local OkHttpClient = bindClass "okhttp3.OkHttpClient"
local Callback = bindClass "okhttp3.Callback"
local MultipartBody = bindClass "okhttp3.MultipartBody"
local Request = bindClass "okhttp3.Request"
local File = bindClass "java.io.File"
local FileOutputStream = bindClass "java.io.FileOutputStream"
local Runnable = bindClass "java.lang.Runnable"
local Http = bindClass "com.difierline.lua.Http"
local cjson = require "cjson"
local FileUtil = require "utils.FileUtil"
local PathUtil = require "utils.PathUtil"
local ProgressMaterialAlertDialog = require "dialogs.ProgressMaterialAlertDialog"

-- 请求管理表
local pendingCalls = {}
local requestIdCounter = 0

local function parse_error_message(error_msg)
  local result = {}

  -- 提取错误类型
  result.error_type = error_msg:match("<b>(.-)</b>") or "Unknown Error"

  -- 提取错误描述
  result.error_desc = error_msg:match(":</b>%s*(.-)%s*in%s*[^<]*")
  if result.error_desc then
    result.error_desc = result.error_desc:gsub("/[^%s]*", "[PATH_FILTERED]")
    :gsub("%s+", " ")
    :gsub("^%s*(.-)%s*$", "%1")
  end

  -- 提取文件名（不包含路径）
  local full_path = error_msg:match("in%s*[^<]-([^%s]+%.%w+:%d+)") or
  error_msg:match("in%s*[^<]-([^%s]+:%d+)")

  if full_path then
    result.filename = full_path:match("([^/:]+):%d+$") or
    full_path:match("([^/:]+)%..+:%d+$") or
    full_path:match("([^/:]+):%d+$")
    result.line = full_path:match(":(%d+)$")
  end

  -- 备用方法提取行号
  if not result.line then
    result.line = error_msg:match("line%s*<b>%s*(%d+)%s*</b>") or
    error_msg:match("(%d+)Stack trace:") or
    error_msg:match(":(%d+)Stack trace:")
  end

  return result
end

function _M.print(str)
  if pcall(_M.decode, str) then
    print(dump(_M.decode(str)))
   else
    print(str)
  end
end

function _M.error(str)
  local result = parse_error_message(str)
  local lines = {
    "Error Type: " .. result.error_type,
    "Error Description: " .. (result.error_desc or "N/A"),
    "File: " .. (result.filename or "N/A"),
    "Line: " .. (result.line or "N/A"),
  }
  MyToast(table.concat(lines, "\n"))
end

-- 初始化HTTP客户端
if not _M.client then
  _M.client = OkHttpClient.Builder()
  .connectTimeout(10, TimeUnit.SECONDS) -- 设置连接超时10秒
  .readTimeout(30, TimeUnit.SECONDS) -- 设置读取超时30秒
  .writeTimeout(30, TimeUnit.SECONDS) -- 设置写入超时30秒
  .dispatcher(Dispatcher().setMaxRequests(5)) -- 设置最大并发请求数
  .dispatcher(Dispatcher().setMaxRequestsPerHost(2)) -- 设置每个主机的最大并发请求数
  .build()
end

-- JSON解码函数
_M.decode = cjson.decode
_M.cecode = cjson.encode

function get(url, header, followRedirects, callback)
  header = header or {}
  followRedirects = followRedirects == nil and true or followRedirects
  callback = callback or nil

  local clientBuilder = _M.client.newBuilder()
  clientBuilder.followRedirects(followRedirects)
  local client = clientBuilder.build()
  local requestBuilder = Request.Builder().url(url).get()

  if not header["User-Agent"] then
    header["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  end

  for key, value in pairs(header) do
    requestBuilder.header(key, value)
  end

  local request = requestBuilder.build()
  local call = client.newCall(request)

  -- 请求ID管理
  requestIdCounter = requestIdCounter + 1
  local currentRequestId = requestIdCounter
  pendingCalls[currentRequestId] = call

  call.enqueue(Callback{
    onFailure = function(call, e)
      -- 从管理表中移除
      pendingCalls[currentRequestId] = nil

      activity.runOnUiThread(Runnable{
        run = function()
          if dialog_code == true then
            dialog_okhttp.dismiss()
          end
          callback(-1, e)
        end
      })
    end,
    onResponse = function(call, response)
      -- 从管理表中移除
      pendingCalls[currentRequestId] = nil

      local code = response.code()
      local content = response.body().string()
      local headers = luajava.astable(response.headers())
      activity.runOnUiThread(Runnable {
        run = function()
          if dialog_code == true then
            dialog_okhttp.dismiss()
          end
          callback(code, content)
        end
      })
    end
  })
end


-- 通用HTTP请求函数
local function post(url, postParams, header, callback)
  local postParams = postParams or {}
  local header = header or {}
  local callback = callback or nil
  local json = cjson.encode(postParams)
  local requestBody = RequestBody.create(MediaType.parse("application/json; charset=utf-8"), json)
  local requestBuilder = Request.Builder().url(url).post(requestBody)

  for key, value in pairs(header) do
    requestBuilder.header(key, value)
  end

  local request = requestBuilder.build()
  local call = _M.client.newCall(request)

  -- 请求ID管理
  requestIdCounter = requestIdCounter + 1
  local currentRequestId = requestIdCounter
  pendingCalls[currentRequestId] = call

  call.enqueue(Callback {
    onFailure = function(call, e)
      -- 从管理表中移除
      pendingCalls[currentRequestId] = nil

      activity.runOnUiThread(Runnable {
        run = function()
          if dialog_code == true then
            dialog_okhttp.dismiss()
          end
          callback(404, e)
        end
      })
    end,

    onResponse = function(call, response)
      -- 从管理表中移除
      pendingCalls[currentRequestId] = nil

      local code = response.code()
      local content = response.body().string()
      local headers = luajava.astable(response.headers())
      activity.runOnUiThread(Runnable {
        run = function()
          if dialog_code == true then
            dialog_okhttp.dismiss()
          end
          callback(code, content)
        end
      })
    end
  })
end

local function addFileToRequestBody(fieldName, filePath, builder)
  local imageFile = File(filePath)
  if imageFile.exists() then
    local mediaType = MediaType.parse("*/*")
    local fileBody = RequestBody.create(mediaType, imageFile)
    builder.addFormDataPart(fieldName, imageFile.getName(), fileBody)
  end
end

-- 通用多文件上传函数
local function upload(url, postParams, files, header, callback)
  -- 1. 初始化Multipart请求体构建器
  local requestBodyBuilder = MultipartBody.Builder()
  requestBodyBuilder.setType(MultipartBody.FORM)

  -- 2. 添加表单参数
  if postParams and next(postParams) ~= nil then
    for key, value in pairs(postParams) do
      requestBodyBuilder.addFormDataPart(key, tostring(value))
    end
  end

  local function processFiles(fieldName, fileData, builder)
    if type(fileData) == "string" then
      -- 单个文件路径
      addFileToRequestBody(fieldName, fileData, builder)
     elseif type(fileData) == "table" then
      for _, item in ipairs(fileData) do
        if type(item) == "string" then
          -- 路径数组中的文件
          addFileToRequestBody(fieldName, item, builder)
         elseif type(item) == "table" then
          -- 递归处理嵌套表
          processFiles(fieldName, item, builder)
        end
      end
    end
  end

  -- 3. 添加上传文件（支持多文件）
  if files and next(files) ~= nil then
    for fieldName, fileData in pairs(files) do
      processFiles(fieldName, fileData, requestBodyBuilder)
    end
  end

  -- 4. 构建请求体
  local requestBody = requestBodyBuilder.build()

  -- 5. 构建请求
  local requestBuilder = Request.Builder()
  requestBuilder.url(url)

  -- 添加请求头
  if header and next(header) ~= nil then
    for key, value in pairs(header) do
      requestBuilder.addHeader(key, tostring(value))
    end
  end

  requestBuilder.post(requestBody)
  local request = requestBuilder.build()

  -- 6. 发起异步请求
  local client = OkHttpClient()
  local call = client.newCall(request)

  -- 请求ID管理
  requestIdCounter = requestIdCounter + 1
  local currentRequestId = requestIdCounter
  pendingCalls[currentRequestId] = call

  call.enqueue(Callback {
    onFailure = function(call, e)
      -- 从管理表中移除
      pendingCalls[currentRequestId] = nil

      activity.runOnUiThread(Runnable {
        run = function()
          if dialog_code2 == true then
            dialog_okhttp2.dismiss()
          end
          callback(404, "404")
        end
      })
    end,

    onResponse = function(call, response)
      -- 从管理表中移除
      pendingCalls[currentRequestId] = nil

      local code = response.code()
      local content = response.body().string()
      activity.runOnUiThread(Runnable {
        run = function()
          if dialog_code2 == true then
            dialog_okhttp2.dismiss()
          end
          callback(code, content)
        end
      })
    end
  })
end

-- POST请求封装
function _M.post(code, url, data, header, callback)
  dialog_code = code
  if code == true then
    dialog_okhttp = ProgressMaterialAlertDialog(activity).show()
  end
  post(url, data, header, callback)
end

-- 文件上传封装
function _M.upload(code, url, data, file, header, callback)
  dialog_code2 = code
  if code == true then
    dialog_okhttp2 = ProgressMaterialAlertDialog(activity).show()
  end
  upload(url, data, file, header, callback)
end

-- GET请求封装
function _M.get(code, url, header, followRedirects, callback)
  dialog_code = code
  if code == true then
    dialog_okhttp = ProgressMaterialAlertDialog(activity).show()
  end
  get(url, header, followRedirects, callback)
end

-- 文件下载封装
function _M.download(code, url, savePath, header, callback)
  dialog_code3 = code
  if code == true then
    dialog_okhttp3 = ProgressMaterialAlertDialog(activity).show()
  end
  --download(url, savePath, header, callback)
  Http.download(url, savePath, nil , header, callback)
end

-- 取消所有请求
function _M.cancelAllRequests()
  for requestId, call in pairs(pendingCalls) do
    if not call.isCanceled() then
      call.cancel()
    end
    pendingCalls[requestId] = nil
  end
  requestIdCounter = 0
end

-- 清理对话框
function _M.cleanupDialogs()
  if dialog_okhttp and dialog_okhttp.isShowing() then
    dialog_okhttp.dismiss()
    dialog_okhttp = nil
  end
  if dialog_okhttp2 and dialog_okhttp2.isShowing() then
    dialog_okhttp2.dismiss()
    dialog_okhttp2 = nil
  end
  if dialog_okhttp3 and dialog_okhttp3.isShowing() then
    dialog_okhttp3.dismiss()
    dialog_okhttp3 = nil
  end
end

return _M