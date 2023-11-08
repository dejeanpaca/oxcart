{$IFDEF WINDOWS}
COMPILER_LOCATION          = 'C:\programming\fpc\android\bin\i386-win32\ppcrossarm.exe';
COMPILER_PARAMETERS        = '';
COMPILER_CONFIG_LOCATION    = 'c:\programming\fpc\android\bin\i386-win32\fpc-win.cfg';
DEFAULT_OUTPUT_DIRECTORY   = 'lib\arm-android';
{$ENDIF}

{$IFDEF LINUX}
COMPILER_LOCATION             = '~/programming/fpc/android/bin/i386-linux/ppcrossarm';
COMPILER_PARAMETERS           = '';
COMPILER_CONFIG_LOCATION      = '~/programming/fpc/android/bin/i386-linux/fpc-linux.cfg';
DEFAULT_OUTPUT_DIRECTORY      = 'lib/arm-android';
{$ENDIF}