{
   android_layout_params
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT android_layout_params;

INTERFACE

   USES
      ctypes, jni,
      native_window, uAndroid;

CONST
   LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT = 0;
   LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES = 1;
   LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER = 2;
   LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS = 3;

TYPE

   { androidTLayoutParams }

   androidTLayoutParams = record
      cl: jclass;
      layoutInDisplayCutoutMode: jfieldID;

      procedure SetLayoutInDisplayCutoutMode(window: jclass; layout: jint);
   end;

VAR
   layout_params: androidTLayoutParams;

IMPLEMENTATION

{ androidTLayoutParams }

procedure androidTLayoutParams.SetLayoutInDisplayCutoutMode(window: jclass; layout: jint);
var
   env: PJNIEnv;

begin
   env := mainThreadEnv;

   if(cl = nil) then begin
      cl := env^^.FindClass(env, 'android/view/WindowManager$LayoutParams');

      if(android_api_level >= 28) then
         layoutInDisplayCutoutMode := env^^.GetFieldID(env, cl, 'layoutInDisplayCutoutMode', 'I');
   end;

   env^^.SetIntField(env, window, layoutInDisplayCutoutMode, layout);
end;

END.
