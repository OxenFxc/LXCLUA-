local _M = {}
local bindClass = luajava.bindClass
local LinearLayoutManager = bindClass "androidx.recyclerview.widget.LinearLayoutManager"
local PopupMenu = bindClass "androidx.appcompat.widget.PopupMenu"
local Intent = bindClass "android.content.Intent"
local SQLiteHelper = bindClass "com.difierline.lua.luaappx.utils.SQLiteHelper"(activity)
local AesUtil = bindClass "com.difierline.lua.luaappx.utils.AesUtil"
local OkHttpUtil = require "utils.OkHttpUtil"
local GlideUtil = require "utils.GlideUtil"
local ActivityUtil = require "utils.ActivityUtil"
local LuaRecyclerAdapter = require "utils.LuaRecyclerAdapter"
local MaterialBlurDialogBuilder = require "dialogs.MaterialBlurDialogBuilder"
local SharedPrefUtil = require "utils.SharedPrefUtil"
local Utils = require "utils.Utils"
local qq = require "qq"

local API_BASE_URL = "https://luaappx.top/users/"
local ACCOUNT_BASE_URL = "https://luaappx.top/account/"
-- 保留数据表作为适配器的数据源
local data = {}
local adapter_my

local STR_BOUND = res.string.bound
local STR_UNBOUND = res.string.unbound
local STR_CLICK_LOGIN = res.string.click_me_to_log_in

local function strToBool(str)
  return str and str ~= "" and str:lower() ~= "false"
end

local function initRecy()
  if not SharedPrefUtil.getBoolean("is_login") then return end

  if not adapter_my then
    -- 使用全局 data 表初始化适配器
    local adapter_my = LuaRecyclerAdapter(data, "layouts.my_item", {
      onBindViewHolder = function(viewHolder, pos, views, currentData)
        pcall(function()
          GlideUtil.set(activity.getLuaDir("res/drawable/" .. currentData.src .. ".png"), views.image)
        end)

        if currentData.text then
          if currentData.title == "qq" then
            views.content.setText(strToBool(currentData.text) and STR_BOUND or STR_UNBOUND)
           else
            views.content.setText(currentData.text)
          end
        end

        views.card.onClick = function()
          if currentData.title == "qq" and not strToBool(currentData.text) then
            qq.Login(102796665, function() end)
           elseif currentData.title == "book" then
            ActivityUtil.new("mypost")
           elseif currentData.title == "x_coins" then
            ActivityUtil.new("ranking")
          end
        end
      end
    })

    if recycler_view_my then
      recycler_view_my.setAdapter(adapter_my)
      recycler_view_my.setLayoutManager(LinearLayoutManager(activity))
    end
  end
end

function _M.getProfile()
  local function resetToLoginState()
    nick.setText(STR_CLICK_LOGIN)
    logo.setImageResource(R.drawable.avatar_placeholder)
    title.parent.setVisibility(8)
    check.parent.setVisibility(8)
    email.setVisibility(8)
    recycler_view_my.parent.setVisibility(8)

    local corner = dp2px(12)
    if login then
      login.setBackgroundDrawable(createCornerGradientDrawable(
      true, Colors.colorBackground, Colors.colorOutlineVariant, corner, corner))
    end

    -- 清空数据表
    for i = #data, 1, -1 do
      table.remove(data, i)
    end

    -- 通知适配器更新
    if recycler_view_my.adapter then
      recycler_view_my.adapter.notifyDataSetChanged()
    end
  end

  local function updateProfileUI(profileData)
    nick.setText(tostring(profileData.nickname))
    if profileData.is_banned then
      title.parent.setVisibility(0)
      .setCardBackgroundColor(Utils.setColorAlpha(Colors.colorError, 20))
      title.setText(res.string.ban)
      .setTextColor(Colors.colorError)
     else
     
      title.parent.setVisibility(0)
      title.setText(profileData.is_admin and res.string.administrator or tostring(profileData.title))
      
    end
    if email then
      email.setText((profileData.email))
      email.setVisibility(0)
    end
    if check then
      check.parent.setVisibility(profileData.is_checked and 8 or 0)
    end

    local avatar = tostring(profileData.avatar_url)
    GlideUtil.set((function()
      if avatar:find("http") ~= nil then
        return avatar
       else
        return "https://luaappx.top/public/uploads/avatars/default_avatar.png"
      end
    end)(), logo, true)

    SharedPrefUtil.set("is_admin", profileData.is_admin)
    SharedPrefUtil.set("user_id", profileData.user_id)

    if login then
      login.setBackgroundDrawable(createCornerGradientDrawable(
      true, Colors.colorBackground, Colors.colorOutlineVariant, dp2px(12), 0))
    end

    -- 清空旧数据
    for i = #data, 1, -1 do
      table.remove(data, i)
    end

    -- 添加新数据
    table.insert(data, {
      title = "account",
      src = "ic_account_outline",
      text = profileData.account .. "(" .. tointeger(profileData.user_id) .. ")"
    })

    table.insert(data, {
      title = "qq",
      src = "ic_qq",
      text = tostring(profileData.is_binding)
    })

    table.insert(data, {
      title = "book",
      src = "ic_book_outline",
      text = tostring(tointeger(profileData.stats.post_count))
    })

    table.insert(data, {
      title = "x_coins",
      src = "ic_alpha_b_circle_outline",
      text = tostring(tointeger(profileData.x_coins))
    })

    table.insert(data, {
      title = "member_since",
      src = "ic_alarm",
      text = profileData.member_since
    })

    -- 通知适配器更新
    if recycler_view_my.adapter then
      recycler_view_my.adapter.notifyDataSetChanged()
      if recycler_view_my.parent then
        recycler_view_my.parent.setVisibility(0)
      end
    end
  end

  local function stopRefreshing()
    if mSwipeRefreshLayout3 then
      mSwipeRefreshLayout3.setRefreshing(false)
    end
  end

  if not SharedPrefUtil.getBoolean("is_login") then
    resetToLoginState()
    stopRefreshing()
    return
  end

  OkHttpUtil.post(false, API_BASE_URL .. "get_profile.php", {
    username = getSQLite(1),
    time = os.time()
    }, {
    ["Authorization"] = "Bearer " .. getSQLite(3)
    }, function(code, body)

    local success, response = pcall(OkHttpUtil.decode, body)

    if not success or not response or not response.success then
      resetToLoginState()
      stopRefreshing()
      return
    end

    if response.data then
      updateProfileUI(response.data)
     else
      resetToLoginState()
    end

    stopRefreshing()
  end)
