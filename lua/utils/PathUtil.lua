local _M = {}
local bindClass = luajava.bindClass
local Environment = bindClass "android.os.Environment"

_M.root_path = Environment.getExternalStorageDirectory().toString() .. "/XCLUA"
_M.project_path = _M.root_path .. "/project"
_M.backup_path = _M.root_path .. "/backup"
_M.bin_path = _M.root_path .. "/bin"
_M.plugins_path = _M.root_path .. "/plugins"
_M.font_path = _M.root_path .. "/font"
_M.templates_path = activity.getLuaDir("res/templates")
_M.crash_path = tostring(activity.getExternalCacheDir())
_M.media_path = tostring(luajava.astable(activity.getExternalMediaDirs())[1].getPath())
_M.cache_path = _M.media_path .. "/cache"
_M.media_backup_path =  _M.media_path .. "/backups"
_M.this_dir = ""
_M.this_file = ""
_M.this_project = ""

return _M