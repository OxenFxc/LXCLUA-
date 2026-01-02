local _M = {}

local activityPaths = {
  main = "activities/main/MainActivity",
  welcome = "activities/welcome/WelcomeActivity",
  newproject = "activities/newproject/NewProjectActivity",
  editor = "activities/editor/EditorActivity",
  build = "activities/build/BuildActivity",
  analysis = "activities/analysis/AnalysisActivity",
  settings = "activities/settings/SettingsActivity",
  plugins = "activities/plugins/PluginsActivity",
  login = "activities/login/LoginActivity",
  javaapi = "activities/javaapi/JavaApiActivity",
  parsing = "activities/parsing/ParsingActivity",
  ranking = "activities/ranking/RankingActivity",
  logs = "activities/logs/LogsActivity",
  about = "activities/about/AboutActivity",
  symbol = "activities/symbol/SymbolActivity",
  post = "activities/post/PostActivity",
  runcode = "activities/runcode/RunCodeActivity",
  people = "activities/people/PeopleActivity",
  details = "activities/details/DetailsActivity",
  mypost = "activities/mypost/MyPostActivity",
  attribute = "activities/attribute/AttributeActivity",
  privacy = "activities/privacy/PrivacyActivity",
  editconfig = "activities/editconfig/EditConfigActivity",
  layouthelper = "activities/layouthelper/LayoutHelperActivity",
  control = "activities/control/ControlActivity"
}

_M.new = function(name, data)
  local path = activityPaths[name]
  if path then
    local fullPath = activity.getLuaDir() .. "/" .. path
    if data then
      activity.newActivity(fullPath, data)
     else
      activity.newActivity(fullPath)
    end
  end
end

return _M