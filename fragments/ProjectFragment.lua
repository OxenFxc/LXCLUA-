local _M = {}
local bindClass = luajava.bindClass
local PropertyValuesHolder = bindClass "android.animation.PropertyValuesHolder"
local ObjectAnimator = bindClass "android.animation.ObjectAnimator"
local LinearLayoutManager = bindClass "androidx.recyclerview.widget.LinearLayoutManager"
local File = bindClass "java.io.File"
local RecyclerView = bindClass "androidx.recyclerview.widget.RecyclerView"
local MaterialBlurDialogBuilder = require "dialogs.MaterialBlurDialogBuilder"
local ProgressMaterialAlertDialog = require "dialogs.ProgressMaterialAlertDialog"
local MyBottomSheetDialog = require "dialogs.MyBottomSheetDialog"
local LuaRecyclerAdapter = require "utils.LuaRecyclerAdapter"
local PathUtil = require "utils.PathUtil"
local FileUtil = require "utils.FileUtil"
local Utils = require "utils.Utils"
local ActivityUtil = require "utils.ActivityUtil"
local cjson = require "cjson"
local GlideUtil = require "utils.GlideUtil"
local fileTracker = require "activities.editor.FileTracker"
local SharedPrefUtil = require "utils.SharedPrefUtil"

-- 添加新依赖
local DefaultItemAnimator = bindClass "androidx.recyclerview.widget.DefaultItemAnimator"
local LayoutAnimationController = bindClass "android.view.animation.LayoutAnimationController"
local AlphaAnimation = bindClass "android.view.animation.AlphaAnimation"
local AnimationUtils = bindClass "android.view.animation.AnimationUtils"
local Android_R = bindClass "android.R" -- 添加Android_R绑定

local projectList = {} -- 当前显示的列表
local projectListFull = {} -- 完整的项目列表
local fadeInAnim = nil -- 渐入动画引用
-- 排序选项键常量
local SORT_OPTION_KEY = "current_sort_option"
local SORT_OPTIONS = {
  NAME_ASC = "name_asc",
  NAME_DESC = "name_desc",
  TIME_ASC = "time_asc",
  TIME_DESC = "time_desc"
}
local currentSortOption = SORT_OPTIONS.NAME_ASC -- 默认排序方式

-- 解析项目清单文件
local function parseManifest(manifestPath)
  if not FileUtil.isExist(manifestPath) then return end
  local success, content = pcall(FileUtil.read, manifestPath)
  if not success then return end
  local s, v = pcall(cjson.decode, content)
  local application = v.application or {}
  if not v then return end
  return {
    label = application.label or "Error",
    version = v.versionName or "Error",
    package = v.package or "Error",
    success = s
  }
end

-- 从 SharedPreferences 读取排序选项
local function sortProjects()
  -- 从 SharedPreferences 读取排序选项
  local sortOption = SharedPrefUtil.getString(SORT_OPTION_KEY) or SORT_OPTIONS.NAME_ASC

  if #projectListFull == 0 then
    return
  end

  table.sort(projectListFull, function(a, b)
    if sortOption == SORT_OPTIONS.NAME_ASC then
      return a.label:lower() < b.label:lower()
     elseif sortOption == SORT_OPTIONS.NAME_DESC then
      return a.label:lower() > b.label:lower()
     elseif sortOption == SORT_OPTIONS.TIME_ASC then
      local timeA = File(a.path).lastModified()
      local timeB = File(b.path).lastModified()
      return timeA < timeB
     elseif sortOption == SORT_OPTIONS.TIME_DESC then
      local timeA = File(a.path).lastModified()
      local timeB = File(b.path).lastModified()
      return timeA > timeB
    end
    return a.label:lower() < b.label:lower() -- 默认按名称升序
  end)

  -- 更新显示列表
  while #projectList > 0 do
    table.remove(projectList, 1)
  end

  for _, v in ipairs(projectListFull) do
    table.insert(projectList, v)
  end

  if recylerView and recylerView.adapter then
    recylerView.adapter.notifyDataSetChanged()
  end
end

