local _M = {}
local bindClass = luajava.bindClass
local MaterialBlurDialogBuilder = require "dialogs.MaterialBlurDialogBuilder"
local MarkdownView = import "fun.ocss.tools.MarkdownView"
local FileUtil = require "utils.FileUtil"

function _M.show(path)
  MaterialBlurDialogBuilder(activity)
  .setView(loadlayout({
    MarkdownView,
    id = "webView",
    layout_width = -1,
    layout_height = -1,
  }))
  .show()
  webView.loadFromText(FileUtil.read(path))
end

return _M