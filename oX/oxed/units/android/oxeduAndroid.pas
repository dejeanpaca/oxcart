{
   oxeduAndroidSettings, oxed android settings
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduAndroid;

INTERFACE

   USES
      uStd;

TYPE
   oxedTAndroidCPUType = (
      ANDROID_CPU_ARM,
      ANDROID_CPU_ARM64,
      ANDROID_CPU_x86,
      ANDROID_CPU_x86_64
   );

CONST
   OXED_DEFAULT_ANDROID_PROJECT_PATH = 'android_project';

   oxedAndroidCPUTypes: array[0..3] of string = (
      'arm',
      'arm64',
      'x86',
      'x86_64'
   );

TYPE

   { oxedTAndroidHelpers }

   oxedTAndroidHelpers = record
      class function HostPlatformPath(): StdString; static;
   end;

IMPLEMENTATION

{ oxedTAndroidHelpers }

class function oxedTAndroidHelpers.HostPlatformPath(): StdString;
begin
   Result := '';

   {$IF DEFINED(WINDOWS)}
      {$IFDEF CPU64}
      Result := 'windows-x86_64';
      {$ELSE}
      Result := 'windows-x86';
      {$ENDIF}
   {$ELSEIF DEFINED(LINUX)}
      {$IFDEF CPU64}
      Result := 'linux-x86_&4';
      {$ELSE}
      Result := 'linux-x86';
      {$ENDIF}
   {$ENDIF}
end;

END.