local function init()
  -- 创建项目动画器
  local itemAnimator = DefaultItemAnimator()
  itemAnimator.setAddDuration(250)
  itemAnimator.setRemoveDuration(250)
  itemAnimator.setMoveDuration(250)
  itemAnimator.setChangeDuration(250)
  recylerView.setItemAnimator(itemAnimator)

  -- 设置列表整体动画
  local animation = AlphaAnimation(0, 1)
  animation.setDuration(250)
  local controller = LayoutAnimationController(animation)
  controller.setDelay(0.15)
  controller.setOrder(LayoutAnimationController.ORDER_NORMAL)
  recylerView.setLayoutAnimation(controller)

  -- 创建渐入动画
  fadeInAnim = ObjectAnimator.ofFloat(recylerView, "alpha", {0, 1})
  fadeInAnim.setDuration(250)

  local adapter_project = LuaRecyclerAdapter(projectList, "layouts.project_item", {
    onBindViewHolder = function(viewHolder, pos, views, currentData)

      views.title.setText(currentData.label)
      views.package.setText(currentData.package)
      views.version.setText(currentData.version)
      if not activity.getSharedData("show_item_icon") then
        views.icon.setText(utf8.sub(currentData.label, 1, 1))
        views.icon.setBackgroundColor((function() if not currentData.success then return Colors.colorError else return Colors.colorPrimary end end)())
        views.icon.Visibility = 0
        views.icon2.Visibility = 8
       else
        GlideUtil.set((function() if FileUtil.isFile(currentData.path .. "/icon.png") return currentData.path .. "/icon.png" else return activity.getLuaDir("ic_launcher_playstore.png") end end)(), views.icon2)
        views.icon.Visibility = 8
        views.icon2.Visibility = 0
      end
      -- 添加点击事件
      views.card.onClick = function(v)
        ActivityUtil.new("editor", { currentData.path, currentData.label})
      end
      activity.onLongClick(views.card, function()
        -- 长按动画效果
        local rotateAnim = ObjectAnimator.ofFloat(views.card, "rotation", {0, 5, -5, 0})
        rotateAnim.setDuration(400)
        rotateAnim.start()

        local dialog = MyBottomSheetDialog(activity)
        .setView("layouts.project_long_layout")
        .show()
        title.setText(currentData.label)
        longpackage.setText(currentData.package)
        icon.setText(utf8.sub(currentData.label, 1, 1))

        fadeInStagger({title, longpackage, icon, build, backup, share, delete})

        function build.onClick()
          dialog.dismiss()
          ActivityUtil.new("build", { currentData.path })
        end
        function backup.onClick()
          dialog.dismiss()
          local wait_dialog = ProgressMaterialAlertDialog(activity).show()
          activity.newTask(function(path, MyToast, res)
            local FileUtil = require "utils.FileUtil"
            local e = FileUtil.backup(path)
            MyToast((function() return e and res.string.backup_succeeded .. ": " .. e or res.string.backup_failed end)())
            end,function()
            wait_dialog.dismiss()
          end).execute({currentData.path, MyToast, res})
        end
        function share.onClick()
          dialog.dismiss()
          local wait_dialog = ProgressMaterialAlertDialog(activity).show()
          activity.newTask(function(path, MyToast, res)
            local FileUtil = require "utils.FileUtil"
            return FileUtil.backup(path)
            end,function(p)
            if p then activity.shareFile(p) end
            wait_dialog.dismiss()
          end).execute({currentData.path, MyToast, res})
        end
        function delete.onClick()
          dialog.dismiss()
          local dialog = MaterialBlurDialogBuilder(activity)
          .setTitle(res.string.tip)
          .setMessage((res.string.delete_or_not):format(currentData.label))
          .setPositiveButton(res.string.ok, function()
            local wait_dialog = ProgressMaterialAlertDialog(activity).show()
            activity.newTask(function(path, MyToast, res)
              local FileUtil = require "utils.FileUtil"
              local PathUtil = require "utils.PathUtil"
              local fileTracker = require "activities.editor.FileTracker"
              -- 获取项目名称
              local projectName = FileUtil.getName(path)
              -- 删除项目文件夹
              local deleteSuccess = FileUtil.remove(path)
              if deleteSuccess then
                -- 删除fileTracker中的项目数据
                local db = fileTracker.open(PathUtil.crash_path .. "/fileTracker.db")
                -- 直接删除项目键
                fileTracker.deleteProject(db, projectName)
                -- 关闭数据库连接
                db:close()
              end

              MyToast(deleteSuccess and res.string.deleted_successfully or res.string.delete_failed)
              return deleteSuccess
              end, function(success)
              if success then
                _M.update()
              end
              wait_dialog.dismiss()
            end).execute({currentData.path, MyToast, res})
          end)
          .setNegativeButton(res.string.no, nil)
          .show()
        end
      end)
    end
  })
  recylerView.setAdapter(adapter_project).setLayoutManager(LinearLayoutManager(activity))
  return _M
