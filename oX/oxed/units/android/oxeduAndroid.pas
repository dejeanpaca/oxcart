{
   oxeduAndroidSettings, oxed android settings
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduAndroid;

INTERFACE

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

IMPLEMENTATION

END.
