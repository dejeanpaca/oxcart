{
   android_native_activity_helper
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT android_native_activity_helper;

INTERFACE

   USES
      ctypes, jni, android_native_app_glue, android_env,
      uAndroid;

procedure androidAutoHideNavBar(var app: android_app);

IMPLEMENTATION

VAR
   activityClass,
   windowClass,
   viewClass,
   layoutParamsClass,
   windowManagerClass,
   window,
   decorView: jclass;

   getWindow,
   getDecorView,
   setSystemUiVisibility: jmethodID;

   flagFullscreenID,
   flagHideNavigationID,
   flagImmersiveStickyID,
   flagLayoutStableID,
   flagLayoutHideNavigationID,
   flagLayoutFullscreenID,
   layoutInDisplayCutoutMode: jfieldID;

   flagFullscreen,
   flagHideNavigation,
   flagImmersiveSticky,
   flagLayoutStable,
   flagLayoutHideNavigation,
   flagLayoutFullscreen: cint;

procedure androidAutoHideNavBar(var app: android_app);
var
   env: PJNIEnv;
   flag: cint;

begin
   env := mainThreadEnv;

   if(activityClass = nil) then begin
      activityClass := env^^.FindClass(env, 'android/app/NativeActivity');
      getWindow := env^^.GetMethodID(env, activityClass, 'getWindow', '()Landroid/view/Window;');

      windowClass := env^^.FindClass(env, 'android/view/Window');
      getDecorView := env^^.GetMethodID(env, windowClass, 'getDecorView', '()Landroid/view/View;');

      viewClass := env^^.FindClass(env, 'android/view/View');
      windowManagerClass := env^^.FindClass(env, 'android/view/WindowManager');
      setSystemUiVisibility := env^^.GetMethodID(env, viewClass, 'setSystemUiVisibility', '(I)V');

      layoutParamsClass := env^^.FindClass(env, 'android/view/WindowManager$LayoutParams');

      if(android_api_level >= 28) then begin
         layoutInDisplayCutoutMode := env^^.GetFieldID(env, layoutParamsClass, 'layoutInDisplayCutoutMode', 'I');
      end;

      flagFullscreenID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_FULLSCREEN', 'I');
      flagHideNavigationID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_HIDE_NAVIGATION', 'I');
      flagImmersiveStickyID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_IMMERSIVE_STICKY', 'I');
      flagLayoutStableID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_LAYOUT_STABLE', 'I');
      flagLayoutHideNavigationID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION', 'I');
      flagLayoutFullscreenID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN', 'I');

      flagFullscreen := env^^.GetStaticIntField(env, viewClass, flagFullscreenID);
      flagHideNavigation := env^^.GetStaticIntField(env, viewClass, flagHideNavigationID);
      flagImmersiveSticky := env^^.GetStaticIntField(env, viewClass, flagImmersiveStickyID);
      flagLayoutStable := env^^.GetStaticIntField(env, viewClass, flagLayoutStableID);
      flagLayoutHideNavigation := env^^.GetStaticIntField(env, viewClass, flagLayoutHideNavigationID);
      flagLayoutFullscreen := env^^.GetStaticIntField(env, viewClass, flagLayoutFullscreenID);
   end;

   flag := flagImmersiveSticky or
      flagLayoutStable or flagLayoutHideNavigation or flagLayoutFullscreen or
      flagHideNavigation or flagFullscreen;

   window := env^^.CallObjectMethod(env, app.activity^.clazz, getWindow);
   decorView := env^^.CallObjectMethod(env, window, getDecorView);

   env^^.CallVoidMethodA(env, decorView, setSystemUiVisibility, @flag);
end;

END.
