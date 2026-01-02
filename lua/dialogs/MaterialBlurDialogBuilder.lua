local bindClass = luajava.bindClass
local MaterialAlertDialogBuilder = bindClass "com.google.android.material.dialog.MaterialAlertDialogBuilder"
local Build = bindClass "android.os.Build"

local function MaterialBlurDialogBuilder(context)
  local RenderEffect = bindClass "android.graphics.RenderEffect"
  local Shader = bindClass "android.graphics.Shader"
  local ValueAnimator = bindClass "android.animation.ValueAnimator"
  local DialogInterface = bindClass "android.content.DialogInterface"
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
          local blurEffect = RenderEffect.createBlurEffect(
          radius, radius, Shader.TileMode.CLAMP)
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

  local dialog = luajava.override(MaterialAlertDialogBuilder, {
    create = function(super)
      animator = getAnimator()
      animator.start()
      return super()
    end,
    show = function(super)
      animator = getAnimator()
      animator.start()
      return super()
    end
  })

  dialog.setOnDismissListener(DialogInterface.OnDismissListener{
    onDismiss = function(dialog)
      if animator and animator.isRunning() then
        animator.cancel()
      end
      if Build.VERSION.SDK_INT >= 31 then
        blurView.setRenderEffect(nil)
      end
    end
  })

  setmetatable(self, {
    __index = function(self, i)
      return dialog[i]
    end
  })
  return self
end

if Build.VERSION.SDK_INT >= 31 then
  return MaterialBlurDialogBuilder
 else
  return MaterialAlertDialogBuilder
end