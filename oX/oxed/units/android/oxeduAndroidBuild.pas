{
   oxeduAndroidBuild
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidBuild;

INTERFACE

   USES
      uStd, StringUtils,
      {app}
      appuEvents, appuActionEvents,
      {build}
      uBuildInstalls, uBuild,
      {oxed}
      uOXED, oxeduBuild, oxeduAndroidPlatform, oxeduAndroidSettings;

TYPE

   { oxedTAndroidBuild }

   oxedTAndroidBuild = record
      BUILD_TO_PROJECT_ACTION: TEventID;

      procedure BuildToProject();
      procedure Initialize();
   end;

VAR
  oxedAndroidBuild: oxedTAndroidBuild;

IMPLEMENTATION

{ oxedTAndroidBuild }

procedure oxedTAndroidBuild.BuildToProject();
var
   cpuType: loopint;

begin
   cpuType := loopint(oxedAndroidSettings.GetCPUType());

   oxedBuild.BuildTarget := OXED_BUILD_LIB;
   oxedBuild.StartTask(OXED_BUILD_TASK_RECODE, oxedAndroidPlatform.Architectures.List[cpuType]);
end;

procedure oxedTAndroidBuild.Initialize();
begin
   if BuildInstalls.FindPlatform('arm-android') = nil then
      BuildInstalls.AddPlatformFromExecutable('arm', 'android', '', 'ppcrossarm');

   if BuildInstalls.FindPlatform('aarch64-android') = nil then
      BuildInstalls.AddPlatformFromExecutable('aarch64', 'android', '', 'ppcrossa64');

   if BuildInstalls.FindPlatform('i386-android') = nil then
      BuildInstalls.AddPlatformFromExecutable('i386', 'android', '', 'ppcross386');

   if BuildInstalls.FindPlatform('x86_64-android') = nil then
      BuildInstalls.AddPlatformFromExecutable('x86_64', 'android', '', 'ppcrossx64');
end;

procedure buildToProject();
begin
   oxedAndroidBuild.BuildToProject();
end;

procedure buildStartRun();
var
   arch: oxedTAndroidPlatformArchitecture;

begin
   if(oxedBuild.BuildArch.PlatformObject <> oxedAndroidPlatform) then
      exit;

   arch := oxedTAndroidPlatformArchitecture(oxedBuild.BuildArch);

   build.FPCOptions.CompilerUtilitiesPath := IncludeTrailingPathDelimiterNonEmpty(oxedAndroidSettings.GetNDKPath()) +
      'toolchains' +  DirSep + arch.ToolChainPath + DirSep;

   if(arch.LibPath <> '') then
      build.Libraries.Add(IncludeTrailingPathDelimiterNonEmpty(oxedAndroidSettings.GetNDKPath()) +
      'platforms' + DirSep + 'android-' + sf(oxedAndroidSettings.Project.TargetVersion) + DirSep + 'arch-' + arch.LibPath + DirSep);
end;

procedure init();
begin
   oxedAndroidBuild.Initialize();
end;

INITIALIZATION
   oxedAndroidBuild.BUILD_TO_PROJECT_ACTION := appActionEvents.SetCallback(@buildToProject);
   oxedBuild.OnStartRun.Add(@buildStartRun);
   oxed.Init.Add('platform.android.build', @init);

END.
