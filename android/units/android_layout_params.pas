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
      layoutParamsClass: jclass;
      layoutInDisplayCutoutMode: jfieldID;

      procedure SetLayoutInDisplayCutoutMode(params: jobject; layout: jint);
      procedure Initialize();
   end;

VAR
   androidLayoutParams: androidTLayoutParams;

IMPLEMENTATION

{ androidTLayoutParams }

procedure androidTLayoutParams.SetLayoutInDisplayCutoutMode(params: jobject; layout: jint);
begin
   if(layoutInDisplayCutoutMode <> nil) then
      mainThreadEnv^^.SetIntField(mainThreadEnv, params, layoutInDisplayCutoutMode, layout);
end;

procedure androidTLayoutParams.Initialize();
begin
   layoutParamsClass := mainThreadEnv^^.FindClass(mainThreadEnv, 'android/view/WindowManager$LayoutParams');

   if(android_api_level >= 28) then
      layoutInDisplayCutoutMode := mainThreadEnv^^.GetFieldID(mainThreadEnv, layoutParamsClass, 'layoutInDisplayCutoutMode', 'I');
end;

END.
