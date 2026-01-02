local _M = {}
local bindClass = luajava.bindClass
local PropertyValuesHolder = bindClass "android.animation.PropertyValuesHolder"
local ObjectAnimator = bindClass "android.animation.ObjectAnimator"
local LinearLayoutManager = bindClass "androidx.recyclerview.widget.LinearLayoutManager"
local RecyclerView = bindClass "androidx.recyclerview.widget.RecyclerView"

function _M.onCreate()
  
end

return _M