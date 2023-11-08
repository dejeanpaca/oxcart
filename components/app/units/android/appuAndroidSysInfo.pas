{
   Gathers information on android systems
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuAndroidSysInfo;

INTERFACE

	USES
      uAndroid, StringUtils,
      {app}
      appuSysInfoBase, appuLinuxSysInfo, appuLinuxSysInfoBase;

procedure appAndroidSysInfoGetInformation();

IMPLEMENTATION

procedure appAndroidSysInfoGetInformation();
begin
   appSI.System.Name := 'Android';
   appSI.System.OS := 'android';

   appSI.System.Name := 'Android API ' + sf(android_api_level);

   appLinuxSysInfoGetKernelVersion();
   appLinuxSysInfoGetMemoryInfo();
   appLinuxSysInfoGetCPUInfo();
end;

INITIALIZATION
   appSI.GetInformation := @appAndroidSysInfoGetInformation;

END.
