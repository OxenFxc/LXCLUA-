local _M = {}
local bindClass = luajava.bindClass
local BottomSheetDialog = bindClass "com.google.android.material.bottomsheet.BottomSheetDialog"
local Build = bindClass "android.os.Build"
local UiUtil = require "utils.UiUtil"

local function MyBottomSheetDialog(context)
  local DialogInterface = bindClass "android.content.DialogInterface"
  local RenderEffect = bindClass "android.graphics.RenderEffect"
  local Shader = bindClass "android.graphics.Shader"
  local ValueAnimator = bindClass "android.animation.ValueAnimator"
  local self = {}
  local blurView = context.getWindow().getDecorView()
  local blurRadius = 0
  local animatorDuration = 200
  local animator

  local function getAnimator()
    local animator = ValueAnimator.ofFloat({0, blurRadius})
    animator.setDuration(animatorDuration)
    animator.addUpdateListener(ValueAnimator.AnimatorUpdateListener {
      onAnimationUpdate = function(animation)
        local radius = animation.getAnimatedValue()
        if radius > 0 then
          local blurEffect = RenderEffect.createBlurEffect(radius, radius, Shader.TileMode.CLAMP)
          blurView.setRenderEffect(blurEffect)
        end
      end
    })
    return animator
  end

  function self.setBlurRadius(radius)
    blurRadius = radius
  end

  function self.setAnimatorDuration(duration)
    animatorDuration = duration
  end

  function self.setBlurView(view)
    blurView = view
  end

  local dialog = luajava.override(BottomSheetDialog, {
    show = function(super)
      if Build.VERSION.SDK_INT >= 31 then
        animator = getAnimator()
        animator.start()
      end
      return super()
    end
  })

  function self.setView(layout)
    dialog.setContentView(loadlayout(layout))
    dialog.window.decorView.systemUiVisibility = 2
    local bottomSheet = dialog.window.findViewById(bindClass("com.google.android.material.R$id").design_bottom_sheet)
    UiUtil.applyEdgeToEdgePreference(dialog.getWindow())
    return self
  end

  dialog.setOnDismissListener(DialogInterface.OnDismissListener{
    onDismiss = function()
      if animator and animator.isRunning() then
        animator.cancel()
      end
      if Build.VERSION.SDK_INT >= 31 then
        blurView.setRenderEffect(nil)
      end
    end
  })

  setmetatable(self, {
    __index = function(_, key)
      return dialog[key] or BottomSheetDialog[key]
    end
  })
  return self
end

if Build.VERSION.SDK_INT >= 31 then
  return MyBottomSheetDialog
 else
  return function(context)
    local dialog = BottomSheetDialog(context)
    return {
      setView = function(layout)
        dialog.setContentView(loadlayout(layout))
        dialog.window.decorView.systemUiVisibility = 2
        local bottomSheet = dialog.window.findViewById(bindClass("com.google.android.material.R$id").design_bottom_sheet)
        UiUtil.applyEdgeToEdgePreference(dialog.getWindow())
        return dialog
      end
    }
  end
end