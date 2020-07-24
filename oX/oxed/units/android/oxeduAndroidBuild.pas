{
   oxeduAndroidBuild
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidBuild;

INTERFACE

   USES
      {app}
      appuEvents, appuActionEvents,
      {build}
      uBuildInstalls,
      {oxed}
      uOXED, oxeduBuild, oxeduAndroidPlatform;

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
begin
   oxedBuild.BuildTarget := OXED_BUILD_LIB;
   oxedBuild.StartTask(OXED_BUILD_TASK_RECODE, oxedAndroidPlatform.Architectures.List[0]);
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

procedure init();
begin
   oxedAndroidBuild.Initialize();
end;

INITIALIZATION
   oxedAndroidBuild.BUILD_TO_PROJECT_ACTION := appActionEvents.SetCallback(@buildToProject);
   oxed.Init.Add('platform.android.build', @init);

END.
