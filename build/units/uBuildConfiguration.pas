{
   uBuildConfiguration
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uBuildConfiguration;

INTERFACE

   USES
      sysutils, strutils,
      uStd, uLog, StringUtils, udvars,
      dvaruFile, uFileUtils, uFileTraverse,
      uBuild, uBuildInstalls, appuPaths;

TYPE
   { TBuildConfiguration }

   TBuildConfiguration = record
      public
      {dvar configuration root}
      dvgLocation: TDVarGroup;
      {units configuration root}
      dvgUnits,
      {configuration root}
      dvgConfig,
      {units base path group}
      dvgUnitsBase: TDVarGroup;

      {should we load default units}
      DoLoadUnits: boolean;

      {load configuration}
      procedure LoadConfiguration();
      {save location configuration}
      procedure SaveLocationConfiguration();
      {load configured units}
      procedure LoadUnits();

      {load the specified config file}
      procedure LoadConfigFile(const fn: StdString);

      {automatically determine config path}
      procedure AutoDetermineConfigPath();
   end;

VAR
   BuildConfiguration: TBuildConfiguration;

IMPLEMENTATION

VAR
   { store config_path configuration file}
   dvConfigLocation: TDVar;

   dvUnitsUnit,
   dvUnitsInclude: TDVar;

   currentMode: StdString = 'fpc';
   currentConfigFilePath,
   currentValue: StdString;

   dvFPC,
   dvLazarus,
   dvPlatform,
   dvExecutable,
   dvPath,
   dvConfigPath,
   dvUseFPC,

   dvToolsPath,
   dvBuildPath,
   dvBuildLibOptimizationLevels: TDVar;

   currentPlatform: PBuildPlatform;
   currentLazarus: PBuildLazarusInstall;

function getdvCurrentPlatform(): PBuildPlatform;
begin
   if(BuildInstalls.Platforms.n > 0) then
      exit(BuildInstalls.Platforms.GetLast());

   Result := nil;
end;

function getdvCurrentLazInstall(): PBuildLazarusInstall;
begin
   if(BuildInstalls.Lazarus.n > 0) then
      exit(BuildInstalls.Lazarus.GetLast());

   Result := nil;
end;


procedure TBuildConfiguration.LoadConfiguration();
var
   fn: StdString;

begin
   build.AutoDeterminedConfigPath := false;

   fn := appPath.HomeConfigurationDir('.' + SYSTEM_NAME) + 'location.config';

   if(FileUtils.Exists(fn) > 0) then begin
      {load config_path configuration if one exists}
      dvarf.ReadText(dvgLocation, fn);
   end;

   if(build.ConfigPath = 'default') then
      AutoDetermineConfigPath();

   {read general configuration}
   fn := build.ConfigPath + 'build.config';

   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   {read user configuration}
   fn := build.ConfigPath + 'user.config';
   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   FileUtils.NormalizePathEx(build.Tools.Build);
   FileUtils.NormalizePathEx(build.Tools.Path);
end;

procedure TBuildConfiguration.SaveLocationConfiguration();
var
   fn: StdString;

begin
   fn := appPath.HomeConfigurationDir('.' + SYSTEM_NAME) + 'location.config';

   log.i('build > Wrote location configuration at: ' + fn);
   dvarf.WriteText(dvgLocation, fn);
end;

procedure TBuildConfiguration.LoadUnits();
var
   fn: StdString;

begin
   fn := build.ConfigPath + 'units.config';

   LoadConfigFile(fn);
end;

procedure TBuildConfiguration.LoadConfigFile(const fn: StdString);
begin
   if(FileUtils.Exists(fn) > 0) then begin
      currentConfigFilePath := ExtractFilePath(fn);

      {read Units from unit configuration}
      dvarf.ReadText(dvgUnits, fn);
   end;
end;

function tryDetermineConfigPath(startPath: StdString): boolean;
var
   path: StdString;

begin
   build.ConfigPath := IncludeTrailingPathDelimiter(startPath);
   path := build.ConfigPath;

   repeat
      if(FileUtils.Exists(path + 'build' + DirectorySeparator + 'here.build') > 0) then begin
         build.ConfigPath := path + 'build' + DirectorySeparator;
         break;
      end else begin
         if(path = IncludeTrailingPathDelimiterNonEmpty(GetParentDirectory(path))) or (path = '') then begin
            path := '';
            break;
         end;

         path := IncludeTrailingPathDelimiterNonEmpty(GetParentDirectory(path));
      end;
   until (path = '');

   if(path <> '') then
      build.ConfigPath := IncludeTrailingPathDelimiter(path) + 'build' + DirectorySeparator
   else
      build.ConfigPath := 'default';

   Result := path <> '';
end;

procedure TBuildConfiguration.AutoDetermineConfigPath();
begin
   if(not tryDetermineConfigPath(GetParentDirectory(appPath.GetExecutablePath()))) then
      tryDetermineConfigPath(GetCurrentDir());

   log.i('build > Auto determined config path: ' + build.ConfigPath);
   build.AutoDeterminedConfigPath := true;
end;

function doesIncludeAll(const path: StdString): boolean;
begin
   Result := strutils.AnsiEndsStr('*', path);
end;

function isRelativePath(const path: StdString): boolean;
begin
   Result := strutils.AnsiContainsStr(path, '..');
end;

VAR
   Walker: TFileTraverse;

function onUnit(const f: TFileTraverseData): boolean;
var
   path: StdString;

begin
   Result := true;

   path := ExtractFilePath(f.f.Name);

   if(build.Units.FindString(path) < 0) then begin
      build.Units.Add(path);

      if(build.VerboseLog) then
         log.v('Auto find unit path: ' + path);
   end;
end;

function onInclude(const f: TFileTraverseData): boolean;
var
   path: StdString;

begin
   Result := true;

   path := ExtractFilePath(f.f.Name);

   if(build.Includes.FindString(path) < 0) then begin
      build.Includes.Add(path);

      if(build.VerboseLog) then
         log.v('Auto find include path: ' + ExtractFilePath(f.f.Name));
   end;
end;

procedure scanUnits(const startPath: StdString);
begin
   log.v('build > Will scan path for units: ' + startPath);

   Walker.ResetExtensions();

   Walker.AddExtension('.pas');

   Walker.OnFile := @onUnit;
   Walker.Run(startPath);
end;

procedure scanIncludes(const startPath: StdString);
begin
   log.v('build > Will scan path for includes: ' + startPath);

   Walker.ResetExtensions();

   Walker.AddExtension('.inc');

   Walker.onFile := @onInclude;
   Walker.Run(startPath);
end;

function processPath(var path: StdString): boolean;
begin
   Result := False;
   ReplaceDirSeparators(path);

   if(isRelativePath(path)) then
      path := ExpandFileName(currentConfigFilePath + currentValue);

   if(doesIncludeAll(path)) then
      exit(True);
end;

{$push}{$warn 5024 off}
procedure dvUnitNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(processPath(currentValue)) then
      scanUnits(ExtractFilePath(currentValue))
   else
      build.Units.Add(currentValue);
end;

procedure dvIncludeNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(processPath(currentValue)) then
      scanIncludes(ExtractFilePath(currentValue))
   else
      build.Includes.Add(currentValue);
end;

procedure dvFPCNotify(var {%H-}context: TDVarNotificationContext);
var
   platform: TBuildPlatform;

begin
   currentMode := 'fpc';

   if(currentValue = 'default') then begin
      currentPlatform := BuildInstalls.DefaultPlatform;
      exit;
   end;

   platform.Initialize(platform);
   platform.Name := currentValue;

   BuildInstalls.Platforms.Add(platform);
   currentPlatform := getdvCurrentPlatform();
end;

procedure dvLazarusNotify(var {%H-}context: TDVarNotificationContext);
var
   laz: TBuildLazarusInstall;

begin
   currentMode := 'lazarus';

   if(currentValue = 'default') then begin
      currentLazarus := BuildInstalls.DefaultLazarus;
      exit;
   end;

   laz.Initialize(laz);
   laz.Name := currentValue;

   BuildInstalls.Lazarus.Add(laz);
   currentLazarus := getdvCurrentLazInstall();
end;

procedure dvPlatformNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.SetPlatform(currentValue);
end;

procedure dvPathNotify(var {%H-}context: TDVarNotificationContext);
begin
   FileUtils.NormalizePathEx(currentValue);

   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.Path := currentValue
   else if(currentMode = 'lazarus') and (currentLazarus <> nil) then
      currentLazarus^.Path := currentValue;
end;

procedure dvExecutableNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.Executable := currentValue;
end;

procedure dvConfigPathNotify(var {%H-}context: TDVarNotificationContext);
begin
   FileUtils.NormalizePathEx(currentValue);

   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.ConfigPath := currentValue
   else if(currentMode = 'lazarus') and (currentLazarus <> nil) then
      currentLazarus^.ConfigPath := currentValue;
end;

procedure dvUseFPCNotify(var {%H-}context: TDVarNotificationContext);
var
   platform: PBuildPlatform;

begin
   if(currentMode = 'lazarus') and (currentLazarus <> nil) then begin
      platform := BuildInstalls.Platforms.FindByName(currentValue);

      if(platform <> nil) then begin
         {set the used fpc for the lazarus install}
         currentLazarus^.FPC := platform;
      end else
         log.w('Could not find platform: ' + currentValue + ' used by ' + currentLazarus^.Name);
   end;
end;

procedure libOptimizationLevelsNotify(var {%H-}context: TDVarNotificationContext);
var
   i: loopint;
   optimizationLevels: TStringArray;

begin
   optimizationLevels := strExplode(currentValue, ',');

   if(currentPlatform <> nil) and (Length(optimizationLevels) > 0) then begin
      for i := 0 to High(optimizationLevels) do begin
         currentPlatform^.OptimizationLevels.Add(optimizationLevels[i]);
      end;
   end;
end;
{$pop}

procedure loadConfiguration();
begin
   BuildConfiguration.LoadConfiguration();
end;

procedure loadUnits();
begin
   if(BuildConfiguration.DoLoadUnits) then
      BuildConfiguration.LoadUnits();
end;

INITIALIZATION
   TFileTraverse.Initialize(Walker);

   BuildConfiguration.dvgLocation := dvar.RootGroup;
   BuildConfiguration.dvgLocation.Add(dvConfigLocation, 'location', dtcSTRING, @build.ConfigPath);

   { CONFIGURATION }
   BuildConfiguration.dvgConfig := dvar.RootGroup;

   { FPC }
   BuildConfiguration.dvgConfig.Add(dvFPC, 'fpc', dtcSTRING, @currentValue);
   dvFPC.pNotify := @dvFPCNotify;

   { LAZARUS }
   BuildConfiguration.dvgConfig.Add(dvLazarus, 'lazarus', dtcSTRING, @currentValue);
   dvLazarus.pNotify := @dvLazarusNotify;

   { PLATFORM }
   BuildConfiguration.dvgConfig.Add(dvPlatform, 'platform', dtcSTRING, @currentValue);
   dvPlatform.pNotify := @dvPlatformNotify;

   { PATH }
   BuildConfiguration.dvgConfig.Add(dvPath, 'path', dtcSTRING, @currentValue);
   dvPath.pNotify := @dvPathNotify;

   { EXECUTABLE }
   BuildConfiguration.dvgConfig.Add(dvExecutable, 'executable', dtcSTRING, @currentValue);
   dvExecutable.pNotify := @dvExecutableNotify;

   { CONFIG PATH }
   BuildConfiguration.dvgConfig.Add(dvConfigPath, 'config_path', dtcSTRING, @currentValue);
   dvConfigPath.pNotify := @dvConfigPathNotify;

   { CONFIG PATH }
   BuildConfiguration.dvgConfig.Add(dvUseFPC, 'use_fpc', dtcSTRING, @currentValue);
   dvUseFPC.pNotify := @dvUseFPCNotify;

   BuildConfiguration.dvgConfig.Add(dvToolsPath, 'tools_path', dtcSTRING, @build.Tools.Path);
   BuildConfiguration.dvgConfig.Add(dvBuildPath, 'build_path', dtcSTRING, @build.Tools.Build);
   BuildConfiguration.dvgConfig.Add(dvBuildLibOptimizationLevels, 'lib_optimization_levels', dtcSTRING, @currentValue);
   dvBuildLibOptimizationLevels.pNotify := @libOptimizationLevelsNotify;

   { UNITS}

   BuildConfiguration.dvgUnits := dvar.RootGroup;
   BuildConfiguration.dvgUnits.Add('base', BuildConfiguration.dvgUnitsBase);

   BuildConfiguration.dvgUnits.Add(dvUnitsUnit, 'unit', dtcSTRING, @currentValue);
   dvUnitsUnit.pNotify := @dvUnitNotify;
   BuildConfiguration.dvgUnits.Add(dvUnitsInclude, 'include', dtcSTRING, @currentValue);
   dvUnitsInclude.pNotify := @dvIncludeNotify;

   build.OnLoadConfiguration.Add(@loadConfiguration);
   build.OnInitialize.Add(@loadUnits);

   BuildConfiguration.DoLoadUnits := true;
END.
