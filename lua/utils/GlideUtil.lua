local _M = {}
local bindClass = luajava.bindClass

-- 绑定 Java 类
local Glide = bindClass "com.bumptech.glide.Glide"
local DrawableTransitionOptions = bindClass "com.bumptech.glide.load.resource.drawable.DrawableTransitionOptions"
local DiskCacheStrategy = bindClass "com.bumptech.glide.load.engine.DiskCacheStrategy"
local RequestOptions = bindClass "com.bumptech.glide.request.RequestOptions"

-- Glide 加载图片（启用缓存）
local function loadWithGlide(path, view, errorDrawable)
  -- 创建基础请求选项
  local requestOptions = RequestOptions()
  .diskCacheStrategy(DiskCacheStrategy.AUTOMATIC) -- 使用自动磁盘缓存策略

  -- 如果有错误占位图资源，添加到请求选项
  if errorDrawable then
    requestOptions = requestOptions.error(errorDrawable)
  end

  -- 创建请求构建器
  local requestBuilder = Glide.with(activity)
  .load(path)
  .transition(DrawableTransitionOptions.withCrossFade()) -- 使用淡入淡出动画
  .apply(requestOptions) -- 应用请求选项

  -- 加载到视图
  requestBuilder.into(view)
end

-- 设置图片加载逻辑（支持可选错误占位图）
function _M.set(path, view, error)
  -- 只有当 error 参数存在时才使用错误占位图
  loadWithGlide(path, view, error and R.drawable.avatar_placeholder)
  return _M
end

-- 清理缓存
function _M.clear()
  -- 清理 Glide 缓存
  Glide.get(activity).clearMemory()
  thread(function(Glide, activity)
    Glide.get(activity).clearDiskCache()
  end, Glide, activity)
  return _M
end

return _M