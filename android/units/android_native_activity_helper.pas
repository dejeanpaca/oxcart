{
   android_native_activity_helper
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT android_native_activity_helper;

INTERFACE

   USES
      ctypes, jni, android_native_app_glue,
      uAndroid, android_view;

procedure androidAutoHideNavBar(var app: android_app);
function androidGetWindow(var app: android_app): jclass;

IMPLEMENTATION

VAR
   activityClass,
   windowClass,
   viewClass,
   windowManagerClass,
   decorView,
   window: jclass;

   getWindow,
   getDecorView,
   setSystemUiVisibility: jmethodID;

function androidGetWindow(var app: android_app): jclass;
begin
   if(getWindow = nil) then
      getWindow := mainThreadEnv^^.GetMethodID(mainThreadEnv, activityClass, 'getWindow', '()Landroid/view/Window;');

   Result := mainThreadEnv^^.CallObjectMethod(mainThreadEnv, app.activity^.clazz, getWindow);
end;

procedure androidAutoHideNavBar(var app: android_app);
var
   env: PJNIEnv;
   flag: cint;

begin
   env := mainThreadEnv;

   if(activityClass = nil) then begin
      activityClass := env^^.FindClass(env, 'android/app/NativeActivity');

      windowClass := env^^.FindClass(env, 'android/view/Window');
      getDecorView := env^^.GetMethodID(env, windowClass, 'getDecorView', '()Landroid/view/View;');

      viewClass := env^^.FindClass(env, 'android/view/View');
      windowManagerClass := env^^.FindClass(env, 'android/view/WindowManager');
      setSystemUiVisibility := env^^.GetMethodID(env, viewClass, 'setSystemUiVisibility', '(I)V');
   end;

   flag := SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
      SYSTEM_UI_FLAG_LAYOUT_STABLE or SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
      SYSTEM_UI_FLAG_HIDE_NAVIGATION or SYSTEM_UI_FLAG_FULLSCREEN;

   window := androidGetWindow(app);
   decorView := env^^.CallObjectMethod(env, window, getDecorView);

   env^^.CallVoidMethodA(env, decorView, setSystemUiVisibility, @flag);
end;

END.
