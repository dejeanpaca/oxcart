{
   android_window
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT android_window;

INTERFACE

   USES
      ctypes, jni, native_activity,
      native_window, uAndroid, android_layout_params;

TYPE

   { androidTWindow }

   androidTWindow = record
      activityClass,
      windowClass,
      windowManagerClass,
      viewClass: jclass;

      getWindow,
      getDecorView,
      setSystemUiVisibilityID,
      getAttributesID,
      setAttributesID: jmethodID;

      {get window from given activity}
      function Get(from: PANativeActivity): jclass;
      {set UI visibility flags}
      procedure SetSystemUiVisibility(activity: PANativeActivity; flags: jint);
      {set layout in display cutout mode}
      procedure SetLayoutInDisplayCutoutMode(activity: PANativeActivity; layout: jint);

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

procedure androidTWindow.SetSystemUiVisibility(activity: PANativeActivity; flags: jint);
var
   env: PJNIEnv;
   wnd: jclass;
   decorView: jobject;

begin
   env := mainThreadEnv;

   wnd := Get(activity);
   decorView := env^^.CallObjectMethod(env, wnd, getDecorView);

   env^^.CallVoidMethodA(env, decorView, setSystemUiVisibilityID, @flags);
end;

procedure androidTWindow.SetLayoutInDisplayCutoutMode(activity: PANativeActivity; layout: jint);
var
   wnd: jclass;
   attributes: jobject;
   args: array[0..0] of jvalue;

begin
   wnd := Get(activity);
   attributes := mainThreadEnv^^.CallObjectMethod(mainThreadEnv, wnd, getAttributesID);

   androidLayoutParams.SetLayoutInDisplayCutoutMode(attributes, LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES);

   args[0].l := attributes;
   mainThreadEnv^^.CallVoidMethodA(mainThreadEnv, wnd, setAttributesID, args);
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
   setSystemUiVisibilityID := env^^.GetMethodID(env, viewClass, 'setSystemUiVisibility', '(I)V');

   getDecorView := env^^.GetMethodID(env, windowClass, 'getDecorView', '()Landroid/view/View;');
   getAttributesID := env^^.GetMethodID(env, windowClass, 'getAttributes', '()Landroid/view/WindowManager$LayoutParams;');
   setAttributesID := env^^.GetMethodID(env, windowClass, 'setAttributes', '(Landroid/view/WindowManager$LayoutParams;)V');

   androidLayoutParams.Initialize();
end;

END.
