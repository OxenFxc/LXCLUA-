local _M = {}
local bindClass = luajava.bindClass
local packageInfo = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0)
local Intent = bindClass "android.content.Intent"
local Uri = bindClass "android.net.Uri"
local OkHttpUtil = require "utils.OkHttpUtil"
local MyBottomSheetDialog = require "dialogs.MyBottomSheetDialog"
local PathUtil = require "utils.PathUtil"

local versionName = packageInfo.versionName
local versionCode = packageInfo.versionCode

function _M.check()
  if activity.getSharedData("offline_mode") or activity.getSharedData("ignore_this_time") == versionName or not activity.getSharedData("check_for_updated") then
    return
  end

  OkHttpUtil.post(false, "https://luaappx.top/update.php",
  nil, nil, function (code, body)
    local success, v = pcall(OkHttpUtil.decode, body)
    if success and v then
      local filename = v.filename
      local appver = v.appver
      local content = v.content
      local link = v.link
      
      
      if not v["switch"] then
        return
      end

      if appver > versionName then

        local dialog = MyBottomSheetDialog(activity)
        .setView("layouts.update_layout")
        .show()

        function ignore_this_time.onClick()
          activity.setSharedData("ignore_this_time", packageInfo.versionName)
          dialog.dismiss()
        end

        function no.onClick()
          dialog.dismiss()
        end

        function update.onClick()
          local viewIntent = Intent("android.intent.action.VIEW", Uri.parse(link))
          activity.startActivity(viewIntent)
        end

        title_filename.setText(filename .. "_" .. appver)
        update_content.setText(content)

      end
    end
  end)
end

return _M