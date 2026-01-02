local _M = {}
local bindClass = luajava.bindClass
local ActivityCompat = bindClass "androidx.core.app.ActivityCompat"
local String = bindClass "java.lang.String"
local PackageManager = bindClass "android.content.pm.PackageManager"
local File = bindClass "java.io.File"

local grantedList = {}
_M.grantedList = grantedList


local request = function(permissions)
  ActivityCompat.requestPermissions(activity, String(permissions), 0)
end
_M.request = request


local checkPermission = function(permission)
  if permission == "android.permission.REQUEST_INSTALL_PACKAGES" then
    return activity.getPackageManager().canRequestPackageInstalls()
   else
    return ActivityCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
  end
end
_M.checkPermission = checkPermission


local check = function(permissions)
  for index,permission in ipairs(permissions)
    local granted = checkPermission(permission)
    if not(granted)
      return false
    end
  end
  return true
end
_M.check = check

function _M.isAllGranted(grantResults)
  for _, result in ipairs(grantResults) do
    if result ~= PackageManager.PERMISSION_GRANTED then
      return false
    end
  end
  return true
end

return _M