end

local getList = function()
  mSwipeRefreshLayout.setRefreshing(true)
  recylerView.alpha = 0.2

  activity.newTask(FileUtil.traversalProject, function(list)
    local rawList = luajava.astable(list)

    -- 清空完整列表
    while #projectListFull > 0 do
      table.remove(projectListFull, 1)
    end

    -- 填充完整列表
    for _, path in ipairs(rawList) do
      local manifestPath = path.. "/manifest.json"
      local projectInfo = parseManifest(manifestPath)
      if projectInfo then
        table.insert(projectListFull, {
          label = projectInfo.label,
          version = projectInfo.version,
          package = projectInfo.package,
          path = path,
          success = projectInfo.success
        })
      end
    end

    -- 在数据填充后调用排序
    sortProjects()

    if recylerView and recylerView.adapter then
      recylerView.adapter.notifyDataSetChanged()
    end
    mSwipeRefreshLayout.setRefreshing(false)

    if fadeInAnim then
      fadeInAnim.start()
    end
    recylerView.alpha = 1
  end).execute()
end

local function initSwipeRefresh()
  recylerView.addItemDecoration(RecyclerView.ItemDecoration {
    getItemOffsets = function(outRect, view, parent, state)
      if recylerView and recylerView.adapter then
        Utils.modifyItemOffsets(outRect, view, parent, recylerView.adapter, 12)
      end
    end
  })
  mSwipeRefreshLayout.setProgressViewOffset(true, -100, 250)
  mSwipeRefreshLayout.setColorSchemeColors({ Colors.colorPrimary })
  mSwipeRefreshLayout.setOnRefreshListener({
    onRefresh = function()
      _M.update()
    end
  })
end

function _M.search(newText)
  -- 添加搜索开始时的淡出效果
  local fadeOut = AlphaAnimation(1, 0.3)
  fadeOut.setDuration(150)
  recylerView.startAnimation(fadeOut)

  -- 清空当前显示的列表
  while #projectList > 0 do
    table.remove(projectList, 1)
  end

  if newText == "" or newText == nil then
    -- 显示完整列表
    for _, v in ipairs(projectListFull) do
      table.insert(projectList, v)
    end
   else
    local searchTextLower = string.lower(newText)
    -- 从完整列表过滤
    for _, project in ipairs(projectListFull) do
      if string.find(string.lower(project.label), searchTextLower) or
        string.find(string.lower(project.package), searchTextLower) then
        table.insert(projectList, project)
      end
    end
  end

  -- 添加搜索完成后的渐入动画
  fadeOut.setAnimationListener({
    onAnimationEnd = function()
      if recylerView and recylerView.adapter then
        recylerView.adapter.notifyDataSetChanged()
      end
      local fadeIn = AlphaAnimation(0.3, 1)
      fadeIn.setDuration(250)
      recylerView.startAnimation(fadeIn)
    end
  })
end

function _M.update()
  getList()
  return _M
end

-- 外部可访问的排序函数
function _M.sort(sortOption)
  -- 如果传入了排序选项，保存到 SharedPreferences
  if sortOption then
    SharedPrefUtil.set(SORT_OPTION_KEY, sortOption)
  end
  sortProjects()
  return _M
end

function _M.onCreate()
  init()
  initSwipeRefresh()
  -- 首次加载时添加延迟动画
  recylerView.alpha = 0
  local handler = luajava.bindClass("android.os.Handler")(luajava.bindClass("android.os.Looper").getMainLooper())
  handler.postDelayed(function()
    _M.update()
  end, 300) -- 延迟300ms开始加载
end

function _M.onDestroy()
  if mSwipeRefreshLayout then
    mSwipeRefreshLayout.setOnRefreshListener(nil)
  end

  -- 释放项目数据
  projectList = {}
  projectListFull = {}
  recylerView.adapter.release()
  recylerView.adapter = nil

  -- 释放动画资源
  if fadeInAnim then
    fadeInAnim.cancel()
    fadeInAnim = nil
  end

  return _M
end

return _M