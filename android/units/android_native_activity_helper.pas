UNIT android_native_activity_helper;

{$packrecords c}{$modeswitch advancedrecords}

INTERFACE

   USES
      ctypes, jni, android_native_app_glue;

procedure androidAutoHideNavBar(app: Pandroid_app);

IMPLEMENTATION

procedure androidAutoHideNavBar(app: Pandroid_app);
var
   env: PJNIEnv;

   activityClass,
   windowClass,
   viewClass,
   window,
   decorView: jclass;

   getWindow,
   getDecorView,
   setSystemUiVisibility: jmethodID;

   flagFullscreenID,
   flagHideNavigationID,
   flagImmersiveStickyID: jfieldID;

   flagFullscreen,
   flagHideNavigation,
   flagImmersiveSticky,
   flag: cint;

begin
   app^.activity^.vm^^.AttachCurrentThread(app^.activity^.vm, @env, nil);

   activityClass := env^^.FindClass(env, 'android/app/NativeActivity');
   getWindow := env^^.GetMethodID(env, activityClass, 'getWindow', '()Landroid/view/Window;');

   windowClass := env^^.FindClass(env, 'android/view/Window');
   getDecorView := env^^.GetMethodID(env, windowClass, 'getDecorView', '()Landroid/view/View;');

   viewClass := env^^.FindClass(env, 'android/view/View');
   setSystemUiVisibility := env^^.GetMethodID(env, viewClass, 'setSystemUiVisibility', '(I)V');

   window := env^^.CallObjectMethod(env, app^.activity^.clazz, getWindow);
   decorView := env^^.CallObjectMethod(env, window, getDecorView);

   flagFullscreenID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_FULLSCREEN', 'I');
   flagHideNavigationID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_HIDE_NAVIGATION', 'I');
   flagImmersiveStickyID := env^^.GetStaticFieldID(env, viewClass, 'SYSTEM_UI_FLAG_IMMERSIVE_STICKY', 'I');

   flagFullscreen := env^^.GetStaticIntField(env, viewClass, flagFullscreenID);
   flagHideNavigation := env^^.GetStaticIntField(env, viewClass, flagHideNavigationID);
   flagImmersiveSticky := env^^.GetStaticIntField(env, viewClass, flagImmersiveStickyID);

   flag := flagFullscreen or flagHideNavigation or flagImmersiveSticky;

   env^^.CallVoidMethodA(env, decorView, setSystemUiVisibility, @flag);
   app^.activity^.vm^^.DetachCurrentThread(app^.activity^.vm);
end;

END.
