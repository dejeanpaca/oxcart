{
   android_native_activity_helper
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT android_native_activity_helper;

INTERFACE

   USES
      uStd, jni,
      native_activity, android_view, android_window;

procedure androidAutoHideNavBar(activity: PANativeActivity);

IMPLEMENTATION

procedure androidAutoHideNavBar(activity: PANativeActivity);
var
   flags: jint;

begin
   if(activity = nil) then
     exit;

   flags := SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
      SYSTEM_UI_FLAG_LAYOUT_STABLE or SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
      SYSTEM_UI_FLAG_HIDE_NAVIGATION or SYSTEM_UI_FLAG_FULLSCREEN;

   androidWindow.SetSystemUiVisibility(activity, flags);
end;

END.
