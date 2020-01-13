{
   uBuild
   Copyright (C) 2015. Dejan Boras

   Started On:    08.02.2015.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uBuild;

INTERFACE

   USES
      process, sysutils, strutils, uProcessHelpers, ParamUtils, StreamIO,
      uStd, uLog, uFileUtils, StringUtils, ConsoleUtils, uSimpleParser, uTiming,
      udvars, dvaruFile,
      appuPaths
      {$IFDEF UNIX}, BaseUnix{$ENDIF};

CONST
   { build system name }
   SYSTEM_NAME = 'fpbuild';

   FPC_VERSION = {$I %FPCVersion%};
   FPC_TARGET = {$I %FPCTARGET%};
   FPC_TARGETCPU = {$I %FPCTARGETCPU%};
   FPC_TARGETOS = {$I %FPCTARGETOS%};

TYPE
   PBuildPlatform = ^TBuildPlatform;

   { TBuildPlatform }
   {per platform configuration}
   TBuildPlatform = record
      x64: boolean;

      Name,
      Platform,
      Path,
      ConfigPath,
      {fpc version}
      Version: StdString;
      OptimizationLevels: TSimpleStringList;

      class procedure Initialize(out p: TBuildPlatform); static;
      function GetName(): StdString;
   end;

   TBuildPlatforms = specialize TSimpleList<TBuildPlatform>;

   { TBuildPlatformsHelper }

   TBuildPlatformsHelper = record helper for TBuildPlatforms
      function FindIndexByName(const name: StdString): loopint;
      function FindByName(const name: StdString): PBuildPlatform;
   end;


   PBuildLazarusInstall = ^TBuildLazarusInstall;

   { TBuildLazarusInstall }

   {per lazarus configuration}

   TBuildLazarusInstall = record
      x64: boolean;

      Name,
      Path,
      ConfigPath: StdString;

      FPC: PBuildPlatform;

      class procedure Initialize(out install: TBuildLazarusInstall); static;
      function GetFPCName(): StdString;
   end;

   TBuildLazarusInstalls = specialize TSimpleList<TBuildLazarusInstall>;

   { TLazarusInstallsHelper }

   TLazarusInstallsHelper = record helper for TBuildLazarusInstalls
      function FindIndexByName(const name: StdString): loopint;
      function FindByName(const name: StdString): PBuildLazarusInstall;
      function FindByPlatform(platform: PBuildPlatform): PBuildLazarusInstall;
   end;


   { TBuildSystemTools }

   TBuildSystemTools = record
      Path,
      Build: StdString;

      procedure SetPath(const s: StdString);
      procedure SetBuildPath(const s: StdString);
   end;

   { TBuildSystem }

   TBuildSystem = record
      public
      VerboseLog,
      Initialized,
      {have we automagically determined where our config is located at}
      AutoDeterminedConfigPath: boolean;

      {for which target are we built}
      BuiltWithTarget: StdString;
      {with which fpc version are we built}
      BuiltWithVersion: StdString;

      Tools: TBuildSystemTools;
      {dvar configuration root}
      dvgLocation: TDVarGroup;
      {units configuration root}
      dvgUnits,
      {configuration root}
      dvgConfig,
      {units base path group}
      dvgUnitsBase: TDVarGroup;

      {build configuration path}
      ConfigPath,
      {build mode}
      BuildMode: StdString;

      {selected optimization level}
      OptimizationLevel: loopint;

      {Configurations for various platforms (first one is default one for the current system), for cross-compiling}
      Platforms: TBuildPlatforms;

      {configurations for various lazarus installs}
      LazarusInstalls: TBuildLazarusInstalls;

      {result of build output}
      Output: record
         Redirect,
         Success: boolean;
         ExitCode,
         ExitStatus: loopint;
         ExecutableName,
         ErrorDecription,
         LastLine: StdString;
         OnLine: TProcedures;
      end;

      FPCOptions: record
         UnitOutputPath: StdString;
      end;

      Options: record
         {we're building a library}
         IsLibrary,
         {rebuilds everything}
         Rebuild: boolean;
      end;

      Units,
      Includes,
      Symbols: TSimpleStringList;

      CurrentPlatform: PBuildPlatform;
      CurrentLazarus: PBuildLazarusInstall;
      OptimizationLevels: TSimpleStringList;

      DefaultPlatform: PBuildPlatform;
      DefaultLazarus: PBuildLazarusInstall;

      OnInitialize: TProcedures;

      {initialize the build system}
      procedure Initialize();
      {reinitialize the build system (e.g. after config path change)}
      procedure ReInitialize();
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

      {get lazarus project filename for the given path (which may already include project filename)}
      function GetLPIFilename(const path: StdString): StdString;
      {get tool process}
      function GetToolProcess(): TProcess;

      {build a lazarus project}
      procedure Laz(const originalPath: StdString);
      {retrieves the executable name from a lazarus project}
      function GetExecutableNameFromLPI(const path: StdString): StdString;
      {build an fpc program}
      procedure Pas(const originalPath: StdString);
      {used to report building failed for a process (laz or fpc)}
      procedure BuildingFailed(const p: TProcess);

      {copies a tool into the tool directory}
      procedure CopyTool(const path: StdString);

      {build a tools (lazarus project) and copies it to the tools directory}
      procedure LazTool(const path: StdString);
      {build a tools (fpc source) and copies it to the tools directory}
      procedure PasTool(const path: StdString);

      {writes out output of a process}
      procedure LogOutput(const p: TProcess);

      {run a command (abstraction over process.RunCommand)}
      procedure RunCommand(const exename: StdString; const commands: array of StdString);
      procedure RunCommandCurrentDir(const exename: StdString; const commands: array of StdString);
      {get the name of an executable}
      function GetExecutableName(const name: StdString; isLibrary: boolean = false): StdString;

      {checks if lazarus is in environment path}
      function LazarusInPathEnv(): boolean;
      {checks if fpc is in environment path}
      function FPCINPathEnv(): boolean;

      {get the semicolon separated includes path from a list of strings relative the base path}
      function GetIncludesPath(const basePath: StdString; const paths: TSimpleStringList): StdString;
      {get the semicolon separated includes path from a list of strings relative the base path, including the existing items}
      function GetIncludesPath(const basePath: StdString; const paths: TSimpleStringList; const existing: StdString): StdString;

      {stores the output of a build process into the output structure}
      procedure StoreOutput(p: TProcess);
      procedure ResetOutput();
      {wait for a build process to finish (fpc/lazbuild)}
      procedure Wait(p: TProcess);

      {get an optimization level name}
      function GetOptimizationLevelName(level: loopint): StdString;
      {get a human readable optimization level name}
      function GetOptimizationLevelNameHuman(level: loopint): StdString;
      {get lazarus executable}
      function GetLazarusExecutable(): StdString;
      function GetLazarusStartExecutable(): StdString;

      {get current platform}
      function GetPlatform(): PBuildPlatform;
      {find platform for specified target and fpc version}
      function FindPlatform(const target: string; const version: string = ''): PBuildPlatform;
      {get current lazarus install}
      function GetLazarus(): PBuildLazarusInstall;
      {set current platform by its name}
      function SetPlatform(const name: StdString): Boolean;
      {set lazarus by name}
      function SetLazarusInstall(const name: StdString): Boolean;
      {find platform by name, returns nil if nothing found}
      function FindPlatform(const name: StdString): PBuildPlatform;
      {find lazarus install by name, returns nil if nothing found}
      function FindLazarusInstall(const name: StdString): PBuildLazarusInstall;
      {find lazarus install by platform}
      function FindLazarusInstallForPlatform(platform: PBuildPlatform): PBuildLazarusInstall;
      {get the platform we're compiled with}
      function GetCurrentPlatform(): StdString;

      {test all platforms}
      procedure TestPlatforms();
      {sets the platform based on what is available}
      procedure SetupAvailablePlatform();
      {sets the lazarus install based on what is available}
      procedure SetupAvailableLazarus();

      {get current platform and settings as an fpc command line string}
      function GetFPCCommandLineAsString(): StdString;
      function GetFPCCommandLine(emptyBefore: loopint = 0; emptyAfter: loopint = 0): TStringArray;

      {get all commmand line defined symbol parameters}
      procedure GetSymbolParameters();
      {set default symbols for current platform}
      procedure SetDefaultSymbols();

      {set default values if these were not set through config}
      procedure SetupDefaults();

      {get the target name with which the current build was made}
      class function GetBuiltWithTarget(): StdString; static;
   end;

VAR
   build: TBuildSystem;

IMPLEMENTATION

VAR
   { store config_path configuration file}
   dvConfigLocation: TDVar;

   dvUnitsUnit,
   dvUnitsInclude,
   dvUnitsBaseWin,
   dvUnitsBaseUnix,
   dvUnitsBaseLinux,
   dvUnitsBaseDarwin: TDVar;

   currentMode: StdString = 'fpc';
   currentConfigFilePath,
   currentValue: StdString;

   dvFPC,
   dvLazarus,
   dvPlatform,
   dvCPU,
   dvPath,
   dvConfigPath,
   dvUseFPC,

   dvToolsPath,
   dvBuildPath,
   dvBuildLibOptimizationLevels: TDVar;

   {current base path read from units.config}
   winBasePath,
   unixBasePath,
   darwinBasePath: StdString;

   currentPlatform: PBuildPlatform;
   currentLazarus: PBuildLazarusInstall;

function getdvCurrentPlatform(): PBuildPlatform;
begin
   if(build.Platforms.n > 0) then
      exit(build.Platforms.GetLast());

   Result := nil;
end;

function getdvCurrentLazInstall(): PBuildLazarusInstall;
begin
   if(build.LazarusInstalls.n > 0) then
      exit(build.LazarusInstalls.GetLast());

   Result := nil;
end;

procedure CreateDefaultPlatform();
var
   defaultPlatform: TBuildPlatform;

begin
   defaultPlatform.Initialize(defaultPlatform);
   defaultPlatform.Name := 'default';

   build.Platforms.Dispose();
   build.Platforms.Add(defaultPlatform);

   currentPlatform := build.Platforms.GetLast();

   build.DefaultPlatform := currentPlatform;
end;

procedure CreateDefaultLazarus();
var
   defaultLaz: TBuildLazarusInstall;

begin
   defaultLaz.Initialize(defaultLaz);

   defaultLaz.Name := 'default';
   build.LazarusInstalls.Dispose();
   build.LazarusInstalls.Add(defaultLaz);

   defaultLaz.FPC := @build.Platforms.List[0];

   currentLazarus := build.LazarusInstalls.GetLast();
   build.DefaultLazarus := currentLazarus;
end;

{ TLazarusInstallsHelper }

function TLazarusInstallsHelper.FindIndexByName(const name: StdString): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(i);
   end;

   Result := -1;
end;

function TLazarusInstallsHelper.FindByName(const name: StdString): PBuildLazarusInstall;
var
   index: loopint;

begin
   index := FindIndexByName(name);

   if(index > -1) then
      exit(@List[index]);

   Result := nil;
end;

function TLazarusInstallsHelper.FindByPlatform(platform: PBuildPlatform): PBuildLazarusInstall;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].FPC = platform) then
         exit(@List[i]);
   end;

   Result := nil;
end;

{ TBuildPlatformsHelper }

function TBuildPlatformsHelper.FindIndexByName(const name: StdString): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(i);
   end;

   Result := -1;
end;

function TBuildPlatformsHelper.FindByName(const name: StdString): PBuildPlatform;
var
   index: loopint;

begin
   index := FindIndexByName(name);

   if(index > -1) then
      exit(@List[index]);

   Result := nil;
end;

{ TBuildLazarusInstall }

class procedure TBuildLazarusInstall.Initialize(out install: TBuildLazarusInstall);
begin
   ZeroPtr(@install, SizeOf(install));
end;

function TBuildLazarusInstall.GetFPCName(): StdString;
begin
   Result := '';

   if(FPC <> nil) then
      Result := FPC^.Name;
end;

{ TBuildPlatform }

class procedure TBuildPlatform.Initialize(out p: TBuildPlatform);
begin
   ZeroOut(p, SizeOf(p));

   p.OptimizationLevels.InitializeValues(p.OptimizationLevels);
end;

function TBuildPlatform.GetName(): StdString;
begin
   Result := Name;

   if(Name = 'default') then
      Result := build.GetBuiltWithTarget();
end;

{ TBuildSystemTools }

procedure TBuildSystemTools.SetPath(const s: StdString);
begin
   Path := s;
   FileUtils.NormalizePathEx(Path);
end;

procedure TBuildSystemTools.SetBuildPath(const s: StdString);
begin
   Build := s;
   FileUtils.NormalizePathEx(Build);
end;

{ TBuildSystem }

procedure TBuildSystem.ReInitialize();
begin
   CurrentLazarus := nil;
   CurrentPlatform := nil;

   Units.Dispose();
   Includes.Dispose();
   Symbols.Dispose();

   Platforms.Dispose();
   LazarusInstalls.Dispose();

   OptimizationLevels.Dispose();
   Tools.Build := '';
   Tools.Path := '';

   Initialized := false;

   Initialize();
end;

procedure TBuildSystem.Initialize();
var
   start: TDateTime;

begin
   if(Initialized) then
      exit;

   start := Now;

   CreateDefaultPlatform();
   CreateDefaultLazarus();

   LoadConfiguration();

   {setup default values if defaults were not overriden}
   SetupDefaults();

   if(ConfigPath = 'default') then
      exit;

   {setup unit paths}
   LoadUnits();

   OnInitialize.Call();

   {go through Platforms and find an available platform}
   SetupAvailablePlatform();
   SetupAvailableLazarus();

   TestPlatforms();

   log.v('build > Initialized (Elapsed: ' + start.ElapsedfToString() + 's)');

   Initialized := true;
end;

procedure TBuildSystem.LoadConfiguration();
var
   tempConfigPath,
   fn,
   platform,
   mode: StdString;

begin
   AutoDeterminedConfigPath := false;
   tempConfigPath := appPath.HomeConfigurationDir('.' + SYSTEM_NAME);

   fn := tempConfigPath + 'location.config';

   if(FileUtils.Exists(fn) > 0) then begin
      {load config_path configuration if one exists}
      dvarf.ReadText(dvgLocation, fn);

      {if can't find the specified location, restore default}
      if (ConfigPath <> 'default') then begin
         FileUtils.NormalizePathEx(ConfigPath);
         ConfigPath := IncludeTrailingPathDelimiter(ConfigPath);

         if not(FileUtils.DirectoryExists(ConfigPath)) then begin
            log.w('build > Could not find configuration directory: ' + ConfigPath);
            log.i('build > Will revert location configuration to default');

            ConfigPath := 'default';
         end;
      end;
   end;

   if(ConfigPath = 'default') then begin
      log.w('build > Configuration location is not set (location config at: ' + fn + ')');
      AutoDetermineConfigPath();
   end;

   {$IFDEF WINDOWS}
   platform := 'win';
   {$ELSE}
      {$IFDEF UNIX}
         {$IFDEF DARWIN}
         platform := 'darwin';
         {$ELSE}
         platform := 'unix';
         {$ENDIF}
      {$ELSE}
      {$FATAL uBuild does not support this platform}
      {$ENDIF}
   {$ENDIF}

   {read general configuration}
   fn := ConfigPath + 'build.config';
   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   {read per platform mode configuration}
   mode := '';
   if(BuildMode <> '') then
      mode := '.' + BuildMode;

   fn := ConfigPath + 'build.' + platform + mode + '.config';
   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   {read user configuration}
   fn := ConfigPath + 'user.config';
   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   FileUtils.NormalizePathEx(Tools.Build);
   FileUtils.NormalizePathEx(Tools.Path);
end;

procedure TBuildSystem.SaveLocationConfiguration();
var
   fn: StdString;

begin
   fn := appPath.HomeConfigurationDir('.' + SYSTEM_NAME) + 'location.config';

   log.i('build > Wrote location configuration at: ' + fn);
   dvarf.WriteText(dvgLocation, fn);
end;

procedure TBuildSystem.LoadUnits();
var
   fn: StdString;

begin
   fn := ConfigPath + 'units.config';

   LoadConfigFile(fn);
end;

procedure TBuildSystem.LoadConfigFile(const fn: StdString);
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

procedure TBuildSystem.AutoDetermineConfigPath();
begin
   if(not tryDetermineConfigPath(GetParentDirectory(appPath.GetExecutablePath()))) then
      tryDetermineConfigPath(GetCurrentDir());

   log.w('build > Auto determined config path: ' + ConfigPath);
   AutoDeterminedConfigPath := true;
end;


function TBuildSystem.GetLPIFilename(const path: StdString): StdString;
begin
   if(ExtractFileExt(path) = '.lpi') then
      Result := path
   else
      Result := path + '.lpi';
end;

function TBuildSystem.GetToolProcess(): TProcess;
begin
   Result := TProcess.Create(nil);

   if(not Output.Redirect) then
      Result.Options := Result.Options + [poWaitOnExit]
   else
      Result.Options := Result.Options + [poUsePipes];
end;

procedure TBuildSystem.Laz(const originalPath: StdString);
var
   p: TProcess;
   executableName: StdString;
   path: StdString;

begin
   path := originalPath;
   ReplaceDirSeparators(path);

   ResetOutput();

   log.i('build > Building lazarus project: ' + path);

   p := GetToolProcess();

   p.Executable := GetLazarus()^.Path + GetExecutableName('lazbuild');
   if(Options.Rebuild) then
      p.Parameters.Add('-B');

   p.Parameters.Add('-q');

   p.Parameters.Add(GetLPIFilename(path));

   try
      p.Execute();
   except
      on e: Exception do begin
         log.e('build > Failed to execute lazbuild: ' + GetLazarus()^.Path + ' (' + e.ToString() + ')');
         p.Free();
         exit;
      end;
   end;

   Wait(p);
   StoreOutput(p);

   if((p.ExitStatus = 0) and (p.ExitCode = 0)) then begin
      {NOTE: we exepect file name in LPI to not have a path}

      executableName := GetExecutableName(GetExecutableNameFromLPI(path));

      if(executableName <> '') then
         Output.ExecutableName := ExtractFilePath(path) + executableName
      else
         Output.ExecutableName := ExtractAllNoExt(path);

      Output.Success := true;
      log.k('build > Building successful');
   end else begin
      BuildingFailed(p);
   end;

   p.Free();
end;

VAR
   executableNameNext: boolean;
   executableName: StdString;

function readf(var parseData: TParseData): boolean;
begin
   Result := true;

   if(parseData.CurrentLine = '<Target>') then begin
      executableNameNext := true;
   end else begin
      if(executableNameNext) then begin
         executableNameNext := false;

         if(pos('Filename', parseData.CurrentLine) > 0) then begin
            parseData.CurrentLine := CopyAfterDel(parseData.CurrentLine, '"');
            parseData.CurrentLine := CopyToDel(parseData.CurrentLine, '"');
            executableName := parseData.CurrentLine;
         end;
      end;
   end;
end;

function TBuildSystem.GetExecutableNameFromLPI(const path: StdString): StdString;
var
   p: TParseData;

begin
   executableName := '';
   executableNameNext := true;

   TParseData.Init(p);
   p.StripWhitespace := true;
   p.Read(GetLPIFilename(path), TParseMethod(@readf));

   Result := executableName;
end;

procedure TBuildSystem.Pas(const originalPath: StdString);
var
   p: TProcess;
   path: StdString;
   i: loopint;

begin
   path := originalPath;
   ReplaceDirSeparators(path);

   Output.Success := false;

   log.i('build > Building: ' + path);

   p := GetToolProcess();

   p.Executable := GetExecutableName(GetPlatform()^.Path + 'fpc');
   if(Options.Rebuild) then
      p.Parameters.Add('-B');

   if(FPCOptions.UnitOutputPath <> '') then
      p.Parameters.Add('-FU' + FPCOptions.UnitOutputPath);

   if(Units.n > 0) then begin
      for i := 0 to Units.n - 1 do begin
         p.Parameters.Add('-Fu' + Units.List[i]);
      end;
   end;

   if(Includes.n > 0) then begin
      for i := 0 to Includes.n - 1 do begin
         p.Parameters.Add('-Fi' + Includes.List[i]);
      end;
   end;

   if(Symbols.n > 0) then begin
      for i := 0 to Symbols.n - 1 do begin
         p.Parameters.Add('-d' + Symbols.List[i]);
      end;
   end;

   p.Parameters.Add(path);

   try
      p.Execute();
   except
      on e: Exception do begin
         log.e('build > Failed running: ' + p.Executable + ' (' + e.ToString() + ')');
         p.Free();
         exit();
     end;
   end;

   Wait(p);
   StoreOutput(p);

   if((p.ExitStatus = 0) and (p.ExitCode = 0)) then begin
      Output.ExecutableName := GetExecutableName(ExtractFilePath(path) + ExtractFileNameNoExt(path), Options.IsLibrary);
      Output.Success := true;
      log.k('build > Building successful');
   end else begin
      BuildingFailed(p);
   end;

   p.Free();
end;

procedure TBuildSystem.BuildingFailed(const p: TProcess);
begin
   Output.ErrorDecription := '';
   Output.Success := false;

   if(not FileExists(p.Executable)) then
      Output.ErrorDecription := 'tool not found: ' + p.Executable;

   if(p.ExitCode <> 0) then
      Output.ErrorDecription := 'tool returned exit code: ' + sf(p.ExitCode);
   if(p.ExitStatus <> 0) then
      Output.ErrorDecription := 'tool exited with status: ' + sf(p.ExitStatus);

   log.e('build > ' + Output.ErrorDecription);

   LogOutput(p);
end;

procedure TBuildSystem.CopyTool(const path: StdString);
var
   fullPath, target: StdString;
   error: fileint;

begin
   Output.Success := false;

   if(path = '') then begin
      log.e('build > CopyTool given empty parameter.');
      exit;
   end;

   fullPath := path;
   ReplaceDirSeparators(fullPath);

   target := Tools.Path + ExtractFileName(fullPath);

   if(FileUtils.Exists(fullPath) < 0) then begin
      log.e('build > Tool: ' + fullPath + ' could not be found');
      exit;
   end;

   error := FileUtils.Copy(fullPath, target);
   if(error < 0) then begin
      log.e('build > Copy tool: ' + path + ' to ' + target + ' failed: ' + sf(error) + '/' + getRunTimeErrorDescription(ioE));
      exit;
   end else
      log.i('build > Copied tool: ' + path + ' to ' + target);

   {$IFDEF UNIX}
   if(FpChmod(target, &755) <> 0) then begin
      log.e('build > Failed to set tool permissions: ' + target);
      exit;
   end;
   {$ENDIF}

   Output.Success := true;
end;

procedure TBuildSystem.LazTool(const path: StdString);
begin
   Laz(path);

   if(Output.Success) then
      CopyTool(Output.ExecutableName);
end;

procedure TBuildSystem.PasTool(const path: StdString);
begin
   Pas(path);

   if(Output.Success) then
      CopyTool(Output.ExecutableName);
end;

procedure TBuildSystem.LogOutput(const p: TProcess);
var
   buffer: array[0..32768] of char;
   bufferRead: loopint;

begin
   {$IFDEF DEBUG}
   buffer[0] := #0;
   {$ENDIF}
   if(p.Output <> nil) and (p.Output.NumBytesAvailable > 0) then begin
      bufferRead := p.Output.Read(buffer{%H-}, Length(buffer));
      buffer[bufferRead] := #0;
      log.i(pchar(@buffer));
   end;
end;

procedure TBuildSystem.RunCommand(const exename: StdString; const commands: array of StdString);
var
   outputString: string = '';
   ansiCommands: array of String;

begin
   ansiCommands := StringUtils.GetAnsiStrings(commands);

   if(not process.RunCommand(exename, ansiCommands, outputString)) then
      log.e('Failed to run process: ' + exename);

   if(outputString <> '') then
      console.i(outputString);
end;

procedure TBuildSystem.RunCommandCurrentDir(const exename: StdString; const commands: array of StdString);
begin
   RunCommand(IncludeTrailingPathDelimiterNonEmpty(GetCurrentDir()) + exename, commands);
end;

function TBuildSystem.GetExecutableName(const name: StdString; isLibrary: boolean): StdString;
begin
   {$IFDEF WINDOWS}
   if(ExtractFileExt(name) = '') then begin
      if(not isLibrary) then
         Result := name + '.exe'
      else
         Result := name + '.dll';
   end else
      Result := name;
   {$ELSE}
   if(not isLibrary) then
      Result := name
   else begin
      if(ExtractFileExt(name) = '') then
         Result := 'lib' + name + '.so';
   end;
   {$ENDIF}
end;

function TBuildSystem.LazarusInPathEnv(): boolean;
var
   path: StdString;

begin
   path := GetEnvironmentVariable('PATH');
   exit(Pos(DirectorySeparator + 'lazarus', path) <> 0)
end;

function TBuildSystem.FPCINPathEnv(): boolean;
var
   path: StdString;

begin
   path := GetEnvironmentVariable('PATH');
   exit(Pos(DirectorySeparator + 'fpc', path) <> 0)
end;

function TBuildSystem.GetIncludesPath(const basePath: StdString; const paths: TSimpleStringList): StdString;
var
   p, relative: StdString;
   i: loopint;

begin
   p := '';

   if(paths.n > 0) then begin
      for i := 0 to (paths.n - 1) do begin
         relative := ExtractRelativepath(basePath, paths.List[i]);

         if(i < paths.n - 1) then
            p := p + relative + ';'
         else
            p := p + relative;
      end;
   end;

   Result := p;
end;

function TBuildSystem.GetIncludesPath(const basePath: StdString; const paths: TSimpleStringList; const existing: StdString): StdString;
var
   p, relative: StdString;
   existingItems: TStringArray;
   i,
   j: loopint;
   exists: boolean;
   newPaths: TSimpleStringList;

begin
   existingItems := strExplode(existing, ';');

   newPaths.Initialize(newPaths);

   if(Length(existingItems) > 0) then
      for i := 0 to Length(existingItems) - 1 do
         newPaths.Add(existingItems[i]);

   if(paths.n > 0) then
      for i := 0 to (paths.n - 1) do begin
         {get relative path and check if already exists}
         relative := ExtractRelativepath(basePath, paths.List[i]);

         exists := false;
         if(newPaths.n > 0) then begin
            for j := 0 to (newPaths.n - 1) do begin
               if(newPaths.list[j] = relative) then begin
                  exists := true;
                  break;
               end;
            end;
         end;

         if(not exists) then
            newPaths.Add(relative);
      end;

   {create new list}
   p := '';

   if(newPaths.n > 0) then begin
      for i := 0 to (newPaths.n - 1) do begin
         relative := newPaths.list[i];

         if(i < newPaths.n - 1) then
            p := p + relative + ';'
         else
            p := p + relative;
      end;
   end;

   Result := p;
end;

procedure TBuildSystem.StoreOutput(p: TProcess);
begin
   Output.ExitCode := p.ExitCode;

   if(poUsePipes in p.Options) then begin
      if(not (poStderrToOutPut in p.Options)) then begin
         if(p.Stderr.NumBytesAvailable > 0) then
            Output.ErrorDecription := p.Stderr.ReadAnsiString();
      end;
   end;
end;

procedure TBuildSystem.ResetOutput();
begin
   Output.Success := false;
   Output.ExecutableName := '';
   Output.ErrorDecription := '';
end;

procedure TBuildSystem.Wait(p: TProcess);
var
   s: StdString;
   f: TextFile;

begin
   ZeroOut(f, SizeOf(f));

   if(Output.Redirect) then begin
      AssignStream(f, p.Output);
      Reset(f);
   end;

   repeat
      if(Output.Redirect) then begin
         while(not eof(f)) do begin
            ReadLn(f, s);
            Output.LastLine := s;
            Output.OnLine.Call();
         end;

         break;
      end;

      Sleep(5);
   until (not p.Running);

   if(Output.Redirect) then begin
      Close(f);
   end;
end;

function TBuildSystem.GetOptimizationLevelName(level: loopint): StdString;
begin
   if(level > 0) and (level <= CurrentPlatform^.OptimizationLevels.n) then
      Result := CurrentPlatform^.OptimizationLevels.List[level - 1]
   else
      Result := '';
end;

function TBuildSystem.GetOptimizationLevelNameHuman(level: loopint): StdString;
begin
   Result := GetOptimizationLevelName(level);

   if(Result = '') then
      Result := 'none';
end;

function TBuildSystem.GetLazarusExecutable(): StdString;
begin
   Result := GetLazarus()^.Path + GetExecutableName('lazarus');
end;

function TBuildSystem.GetLazarusStartExecutable(): StdString;
begin
   Result := GetLazarus()^.Path + GetExecutableName('startlazarus');
end;

function TBuildSystem.GetPlatform(): PBuildPlatform;
begin
   Result := CurrentPlatform;

   if(CurrentPlatform = nil) then
      Result := @Platforms.List[0];
end;

function TBuildSystem.FindPlatform(const target: string; const version: string): PBuildPlatform;
var
   i: loopint;

begin
   for i := 0 to Platforms.n - 1 do begin
      if(Platforms.List[i].Platform = target) then begin
         if(version <> '') then begin
            if(Pos(version, Platforms.List[i].Version) = 1) then
               exit(@Platforms.List[i]);
         end else
            exit(@Platforms.List[i]);
      end;
   end;

   Result := nil;
end;

function TBuildSystem.GetLazarus(): PBuildLazarusInstall;
begin
   Result := CurrentLazarus;

   if(Result = nil) then
      Result := @LazarusInstalls.List[0];
end;

function TBuildSystem.SetPlatform(const name: StdString): Boolean;
var
   p: PBuildPlatform;

begin
   p := FindPlatform(name);

   if(p <> nil) then begin
      CurrentPlatform := p;
      exit(true);
   end;

   CurrentPlatform := @Platforms.List[0];
   Result := false;
end;

function TBuildSystem.SetLazarusInstall(const name: StdString): Boolean;
var
   p: PBuildLazarusInstall;

begin
   p := FindLazarusInstall(name);

   if(p <> nil) then begin
      CurrentLazarus := p;
      exit(true);
   end;

   CurrentLazarus := @LazarusInstalls.List[0];
   Result := false;
end;

function TBuildSystem.FindPlatform(const name: StdString): PBuildPlatform;
begin
   Result := Platforms.FindByName(name);
end;

function TBuildSystem.FindLazarusInstall(const name: StdString): PBuildLazarusInstall;
begin
   Result := LazarusInstalls.FindByName(name);
end;

function TBuildSystem.FindLazarusInstallForPlatform(platform: PBuildPlatform): PBuildLazarusInstall;
begin
   Result := LazarusInstalls.FindByPlatform(platform);
end;

function TBuildSystem.GetCurrentPlatform(): StdString;
begin
   Result := LowerCase({$I %FPCTARGETOS%});
end;

procedure TBuildSystem.TestPlatforms();
var
   i: loopint;
   p: PBuildPlatform;
   process: TProcess;

begin
   for i := 0 to Platforms.n - 1 do begin
      p := @Platforms.List[i];

      process := GetToolProcess();
      process.Executable := GetExecutableName(p^.Path + 'fpc');
      process.Parameters.Add('-iW');
      process.Options := process.Options + [poUsePipes];

      try
         process.Execute();

         p^.Version := process.GetOutputString();

         log.v('Found fpc(' + p^.Version + ') executable for platform ' + p^.Name + ' at path ' + process.Executable);
      except
         on e: Exception do begin
            log.w('Could not execute fpc for platform ' + p^.Name + ' at path ' + process.Executable);
         end;
      end;

      FreeObject(process);
   end;
end;

procedure TBuildSystem.SetupAvailablePlatform();
var
   i: loopint;

begin
   if(CurrentPlatform = nil) then begin
      if(Platforms.n > 0) then
         CurrentPlatform := @Platforms.List[0]
      else
         exit;
   end;

   {don't touch the current platform if we have a compiler}
   if(not DirectoryExists(CurrentPlatform^.Path)) then begin
      for i := 0 to Platforms.n - 1 do begin
         if(DirectoryExists(Platforms.List[i].Path)) then begin
            log.i('build > Available platform set to ' + Platforms.List[i].Name);
            SetPlatform(Platforms.List[i].Name);
            exit;
         end;
      end;
   end;
end;

procedure TBuildSystem.SetupAvailableLazarus();
var
   i: loopint;

begin
   if(CurrentLazarus = nil) then begin
      if(LazarusInstalls.n > 0) then
         CurrentLazarus := @LazarusInstalls.List[0]
      else
         exit;
   end;

   {don't touch the current lazarus install if we have one}
   if(not DirectoryExists(CurrentLazarus^.Path)) then begin
      for i := 0 to LazarusInstalls.n - 1 do begin
         if(DirectoryExists(LazarusInstalls.List[i].Path)) then begin
            log.i('build > Available lazarus install set to ' + LazarusInstalls.List[i].Name);
            SetLazarusInstall(LazarusInstalls.List[i].Name);
            exit;
         end;
      end;
   end;
end;

function TBuildSystem.GetFPCCommandLineAsString(): StdString;
var
   i: loopint;
   c: TAppendableString;

begin
   c := '';

   for i := 0 to Units.n - 1 do begin
      c.Add('-Fu' + Units.List[i], ' ');
   end;

   for i := 0 to Includes.n - 1 do begin
      c.Add('-Fi' + Includes.List[i], ' ');
   end;

   for i := 0 to Symbols.n - 1 do begin
      c.Add('-d' + Symbols.List[i], ' ');
   end;

   Result := c;
end;

function TBuildSystem.GetFPCCommandLine(emptyBefore: loopint = 0; emptyAfter: loopint = 0): TStringArray;
var
   count,
   i,
   index: loopint;
   arguments: TStringArray;

procedure AddArgument(const s: StdString);
begin
   arguments[index] := s;
   inc(index);
end;

begin
   count := emptyBefore + emptyAfter;

   inc(count, Units.n);
   inc(count, Includes.n);
   inc(count, Symbols.n);

   index := emptyBefore;

   arguments := nil;
   SetLength(arguments, count);

   for i := 0 to Units.n - 1 do begin
      AddArgument('-Fu' + Units.List[i]);
   end;

   for i := 0 to Includes.n - 1 do begin
      AddArgument('-Fi' + Includes.List[i]);
   end;

   for i := 0 to Symbols.n - 1 do begin
      AddArgument('-d' + Symbols.List[i]);
   end;

   Result := arguments;
end;

procedure TBuildSystem.GetSymbolParameters();
var
   cur,
   symbol: StdString;

begin
   parameters.Reset();

   repeat
      cur := parameters.Next();

      if(cur = '-d') then begin
         symbol := parameters.Next();

         if(symbol <> '') then begin
            Symbols.Add(symbol);
         end;
      end;
   until parameters.IsEnd();
end;

procedure TBuildSystem.SetDefaultSymbols();
begin
   {$IFDEF UNIX}
   {if we don't have anything defined, we'll use X11 by default}
   if(Symbols.FindLowercase('x11') < 0) or (Symbols.FindLowercase('wayland') < 0) then
      Symbols.Add('X11');
   {$ENDIF}
end;

procedure TBuildSystem.SetupDefaults();
begin
   if(DefaultPlatform^.Path = '') then begin
      if(VerboseLog) then
         log.v('Build config path: ' + ConfigPath);

      {$IF DEFINED(LINUX)}
      if(VerboseLog) then
         log.v('build > auto fpc defaults for linux');

      DefaultPlatform^.Path := '/usr/bin/';
      {$ELSEIF DEFINED(DARWIN)}
      if(VerboseLog) then
         log.v('build > auto fpc defaults for darwin');

      DefaultPlatform^.Path := '/usr/local/bin/'
      {$ELSEIF DEFINED(WINDOWS)}
      {TODO: Determine default fpc path for windows}
      if(VerboseLog) then
         log.v('build > auto fpc defaults for windows');
      {$ENDIF}

      if(VerboseLog) then
         log.v('build > using auto defaults for fpc platform');
   end;

   if(Tools.Path = '') then begin
      {$IF DEFINED(LINUX)}
      if(VerboseLog) then
         log.v('build > auto tools/build defaults for linux');

      Tools.Path := '~/bin/';
      {$ELSEIF DEFINED(DARWIN)}
      if(VerboseLog) then
         log.v('build > auto tools/build defaults for darwin');

      Tools.Path := '~/bin/';
      {$ELSEIF DEFINED(WINDOWS)}
      {TODO: Determine default fpc path for windows}
      if(VerboseLog) then
         log.v('build > auto tools/build defaults for windows');

      Tools.Path :=  ExpandFileName(IncludeTrailingPathDelimiterNonEmpty(ConfigPath) + '..\tools');
      {$ENDIF}

      FileUtils.NormalizePathEx(Tools.Path);

      if(VerboseLog) then
         log.v('Auto tools path: ' + Tools.Path);
   end;

   if(ConfigPath <> 'default') or (Tools.Build = '') then begin
      Tools.Build := ConfigPath;
      FileUtils.NormalizePathEx(Tools.Build);

      if(VerboseLog) then
         log.v('Auto build path: ' + Tools.Build);
   end;

   if(DefaultPlatform^.OptimizationLevels.n = 0) then begin
      {$IF DEFINED(CPUX86_64) OR DEFINEDCPUX86_32)}
      DefaultPlatform^.OptimizationLevels.Add('sse');
      DefaultPlatform^.OptimizationLevels.Add('sse2');
      DefaultPlatform^.OptimizationLevels.Add('sse3');
      {$ENDIF}
   end;


   if(DefaultLazarus^.Path = '') then begin
      {$IF DEFINED(LINUX)}
      if(VerboseLog) then
         log.v('build > auto lazarus defaults for linux');

      DefaultLazarus^.Path := '/usr/bin/';
      {$ELSEIF DEFINED(DARWIN)}
      if(VerboseLog) then
         log.v('build > auto lazarus defaults for darwin');

      DefaultLazarus^.Path := '/Develope/lazarus';
      {$ELSEIF DEFINED(WINDOW)}
      DefaultLazarus^.Path := 'C:\lazarus\';
      {$ENDIF}

      if(VerboseLog) then
         log.v('build > using auto defaults for lazarus install');
   end;

end;

class function TBuildSystem.GetBuiltWithTarget(): StdString;
begin
   Result := LowerCase(FPC_TARGETCPU + '-' + FPC_TARGETOS);
end;

function getBasePath(): StdString;
begin
   {$IFDEF UNIX}
   {$IFDEF DARWIN}
   Result := darwinBasePath;
   {$ELSE}
   Result := unixBasePath;
   {$ENDIF}
   {$ELSE}
      {$IFDEF WINDOWS}
      Result := winBasePath;
      {$ELSE}
      Result := '';
      {$FATAL uBuild BasePath not support on this platform}
      {$ENDIF}
   {$ENDIF}
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

function onUnit(const fn: StdString): boolean;
var
   path: StdString;

begin
   Result := true;

   path := ExtractFilePath(fn);

   if(build.Units.FindString(path) < 0) then begin
      build.Units.Add(path);

      if(build.VerboseLog) then
         log.v('Auto find unit path: ' + path);
   end;
end;

function onInclude(const fn: StdString): boolean;
var
   path: StdString;

begin
   Result := true;

   path := ExtractFilePath(fn);

   if(build.Includes.FindString(path) < 0) then begin
      build.Includes.Add(path);

      if(build.VerboseLog) then
         log.v('Auto find include path: ' + ExtractFilePath(fn));
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
      build.Units.Add(getBasePath() + currentValue);
end;

procedure dvIncludeNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(processPath(currentValue)) then
      scanIncludes(ExtractFilePath(currentValue))
   else
      build.Includes.Add(getBasePath() + currentValue);
end;

procedure dvNotifyBasePath(var context: TDVarNotificationContext);
begin
   FileUtils.NormalizePathEx(StdString(context.DVar^.Variable^));
end;

procedure dvFPCNotify(var {%H-}context: TDVarNotificationContext);
var
   platform: TBuildPlatform;

begin
   currentMode := 'fpc';

   if(currentValue = 'default') then begin
      currentPlatform := build.DefaultPlatform;
      exit;
   end;

   platform.Initialize(platform);
   platform.Name := currentValue;

   build.Platforms.Add(platform);
   currentPlatform := getdvCurrentPlatform();
end;

procedure dvLazarusNotify(var {%H-}context: TDVarNotificationContext);
var
   laz: TBuildLazarusInstall;

begin
   currentMode := 'lazarus';

   if(currentValue = 'default') then begin
      currentLazarus := build.DefaultLazarus;
      exit;
   end;

   laz.Initialize(laz);
   laz.Name := currentValue;

   build.LazarusInstalls.Add(laz);
   currentLazarus := getdvCurrentLazInstall();
end;

procedure dvCPUNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(currentMode = 'fpc') and (currentPlatform <> nil) then begin
      if(currentValue = '64') then
         currentPlatform^.x64 := True;
   end;
end;

procedure dvPlatformNotify(var {%H-}context: TDVarNotificationContext);
begin
   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.Platform := currentValue;
end;

procedure dvPathNotify(var {%H-}context: TDVarNotificationContext);
begin
   FileUtils.NormalizePathEx(currentValue);

   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.Path := currentValue
   else if(currentMode = 'lazarus') and (currentLazarus <> nil) then
      currentLazarus^.Path := currentValue;
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
      platform := build.Platforms.FindByName(currentValue);

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

VAR
   paramHandler: TParameterHandler;

function processParam(const paramKey: StdString; var {%H-}params: array of StdString; {%H-}n: longint): boolean;
begin
   Result := false;

   if(paramKey = '--build-verbose') then begin
      build.VerboseLog := True;

      Result := true;
   end;
end;


INITIALIZATION
   TFileTraverse.Initialize(Walker);
   TProcedures.Initialize(build.Output.OnLine);

   build.ConfigPath := 'default';

   build.dvgLocation := dvar.RootGroup;
   build.dvgLocation.Add(dvConfigLocation, 'location', dtcSTRING, @build.ConfigPath);

   build.Units.Initialize(build.Units);
   build.Includes.Initialize(build.Includes);
   build.Symbols.Initialize(build.Symbols);
   build.Platforms.Initialize(build.Platforms);
   build.LazarusInstalls.Initialize(build.LazarusInstalls);
   build.OptimizationLevels.Initialize(build.OptimizationLevels);

   { CONFIGURATION }
   build.dvgConfig := dvar.RootGroup;

   { FPC }
   build.dvgConfig.Add(dvFPC, 'fpc', dtcSTRING, @currentValue);
   dvFPC.pNotify := @dvFPCNotify;

   { LAZARUS }
   build.dvgConfig.Add(dvLazarus, 'lazarus', dtcSTRING, @currentValue);
   dvLazarus.pNotify := @dvLazarusNotify;

   { CPU }
   build.dvgConfig.Add(dvCPU, 'cpu', dtcSTRING, @currentValue);
   dvCPU.pNotify := @dvCPUNotify;

   { PLATFORM }
   build.dvgConfig.Add(dvPlatform, 'platform', dtcSTRING, @currentValue);
   dvPlatform.pNotify := @dvPlatformNotify;

   { PATH }
   build.dvgConfig.Add(dvPath, 'path', dtcSTRING, @currentValue);
   dvPath.pNotify := @dvPathNotify;

   { CONFIG PATH }
   build.dvgConfig.Add(dvConfigPath, 'config_path', dtcSTRING, @currentValue);
   dvConfigPath.pNotify := @dvConfigPathNotify;

   { CONFIG PATH }
   build.dvgConfig.Add(dvUseFPC, 'use_fpc', dtcSTRING, @currentValue);
   dvUseFPC.pNotify := @dvUseFPCNotify;

   build.dvgConfig.Add(dvToolsPath, 'tools_path', dtcSTRING, @build.Tools.Path);
   build.dvgConfig.Add(dvBuildPath, 'build_path', dtcSTRING, @build.Tools.Build);
   build.dvgConfig.Add(dvBuildLibOptimizationLevels, 'lib_optimization_levels', dtcSTRING, @currentValue);
   dvBuildLibOptimizationLevels.pNotify := @libOptimizationLevelsNotify;

   { UNITS}

   build.dvgUnits := dvar.RootGroup;
   build.dvgUnits.Add('base', build.dvgUnitsBase);

   build.dvgUnitsBase.Add(dvUnitsBaseWin, 'win', dtcSTRING, @winBasePath);
   build.dvgUnitsBase.Add(dvUnitsBaseUnix, 'unix', dtcSTRING, @unixBasePath);
   build.dvgUnitsBase.Add(dvUnitsBaseLinux, 'linux', dtcSTRING, @unixBasePath);
   build.dvgUnitsBase.Add(dvUnitsBaseDarwin, 'darwin', dtcString, @darwinBasePath);

   {$IFDEF WINDOWS}
   dvUnitsBaseWin.pNotify := @dvNotifyBasePath;
   {$ENDIF}

   {$IFDEF DARWIN}
      dvUnitsBaseDarwin.pNotify := @dvNotifyBasePath;
   {$ELSE}
     {$IFDEF UNIX}
     dvUnitsBaseUnix.pNotify := @dvNotifyBasePath;
     dvUnitsBaseLinux.pNotify := @dvNotifyBasePath;
     {$ENDIF}
   {$ENDIF}

   build.dvgUnits.Add(dvUnitsUnit, 'unit', dtcSTRING, @currentValue);
   dvUnitsUnit.pNotify := @dvUnitNotify;
   build.dvgUnits.Add(dvUnitsInclude, 'include', dtcSTRING, @currentValue);
   dvUnitsInclude.pNotify := @dvIncludeNotify;

   CreateDefaultPlatform();

   parameters.AddHandler(paramHandler, 'build', '--build-verbose', @processParam);

   { determine our built with target and version }

   build.BuiltWithTarget := TBuildSystem.GetBuiltWithTarget();

   if(Pos('-', FPC_VERSION) > 0) then
      build.BuiltWithVersion := copy(FPC_VERSION, 1, Pos('-', FPC_VERSION))
   else
      build.BuiltWithVersion := FPC_VERSION;
END.
