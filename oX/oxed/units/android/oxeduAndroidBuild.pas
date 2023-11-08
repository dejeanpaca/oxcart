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
      uOXED,
      oxeduBuild, oxeduBuildLog, oxeduBuildAssets, oxeduBuildAssetsYPK,
      oxeduAndroidPlatform, oxeduAndroidSettings, oxeduAndroid;

TYPE
   { oxedTAndroidBuild }

   oxedTAndroidBuild = record
      BUILD_TO_PROJECT_ACTION,
      BUILD_ASSETS_TO_PROJECT_ACTION: TEventID;

      procedure BuildToProject();
      procedure BuildAssetsToProject();
      procedure Initialize();
   end;

VAR
  oxedAndroidBuild: oxedTAndroidBuild;

IMPLEMENTATION

{ oxedTAndroidBuild }

procedure buildStart();
var
   cpuType: loopint;

begin
   cpuType := loopint(oxedAndroidSettings.GetCPUType());

   oxedBuild.BuildTarget := OXED_BUILD_LIB;
   oxedBuildAssets.Deployer := oxedYPKAssetsDeployer;

   oxedBuild.StartTask(OXED_BUILD_TASK_RECODE, oxedAndroidPlatform.Architectures.List[cpuType]);
end;

procedure oxedTAndroidBuild.BuildToProject();
begin
   oxedBuild.BuildAssets := false;

   buildStart();
end;

procedure oxedTAndroidBuild.BuildAssetsToProject();
begin
   oxedBuild.BuildAssets := true;
   oxedBuild.BuildBinary := false;

   buildStart();
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
      'toolchains/' + arch.ToolChainPathPrefix + '/prebuilt/' + oxedTAndroidHelpers.HostPlatformPath() + '/bin';

   ReplaceDirSeparators(path);

   if(not FileUtils.DirectoryExists(path)) then begin
       oxedBuild.Fail('Cannot find toolchain utilities at: ' + path);
       exit;
   end;

   build.FPCOptions.CompilerUtilitiesPath := path;

   { set the library path, if any }

   if(arch.LibSource <> '') then begin
      path := IncludeTrailingPathDelimiterNonEmpty(oxedAndroidSettings.GetNDKPath()) +
         'toolchains/llvm/prebuilt/' + oxedTAndroidHelpers.HostPlatformPath() + '/sysroot/usr/lib/' + arch.LibSource +
         '/' + sf(oxedAndroidSettings.Project.TargetVersion) + '/';

      ReplaceDirSeparators(path);

      if(not FileUtils.DirectoryExists(path)) then begin
         oxedBuild.Fail('Cannot find libraries at: ' + path);
         exit;
      end;

      build.Libraries.Add(path);
   end;

   { add units }

   if(not oxedAndroidSettings.Project.ExcludeDefaultMain) then
      oxedBuild.Parameters.IncludeUses.Add('android_native_app_glue')
   else
      oxedBuild.Parameters.PreIncludeUses.Add('android_native_app_glue');

   oxedBuild.Parameters.ExportSymbols.Add('ANativeActivity_onCreate');

   if(not oxedAndroidSettings.Project.ExcludeDefaultMain) then
      oxedBuild.Parameters.IncludeUses.Add('oxuAndroidMain');

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

   appPath := oxedAndroidSettings.GetAppPath();

   {copy built data file to the target folder (if any)}
   if(oxedBuild.BuildAssets) then begin
      source := oxedYPKAssetsDeployer.Builder.OutputFN;
      targetPath := appPath + '/src/main/assets/data.ypk';

      oxedBuild.MoveFile(source, targetPath, 'data file');
   end;

   if(not oxedBuild.BuildBinary) then
      exit;

   {copy built library to the target folder}
   source := oxedBuild.GetTargetExecutableFileName();
   targetPath := appPath + DirSep + 'libs' + DirSep + arch.LibTarget;

   if(ForceDirectories(targetPath)) then begin
      targetPath := targetPath + DirSep + 'libmain.so';

      oxedBuild.MoveFile(source, targetPath, 'data file');
   end else
      oxedBuild.Fail('Cannot create libs directory at: ' + targetPath);
end;

procedure buildToProject();
begin
   oxedAndroidBuild.BuildToProject();
end;

procedure buildAssetsToProject();
begin
   oxedAndroidBuild.BuildAssetsToProject();
end;

procedure init();
begin
   oxedAndroidBuild.Initialize();
end;

INITIALIZATION
   oxedAndroidBuild.BUILD_TO_PROJECT_ACTION := appActionEvents.SetCallback(@buildToProject);
   oxedAndroidBuild.BUILD_ASSETS_TO_PROJECT_ACTION := appActionEvents.SetCallback(@buildAssetsToProject);

   oxedBuild.OnStartRun.Add(@buildStartRun);
   oxedBuild.OnFinish.Add(@buildFinish);

   oxed.Init.Add('platform.android.build', @init);

END.