end

local function initSwipeRefresh()
  mSwipeRefreshLayout3.setProgressViewOffset(true, -100, 250)
  mSwipeRefreshLayout3.setColorSchemeColors({ Colors.colorPrimary })
  mSwipeRefreshLayout3.setOnRefreshListener({
    onRefresh = function()
      _M.getProfile()
    end
  })
end

function _M.onCreate()
  if activity.getSharedData("offline_mode") then
    return
  end

  initRecy()
  _M.getProfile()
  initSwipeRefresh()

  function check.onClick()
    OkHttpUtil.post(true, API_BASE_URL .. "check_in.php", {
      time = os.time()
      }, {
      ["Authorization"] = "Bearer " .. getSQLite(3)
      }, function (code, body)
      local success, v = pcall(OkHttpUtil.decode, body)
      if success and v then
        MyToast(v.message)
        _M.getProfile()
       else
        OkHttpUtil.error(body)
      end
    end)
  end

  function login.onClick(v)

    if SharedPrefUtil.getBoolean("is_login") then
      local pop = PopupMenu(activity, v)
      local menu = pop.Menu
      menu.add(res.string.change_avatar).onMenuItemClick = function()
        activity.startActivityForResult(
        Intent(Intent.ACTION_PICK).setType("image/*"),
        11
        )
      end

      menu.add(res.string.modify_nickname).onMenuItemClick = function()
        local dialogView = loadlayout("layouts.dialog_fileinput")
        MaterialBlurDialogBuilder(activity)
        .setTitle(res.string.modify_nickname)
        .setView(dialogView)
        .setPositiveButton(res.string.ok, function()
          local content = content
          OkHttpUtil.post(true, API_BASE_URL .. "set_username.php", {
            username = content.text,
            time = os.time()
            }, {
            ["Authorization"] = "Bearer " .. getSQLite(3)
            }, function (code, body)
            local success, v = pcall(OkHttpUtil.decode, body)
            if success and v then
              MyToast(v.message)
              _M.getProfile()
             else
              OkHttpUtil.error(body)
            end
          end)
        end)
        .setNegativeButton(res.string.no, nil)
        .show()
        content.setText(nick.text)
      end

      menu.add(res.string.modify_password).onMenuItemClick = function()
        local dialogView = loadlayout("layouts.dialog_fileinput")
        MaterialBlurDialogBuilder(activity)
        .setTitle(res.string.modify_password)
        --.setMessage(res.string.qq_login_password_cannot_be_changed)
        .setView(loadlayout("layouts.dialog_fileinput2"))
        .setPositiveButton(res.string.ok, function()

          local username = getSQLite(1)
          OkHttpUtil.post(true, ACCOUNT_BASE_URL .. "change_password.php", {
            username = tostring(getSQLite(1)),
            current_password = tostring(getSQLite(2)),
            new_password = content.text,
            time = os.time()
            }, {
            ["Authorization"] = "Bearer " .. getSQLite(3)
            }, function (code, body)
            local success, v = pcall(OkHttpUtil.decode, body)
            if success and v then
              MyToast(v.message)
              if v.success then
                SQLiteHelper.setUser(
                AesUtil.encryptToBase64(username, username),
                AesUtil.encryptToBase64(username, content.text),
                AesUtil.encryptToBase64(username, getSQLite(3))
                )
              end
             else
              OkHttpUtil.error(body)
            end
          end)
        end)
        .setNegativeButton(res.string.no, nil)
        .show()
        title.setHint(res.string.old_password)
        .setHelperText(res.string.qq_login_password_cannot_be_changed)
        content.setHint(res.string.new_password)
        .setHelperText(res.string.qq_login_password_cannot_be_changed)
      end

      menu.add(res.string.exit_account_number).onMenuItemClick = function()
        SharedPrefUtil.remove("token")
        SharedPrefUtil.remove("username")
        SharedPrefUtil.remove("password")
        SharedPrefUtil.remove("user_id")
        SharedPrefUtil.remove("is_admin")
        SharedPrefUtil.remove("is_login")
        SQLiteHelper.setUser("","","")

        _M.getProfile()
        SourceFragment.refreshData()

        if login then
          login.setBackgroundDrawable(createCornerGradientDrawable(
          true, Colors.colorBackground, Colors.colorOutlineVariant, dp2px(12), dp2px(12)))
        end
      end
      pop.show()
     else
      ActivityUtil.new("login")
    end
  end
end

function _M.onDestroy()
  if mSwipeRefreshLayout3 then
    mSwipeRefreshLayout3.setOnRefreshListener(nil)
  end

  if OkHttpUtil.cancelAllRequests then
    OkHttpUtil.cancelAllRequests()
  end

  if OkHttpUtil.cleanupDialogs then
    OkHttpUtil.cleanupDialogs()
  end

  -- 释放适配器
  recycler_view_my.adapter.release()
  recycler_view_my.adapter = nil

  return _M
end

return _M