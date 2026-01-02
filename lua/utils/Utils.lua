local _M = {}
local bindClass = luajava.bindClass
local ContentUris = bindClass "android.content.ContentUris"
local Uri = bindClass "android.net.Uri"
local Build = bindClass "android.os.Build"
local Environment = bindClass "android.os.Environment"
local DocumentsContract = bindClass "android.provider.DocumentsContract"
local MediaStore = bindClass "android.provider.MediaStore"
local DialogInterface = bindClass "android.content.DialogInterface"
local Dialog = bindClass "android.app.Dialog"
local View = bindClass "android.view.View"

function _M.changed(id)
  id.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      if s ~= "" then
        id.setErrorEnabled(false)
      end
    end
  })
  return _M
end

function _M.onShow(id, callback)
  id.setOnShowListener(DialogInterface.OnShowListener{
    onShow = function(dialog)
      id.getButton(Dialog.BUTTON_POSITIVE).setOnClickListener(View.OnClickListener
      {
        onClick=function()
          callback()
        end
      })
    end
  })
  return _M
end

local function isExternalStorageDocument(uri)
  return uri.authority == "com.android.externalstorage.documents"
end

local function isDownloadsDocument(uri)
  return uri.authority == "com.android.providers.downloads.documents"
end

local function isMediaDocument(uri)
  return uri.authority == "com.android.providers.media.documents"
end

function _M.uri2path(uri)
  local needToCheckUri = Build.VERSION.SDK_INT >= 19
  local selection
  local selectionArgs

  if needToCheckUri and DocumentsContract.isDocumentUri(activity, uri) then
    if isExternalStorageDocument(uri) then
      local docId = DocumentsContract.getDocumentId(uri)
      local split = String(docId).split(":")
      -- 修复: 使用 # 替代 .length
      return Environment.externalStorageDirectory.toString() .. "/" .. split[1]

     elseif isDownloadsDocument(uri) then
      local id = DocumentsContract.getDocumentId(uri)

      -- Handle both numeric IDs and raw file paths
      if id:match("^%d+$") then
        -- Numeric ID case
        uri = ContentUris.withAppendedId(
        Uri.parse("content://downloads/public_downloads"),
        Long.valueOf(id)
        )
       else
        -- Handle non-numeric IDs (raw paths or other formats)
        local split = String(id).split(":")
        -- 修复: 使用 # 替代 .length
        if split and #split >= 2 then
          -- Try to parse the second part as numeric ID
          local numericPart = split[1]
          if numericPart:match("^%d+$") then
            uri = ContentUris.withAppendedId(
            Uri.parse("content://downloads/public_downloads"),
            Long.valueOf(numericPart)
            )
           else
            -- Return raw path if it's not numeric
            return id
          end
         else
          -- Return raw path if no colon found
          return id
        end
      end

     elseif isMediaDocument(uri) then
      local docId = DocumentsContract.getDocumentId(uri)
      local split = String(docId).split(":")
      local contentUri
      -- 修复: 使用 if/elseif 替代 switch 语句
      if split[1] == "image" then
        contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
       elseif split[1] == "video" then
        contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
       elseif split[1] == "audio" then
        contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
      end
      selection = "_id=?"
      selectionArgs = {split[2]} -- 修复: 索引从1开始
      uri = contentUri
    end
  end

  -- Handle content and file schemes
  if String("content").equalsIgnoreCase(uri.scheme) then
    local projection = {"_data"}
    local cursor
    local result
    pcall(function()
      cursor = activity.contentResolver.query(uri, projection, selection, selectionArgs, nil)
      if cursor and cursor.moveToFirst() then
        local column_index = cursor.getColumnIndexOrThrow("_data")
        result = cursor.getString(column_index)
      end
      if cursor then cursor.close() end
    end)
    return result

   elseif String("file").equalsIgnoreCase(uri.scheme) then
    return uri.path
  end
end

