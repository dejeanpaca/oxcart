{
   uAndroid
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uAndroid;

INTERFACE

   USES
      ctypes;

VAR
   android_api_level: longint;

function android_get_application_target_sdk_version(): cint; cdecl; external;
function android_get_device_api_level(): cint; cdecl; external;

IMPLEMENTATION

INITIALIZATION
   android_api_level :=  android_get_device_api_level();

END.
