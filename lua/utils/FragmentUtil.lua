-- Author: 含清蓝日（优化版）
local bindClass = luajava.bindClass

-- 提前缓存 Java 类，避免重复查找
local FragmentContainerView = bindClass "androidx.fragment.app.FragmentContainerView"
local LuaFragment = bindClass "com.difierline.lua.LuaFragment"
local ViewGroup = bindClass "android.view.ViewGroup"

local mContainer, mId
local currentIndex = 1
local Fragments = {} -- LuaFragment 实例
local Views = {} -- 对应 View
local addedSet = {} -- 标记哪些 Fragment 已 add 到容器，避免重复

local fragmentManager = activity.getSupportFragmentManager()

-- 初始化时就拿到动画 id，后面直接用
local IN_ANIM, OUT_ANIM = (function()
  local cfg = activity.getSharedData("fragment_animation")
  local map = {
    [1] = { MDC_R.anim.m3_bottom_sheet_slide_in,
      MDC_R.anim.m3_bottom_sheet_slide_out },
    [2] = { MDC_R.anim.m3_motion_fade_enter,
      MDC_R.anim.m3_motion_fade_exit },
  }
  local pair = map[cfg] or map[2]
  return pair[1], pair[2]
end)()

local _M = {}

-- 添加 Fragment
function _M.addFragment(layout)
  local t = type(layout)
  if t == "table" then
    layout = loadlayout(layout)
   elseif not luajava.instanceof(layout, ViewGroup) then
    error("ViewGroup expected, got " .. t)
  end
  local view = layout
  local fragment = LuaFragment().setLayout(view)
  table.insert(Views, view)
  Fragments[#Fragments + 1] = fragment -- 利用返回值拿到索引
  return _M
end

-- 预加载并显示第一个 Fragment，其余延迟 attach
function _M.commitFragment()
  local ft = fragmentManager.beginTransaction()
  for i, f in ipairs(Fragments) do
    ft.add(mId, f)
    if i ~= 1 then
      ft.hide(f)
    end
    addedSet[i] = true
  end
  ft.commitNowAllowingStateLoss() -- 立即执行，防止状态异常
  return _M
end

-- 展示指定索引（0-based）
function _M.showFragment(index)
  index = index + 1
  if index == currentIndex or index < 1 or index > #Fragments then
    return true
  end

  -- 懒加载：如果还没 add，先补上
  if not addedSet[index] then
    local ft = fragmentManager.beginTransaction()
    ft.add(mId, Fragments[index]).hide(Fragments[index]).commitNow()
    addedSet[index] = true
  end

  fragmentManager.beginTransaction()
  .setCustomAnimations(IN_ANIM, OUT_ANIM)
  .show(Fragments[index])
  .hide(Fragments[currentIndex])
  .commit()

  currentIndex = index
  return _M
end

-- 隐藏当前
function _M.hideFragment()
  fragmentManager.beginTransaction()
  .hide(Fragments[currentIndex])
  .commit()
  return _M
end

-- 当前索引（0-based）
function _M.getCurrentItem()
  return currentIndex
end

-- 对外构造器
return setmetatable({}, {
  __call = function(_, container)
    local t = type(container)
    if t ~= "userdata"
      or not luajava.instanceof(container, FragmentContainerView) then
      error("FragmentContainerView expected, got " .. tostring(container))
    end
    mContainer = container
    mId = container.getId()
    return _M
  end,
})