function _M.modifyItemOffsets(outRect, view, parent, adapter, int)
  -- 获取当前item的位置
  local position = parent.getChildAdapterPosition(view)
  -- 设置每个方向的间距
  local spacing = dp2px(int) -- 定义总间距
  local halfSpacing = spacing / 2 -- 计算间距的一半，用于更灵活的间距设置
  -- 排他算法: 先统一在修改
  outRect.top = halfSpacing
  outRect.bottom = halfSpacing
  -- 根据列的索引设置间距
  if position == 0 then -- 如果视图在第一个
    outRect.top = spacing
   elseif position == (adapter.getItemCount() -1) then -- 如果视图在最后一个
    outRect.bottom = spacing
  end
end

function _M.modifyItemOffsets2(outRect, view, parent, adapter, int)
  -- 获取当前item的位置
  local position = parent.getChildAdapterPosition(view)

  -- 定义总间距
  local spacing = dp2px(int)

  -- 只对最后一项设置 bottom
  if position == (adapter.getItemCount() - 1) then
    outRect.bottom = spacing
   else
    outRect.bottom = 0
  end
end

function _M.setColorAlpha(color, alpha)
  --[[
    给颜色值设置 Alpha 通道
    参数: 
    color : 原始颜色值（支持格式: 0xRRGGBB 或 0xAARRGGBB）
    alpha : 透明度（支持格式: 0-255 整数 或 0.0-1.0 浮点数）
    
    返回: 
    新的 ARGB 颜色值（0xAARRGGBB 格式）
    --]]

  -- 处理 alpha 值输入
  if alpha < 1 then -- 当输入是 0.0-1.0 的浮点数时
    alpha = math.floor(alpha * 255 + 0.5) -- 四舍五入转换为 0-255
  end

  -- 确保 alpha 在有效范围
  alpha = math.min(255, math.max(0, alpha))

  -- 清除原颜色的 Alpha 通道 (保留 RGB 部分)
  local rgb = color & 0x00FFFFFF -- 保留 RGB 通道，清除 Alpha 通道

  -- 组合新的 Alpha 通道
  local new_alpha = alpha << 24 -- 将 alpha 左移 24 位，移到最高位
  return new_alpha | rgb -- 合并新的 Alpha 通道和原 RGB 通道
end

function _M.setTabRippleEffect(tabLayout)
  -- 导入 Java 类
  local RippleDrawable = bindClass "android.graphics.drawable.RippleDrawable"
  local ColorStateList = bindClass "android.content.res.ColorStateList"
  local TypedValue = bindClass "android.util.TypedValue"
  -- 创建颜色状态列表
  local colorStateList = ColorStateList.valueOf(_M.setColorAlpha(Colors.colorPrimary, 80))
  -- 遍历所有 Tab
  for i = 0 , tabLayout.getTabCount() - 1 do
    local tab = tabLayout.getTabAt(i)
    if tab then
      -- 获取 Tab 视图
      local tabView = tab.view
      -- 创建波纹效果
      local ripple = RippleDrawable (
      colorStateList, -- 波纹颜色
      nil, -- 内容层（设为 nil 表示无内容）
      nil -- 遮罩层（设为 nil 表示整个视图范围）
      )
      -- 应用新背景
      tabView.setBackground(ripple)
      -- 确保视图可交互
      tabView.setClickable (true)
      tabView.setFocusable(true)
    end
  end
end

-- 背景模糊函数
function _M.applyBackgroundBlur(view)
  -- 获取Android版本
  local Build = luajava.bindClass("android.os.Build")
  local sdk = Build.VERSION.SDK_INT

  if sdk >= 31 then
    -- Android 12+ 使用原生模糊
    local RenderEffect = luajava.bindClass("android.graphics.RenderEffect")
    local Shader = luajava.bindClass("android.graphics.Shader$TileMode")

    -- 创建模糊效果
    local blurEffect = RenderEffect.createBlurEffect(
    8,
    8,
    Shader.REPEAT
    )

    -- 应用效果到视图
    view.setRenderEffect(blurEffect)
  end
end

return _M