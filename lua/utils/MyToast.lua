local bindClass = luajava.bindClass
local Gravity = bindClass "android.view.Gravity"
local Snackbar = bindClass "com.google.android.material.snackbar.Snackbar"

-- 创建一个显示自定义Snackbar的函数
return function(...)
  -- 将传入的参数拼接成字符串
  local function concatenateArgs(...)
    local buf = {}
    for n = 1, select("#", ...) do
      table.insert(buf, tostring(select(n, ...)))
    end
    return table.concat(buf, "\t\t")
  end

  -- 配置Snackbar的视图和布局参数
  local function configureSnackbarView(snackbarView)
    -- 加载自定义布局
    snackbarView.addView(loadlayout("layouts.toast_layout"))
    snackbarView.setBackgroundColor(0)

    -- 设置布局参数
    local params = snackbarView.getLayoutParams()
    params.width = -2 -- MATCH_PARENT
    params.setMargins(0, 180, 0, 210)
    params.gravity = Gravity.CENTER | Gravity.BOTTOM
    snackbarView.setLayoutParams(params)
  end

  -- 拼接传入的参数为字符串
  local message = concatenateArgs(...)
  -- 获取锚点视图
  local anchor = activity.findViewById(android.R.id.content)
  -- 创建Snackbar
  local mSnackbar = Snackbar.make(anchor, "", Snackbar.LENGTH_LONG)
  -- 获取并配置Snackbar的视图
  local snackbarView = mSnackbar.getView()
  configureSnackbarView(snackbarView)
  toast_text.setText(message)

  -- 显示Snackbar
  return mSnackbar.show()
end