{
   oxeduAndroidBuild
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduAndroidBuild;

INTERFACE

   USES
      sysutils, uStd, StringUtils, uFileUtils,
      {app}
      appuEvents, appuActionEvents,
      {build}
      uBuildInstalls, uBuild,
      {oxed}
      uOXED, oxeduBuild, oxeduBuildLog,
      oxeduAndroidPlatform, oxeduAndroidSettings;

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

function isAndroidBuild(): oxedTAndroidPlatformArchitecture;
begin
   if(oxedBuild.BuildArch.PlatformObject <> oxedAndroidPlatform) then
      exit(nil);

   Result := oxedTAndroidPlatformArchitecture(oxedBuild.BuildArch);
end;

procedure buildStartRun();
var
   arch: oxedTAndroidPlatformArchitecture;
   path: StdString;

begin
   arch := isAndroidBuild();

   if(arch = nil) then
      exit;

   { check for the ndk }

   path := oxedAndroidSettings.GetNDKPath();

   if(not FileUtils.DirectoryExists(path)) then begin
      oxedBuild.Fail('Cannot find ndk path at: ' + path);
      exit;
   end;

   { check for the android app }

   path := oxedAndroidSettings.GetAppPath();

   if(not FileUtils.DirectoryExists(path)) then begin
      oxedBuild.Fail('Cannot find android app path at: ' + path);
      exit;
   end;

   { set the toolchain path }

   path := IncludeTrailingPathDelimiterNonEmpty(oxedAndroidSettings.GetNDKPath()) +
      'toolchains' +  DirSep + arch.ToolChainPath + DirSep;

   if(not FileUtils.DirectoryExists(path)) then begin
       oxedBuild.Fail('Cannot find toolchain utilities at: ' + path);
       exit;
   end;

   build.FPCOptions.CompilerUtilitiesPath := path;

   { set the library path, if any }

   if(arch.LibPath <> '') then begin
      path := IncludeTrailingPathDelimiterNonEmpty(oxedAndroidSettings.GetNDKPath()) +
         'platforms' + DirSep + 'android-' + sf(oxedAndroidSettings.Project.TargetVersion) +
            DirSep + 'arch-' + arch.LibPath + DirSep;

      if(not FileUtils.DirectoryExists(path)) then begin
         oxedBuild.Fail('Cannot find libraries at: ' + path);
         exit;
      end;

      build.Libraries.Add(path);
   end;

   { add units }

   oxedBuild.Parameters.IncludeUses.Add('android_native_app_glue');
   oxedBuild.Parameters.IncludeUses.Add('oxuAndroidMain');

   oxedBuild.Parameters.ExportSymbols.Add('ANativeActivity_onCreate');
   oxedBuild.Parameters.ExportSymbols.Add('android_main');

   {disable external symbols as we can't use those on android}
   build.Debug.External := false;
end;

procedure buildFinish();
var
   arch: oxedTAndroidPlatformArchitecture;
   source,
   appPath,
   targetPath: StdString;

begin
   arch := isAndroidBuild();

   if(arch = nil) then
      exit;

   {copy built library to the target folder}
   source := oxedBuild.GetTargetExecutableFileName();
   appPath := oxedAndroidSettings.GetAppPath();

   targetPath := appPath + DirSep + 'libs' + DirSep + arch.LibTarget;

   if(ForceDirectories(targetPath)) then begin
      targetPath := targetPath + DirSep + 'libmain.so';

      if(FileUtils.Copy(source, targetPath) > 0) then
         oxedBuildLog.k('Copied library from "' + source + '" to "' + targetPath + '"')
      else
         oxedBuild.Fail('Failed to copy library from "' + source + '" to "' + targetPath + '"');
   end else
      oxedBuild.Fail('Cannot create libs directory at: ' + targetPath);
end;

procedure init();
begin
   oxedAndroidBuild.Initialize();
end;

INITIALIZATION
   oxedAndroidBuild.BUILD_TO_PROJECT_ACTION := appActionEvents.SetCallback(@buildToProject);
   oxedBuild.OnStartRun.Add(@buildStartRun);
   oxedBuild.OnFinish.Add(@buildFinish);
   oxed.Init.Add('platform.android.build', @init);

END.
