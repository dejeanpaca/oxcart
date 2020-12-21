{
   android_window
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT android_window;

INTERFACE

   USES
      ctypes, jni, native_activity,
      native_window, uAndroid;

TYPE

   { androidTWindow }

   androidTWindow = record
      activityClass,
      windowClass,
      windowManagerClass,
      viewClass: jclass;

      getWindow,
      getDecorView,
      setSystemUiVisibilityID: jmethodID;

      {get window from given activity}
      function Get(from: PANativeActivity): jclass;
      {set UI visibility flags}
      procedure SetSystemUiVisibility(on: PANativeActivity; flags: jint);

      {initialize jni stuff we need}
      procedure Initialize();
   end;

VAR
   androidWindow: androidTWindow;

IMPLEMENTATION

{ androidTWindow }

function androidTWindow.Get(from: PANativeActivity): jclass;
begin
   Result := mainThreadEnv^^.CallObjectMethod(mainThreadEnv, from^.clazz, getWindow);
end;

procedure androidTWindow.SetSystemUiVisibility(on: PANativeActivity; flags: jint);
var
   env: PJNIEnv;
   wnd: jclass;
   decorView: jmethodID;

begin
   env := mainThreadEnv;

   wnd := Get(on);
   decorView := env^^.CallObjectMethod(env, wnd, getDecorView);

   env^^.CallVoidMethodA(env, decorView, setSystemUiVisibilityID, @flags);
end;

procedure androidTWindow.Initialize();
var
   env: PJNIEnv;

begin
   env := mainThreadEnv;

   viewClass := env^^.FindClass(env, 'android/view/View');
   windowManagerClass := env^^.FindClass(env, 'android/view/WindowManager');
   activityClass := env^^.FindClass(env, 'android/app/NativeActivity');
   windowClass := env^^.FindClass(env, 'android/view/Window');

   getWindow := mainThreadEnv^^.GetMethodID(mainThreadEnv, activityClass, 'getWindow', '()Landroid/view/Window;');
   getDecorView := env^^.GetMethodID(env, windowClass, 'getDecorView', '()Landroid/view/View;');
   setSystemUiVisibilityID := env^^.GetMethodID(env, viewClass, 'setSystemUiVisibility', '(I)V');
end;

END.
