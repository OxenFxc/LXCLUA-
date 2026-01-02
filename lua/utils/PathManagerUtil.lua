local _M = {}
local PathUtil = require "utils.PathUtil"

function _M.update_this_file(path)
  PathUtil.this_file = path
end

function _M.update_this_dir(path)
  PathUtil.this_dir = path
end

return _M