{
   android_native_activity_helper
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uAndroidApp;

INTERFACE

   USES
     uStd,
     android_native_app_glue;

VAR
   AndroidApp: Pandroid_app;

function androidGetInternalStorage(): StdString;

IMPLEMENTATION

function androidGetInternalStorage(): StdString;
begin
   Result := AndroidApp^.activity^.internalDataPath;
end;

function androidGetExternalStorage(): StdString;
begin
   Result := AndroidApp^.activity^.externalDataPath;
end;

END.
