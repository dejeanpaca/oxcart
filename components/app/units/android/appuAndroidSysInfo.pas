{
   Gathers information on android systems
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuAndroidSysInfo;

INTERFACE

	USES
      appuSysInfoBase, appuLinuxSysInfo, appuLinuxSysInfoBase;

procedure appAndroidSysInfoGetInformation();

IMPLEMENTATION

procedure appAndroidSysInfoGetInformation();
begin
   appSI.System.Name := 'Android';

   appLinuxSysInfoGetKernelVersion();
   appLinuxSysInfoGetMemoryInfo();
   appLinuxSysInfoGetCPUInfo();
end;

INITIALIZATION
   appSI.GetInformation := @appAndroidSysInfoGetInformation;

END.
