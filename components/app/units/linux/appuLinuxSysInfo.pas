{
   Gathers information on linux systems
   Copyright (C) 2012. Dejan Boras

	TODO: Need to also skip unsupported sections in cpuinfo, and expand support for the hardware section.
   TODO: Maybe not cram android stuff in here
}

{$INCLUDE oxheader.inc}
UNIT appuLinuxSysInfo;

INTERFACE

	USES
      uStd, StringUtils, uFileUtils,
      appuSysInfoBase, appuLinuxSysInfoBase;

procedure appLinuxSysInfoGetInformation();

IMPLEMENTATION

CONST
   nPlatforms = 4;

   platformFileNames: array[0..nPlatforms - 1] of string = (
      'debian-version',
      'fedora-release',
      'redhat-release',
      'slackware-version'
   );

   platformNames: array[0..nPlatforms - 1] of string = (
      'debian',
      'fedora',
      'redhat',
      'slackware'
   );

procedure appLinuxSysInfoGetInformation();
var
   release: StdString = '';
   ok: longint;
   i: longint;

begin
   appSI.System.Name := 'Linux';

   {get platform names}
   for i := 0 to (nPlatforms - 1) do begin
      ok := FileUtils.LoadStringPipe('/etc/' + platformFileNames[i], release);

      if(ok > 0) then begin
         StringUtils.StripEndLine(release);
         appSI.System.Name := release;
         appSI.System.OS := platformNames[i];
         break;
      end;
   end;

   appLinuxSysInfoGetKernelVersion();
   appLinuxSysInfoGetMemoryInfo();
   appLinuxSysInfoGetCPUInfo();
end;

INITIALIZATION
   appSI.GetInformation := @appLinuxSysInfoGetInformation;

END.
