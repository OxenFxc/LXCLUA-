require "utils.InitAppUtil"
local Init = require "activities.editor.EditorActivity$init".setSymbol()
local ActivityUtil = require "utils.ActivityUtil"
local PathUtil = require "utils.PathUtil"
local welcomeAgain = activity.getSharedData("welcome")

if not welcomeAgain then
  ActivityUtil.new("welcome")
 else
  ActivityUtil.new("main")
  --ActivityUtil.new("layouthelper", { "/storage/emulated/0/XCLUA/project/My Application2/layout.aly" })
end

activity.finish()