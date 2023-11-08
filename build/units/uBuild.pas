{
   uTest
   Copyright (C) 2011. Dejan Boras

   Started On:    08.02.2015.

   TODO: Load lazarus (GetLazarusPath) and fpc paths from config or try to find them.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uBuild;

INTERFACE

   USES
      process, sysutils, strutils, pipes, uProcessHelpers,
      uStd, uLog, uFileUtils, StringUtils, ConsoleUtils, uSimpleParser, ParamUtils, uTiming,
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
      Version: string;
      OptimizationLevels: TPreallocatedStringArrayList;

      class procedure Initialize(out p: TBuildPlatform); static;
      function GetName(): string;
   end;

   TBuildPlatforms = specialize TPreallocatedArrayList<TBuildPlatform>;

   { TBuildPlatformsHelper }

   TBuildPlatformsHelper = record helper for TBuildPlatforms
      function FindIndexByName(const name: string): loopint;
      function FindByName(const name: string): PBuildPlatform;
   end;


   PBuildLazarusInstall = ^TBuildLazarusInstall;

   { TBuildLazarusInstall }

   {per lazarus configuration}

   TBuildLazarusInstall = record
      x64: boolean;

      Name,
      Path,
      ConfigPath,
      UseFpc: string;

      FPC: PBuildPlatform;

      class procedure Initialize(out install: TBuildLazarusInstall); static;
   end;

   TBuildLazarusInstalls = specialize TPreallocatedArrayList<TBuildLazarusInstall>;

   { TLazarusInstallsHelper }

   TLazarusInstallsHelper = record helper for TBuildLazarusInstalls
      function FindIndexByName(const name: string): loopint;
      function FindByName(const name: string): PBuildLazarusInstall;
   end;


   { TBuildSystemTools }

   TBuildSystemTools = record
      Path,
      Build: string;

      procedure SetPath(const s: string);
      procedure SetBuildPath(const s: string);
   end;

   { TBuildSystem }

   TBuildSystem = record
      public
      WriteLog,
      Initialized,
      {have we automagically determined where our config is located at}
      AutoDeterminedConfigPath: boolean;

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
      BuildMode: string;

      {Configurations for various platforms (first one is default one for the current system), for cross-compiling}
      Platforms: TBuildPlatforms;

      {configurations for various lazarus installs}
      LazarusInstalls: TBuildLazarusInstalls;

      {result of build output}
      Output: record
         Success: boolean;
         ExitCode,
         ExitStatus: longint;
         ExecutableName,
         ErrorDecription: string;
      end;

      FPCOptions: record
         UnitOutputPath: string;
      end;

      Options: record
         {we're building a library}
         IsLibrary,
         {rebuilds everything}
         Rebuild: boolean;
      end;

      Units,
      Includes,
      Symbols: TPreallocatedStringArrayList;

      Libraries: record
         Source,
         Target: string;
         OptimizationLevel: longint;
      end;

      CurrentPlatform: PBuildPlatform;
      CurrentLazarus: PBuildLazarusInstall;
      OptimizationLevels: TPreallocatedStringArrayList;

      DefaultPlatform: PBuildPlatform;
      DefaultLazarus: PBuildLazarusInstall;

      {initialize the build system}
      procedure Initialize();
      {load configuration}
      procedure LoadConfiguration();
      {save location configuration}
      procedure SaveLocationConfiguration();
      {load configured units}
      procedure LoadUnits();

      {automatically determine config path}
      procedure AutoDetermineConfigPath();

      {get lazarus project filename for the given path (which may already include project filename)}
      function GetLPIFilename(const path: string): string;
      {get tool process}
      function GetToolProcess(): TProcess;

      {build a lazarus project}
      procedure Laz(const originalPath: string);
      {retrieves the executable name from a lazarus project}
      function GetExecutableNameFromLPI(const path: string): string;
      {build an fpc program}
      procedure Pas(const originalPath: string);
      {used to report building failed for a process (laz or fpc)}
      procedure BuildingFailed(const p: TProcess);

      {copies a tool into the tool directory}
      procedure CopyTool(const path: string);

      {build a tools (lazarus project) and copies it to the tools directory}
      procedure LazTool(const path: string);
      {build a tools (fpc source) and copies it to the tools directory}
      procedure PasTool(const path: string);

      {writes out output of a process}
      procedure LogOutput(const p: TProcess);

      {run a command (abstraction over process.RunCommand)}
      procedure RunCommand(const exename:string; const commands: array of string);
      procedure RunCommandCurrentDir(const exename:string; const commands: array of string);
      {get the name of an executable}
      function GetExecutableName(const name: string; isLibrary: boolean = false): string;

      {checks if lazarus is in environment path}
      function LazarusInPathEnv(): boolean;
      {checks if fpc is in environment path}
      function FPCINPathEnv(): boolean;

      {get the semicolon separated includes path from a list of strings relative the base path}
      function GetIncludesPath(const basePath: string; const paths: TPreallocatedStringArrayList): string;
      {get the semicolon separated includes path from a list of strings relative the base path, including the existing items}
      function GetIncludesPath(const basePath: string; const paths: TPreallocatedStringArrayList; const existing: string): string;

      {stores the output of a build process into the output structure}
      procedure StoreOutput(p: TProcess);
      procedure ResetOutput();
      procedure Wait(p: TProcess);

      {copy a library with the given name from source to target (set in Libraries)}
      function CopyLibrary(const name: string; const newName: string = ''): boolean;
      {get an optimization level name}
      function GetOptimizationLevelName(optimizationLevel: longint): string;
      {get a human readable optimization level name}
      function GetOptimizationLevelNameHuman(optimizationLevel: longint): string;
      {get lazarus executable}
      function GetLazarusExecutable(): string;
      function GetLazarusStartExecutable(): string;

      {get current platform}
      function GetPlatform(): PBuildPlatform;
      {get current lazarus install}
      function GetLazarus(): PBuildLazarusInstall;
      {set current platform by its name}
      function SetPlatform(const name: string): Boolean;
      {set lazarus by name}
      function SetLazarusInstall(const name: string): Boolean;
      {find platform by name, returns nil if nothing found}
      function FindPlatform(const name: string): PBuildPlatform;
      {find lazarus install by name, returns nil if nothing found}
      function FindLazarusInstall(const name: string): PBuildLazarusInstall;
      {get the platform we're compiled with}
      function GetCurrentPlatform(): string;

      {test all platforms}
      procedure TestPlatforms();
      {sets the platform based on what is available}
      procedure SetupAvailablePlatform();
      {sets the lazarus install based on what is available}
      procedure SetupAvailableLazarus();

      {get current platform and settings as an fpc command line string}
      function GetFPCCommandLine(): string;

      {get all commmand line defined symbol parameters}
      procedure GetSymbolParameters();
      {set default symbols for current platform}
      procedure SetDefaultSymbols();

      {set default values if these were not set through config}
      procedure SetupDefaults();
   end;

   { TPascalSourceBuilder }

   TPascalSourceBuilder = record
      Name,
      Header,
      sInterface,
      sImplementation,
      sUses,
      sExports,
      sInitialization,
      sMain: TAppendableString;

      procedure AddUses(var p: TAppendableString);

      function BuildUnit(): TAppendableString;
      function BuildProgram(): TAppendableString;
      function BuildLibrary(): TAppendableString;
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

   currentMode: string = 'fpc';
   currentValue: string;

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
   darwinBasePath: string;

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

   defaultLaz.UseFpc := build.Platforms.List[0].Name;
   defaultLaz.FPC := @build.Platforms.List[0];

   currentLazarus := build.LazarusInstalls.GetLast();
   build.DefaultLazarus := currentLazarus;
end;

{ TLazarusInstallsHelper }

function TLazarusInstallsHelper.FindIndexByName(const name: string): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(i);
   end;

   Result := -1;
end;

function TLazarusInstallsHelper.FindByName(const name: string): PBuildLazarusInstall;
var
   index: loopint;

begin
   index := FindIndexByName(name);

   if(index > -1) then
      exit(@List[index]);

   Result := nil;
end;

{ TBuildPlatformsHelper }

function TBuildPlatformsHelper.FindIndexByName(const name: string): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(i);
   end;

   Result := -1;
end;

function TBuildPlatformsHelper.FindByName(const name: string): PBuildPlatform;
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

{ TBuildPlatform }

class procedure TBuildPlatform.Initialize(out p: TBuildPlatform);
begin
   ZeroOut(p, SizeOf(p));

   p.OptimizationLevels.InitializeValues(p.OptimizationLevels);
end;

function TBuildPlatform.GetName(): string;
begin
   Result := Name;

   if(Name = 'default') then begin
      {$IFDEF WINDOWS}
         {$IFDEF CPU64}
         Result := 'win64';
         {$ELSE}
         Result := 'win32';
         {$ENDIF}
      {$ENDIF}

      {$IFDEF LINUX}
         {$IFDEF CPU64}
         Result := 'linux32';
         {$ELSE}
         Result := 'linux64';
         {$ENDIF}
      {$ENDIF}

      {$IFDEF DARWIN}
         {$IFDEF CPU64}
         Result := 'darwin32';
         {$ELSE}
         Result := 'darwin64';
         {$ENDIF}
      {$ENDIF}
   end;
end;

{ TPascalUnitBuilder }

procedure TPascalSourceBuilder.AddUses(var p: TAppendableString);
begin
   if(sUses <> '') then begin
      p.Add('USES');
      p.Add(sUses + ';');
      p.Add('');
   end;
end;

function TPascalSourceBuilder.BuildUnit(): TAppendableString;
begin
   result := '';

   if(Header <> '') then
      result.Add(Header);

   result.Add('UNIT ' + Name + ';');
   result.Add('');

   result.Add('INTERFACE');

   AddUses(result);

   if(sInterface <> '') then begin
      result.Add('');
      result.Add(sInterface);
   end;

   result.Add('');

   result.Add('IMPLEMENTATION');
   result.Add('');

   if(sImplementation <> '') then begin
      result.Add(sImplementation);
      result.Add('');
   end;

   if(sInitialization <> '') then begin
      result.Add('INITIALIZATION');
      result.Add(sInitialization);
      result.Add('');
   end;

   result.Add('END.');
end;

function TPascalSourceBuilder.BuildProgram: TAppendableString;
begin
   result := '';

   if(Header <> '') then
      result.Add(Header);

   result.Add('PROGRAM ' + Name + ';');

   if(sUses <> '') then
      AddUses(result)
   else
      result.Add('');

   result.Add('BEGIN');

   if(sMain <> '') then begin
      result.Add('');
      result.Add(sMain);
   end;

   result.Add('');
   result.Add('END.');
end;

function TPascalSourceBuilder.BuildLibrary: TAppendableString;
begin
   result := '';

   if(Header<> '') then
      result.Add(Header);

   result.Add('LIBRARY ' + Name + ';');
   result.Add('');

   if(sUses <> '') then
      AddUses(result)
   else
      result.Add('');

   if(sInterface <> '') then begin
      result.Add('');
      result.Add(sInterface);
   end;

   if(sExports <> '') then begin
      result.Add('EXPORTS');
      result.Add(sExports + ';');
      result.Add('');
   end;

   if(sInitialization <> '') then begin
      result.Add('INITIALIZATION');
      result.Add(sInitialization);
      result.Add('');
   end;

   result.Add('END.');
end;

{ TBuildSystemTools }

procedure TBuildSystemTools.SetPath(const s: string);
begin
   path := s;
   FileUtils.NormalizePathEx(path);
end;

procedure TBuildSystemTools.SetBuildPath(const s: string);
begin
   build := s;
   FileUtils.NormalizePathEx(build);
end;

{ TBuildSystem }

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

   Libraries.Source := Tools.Build + 'libraries' + DirectorySeparator;

   {go through platforms and find an available platform}
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
   mode: string;

begin
   AutoDeterminedConfigPath := false;
   tempConfigPath := appPath.HomeConfigurationDir('.' + SYSTEM_NAME);

   fn := tempConfigPath + 'location.config';

   if(FileUtils.Exists(fn) > 0) then begin
      {load config_path configuration if one exists}
      dvarf.ReadText(dvgLocation, fn);

      {if can't find the specified location, restore default}
      if (build.ConfigPath <> 'default') then begin
         FileUtils.NormalizePathEx(build.ConfigPath);
         build.ConfigPath := IncludeTrailingPathDelimiter(build.ConfigPath);

         if not(FileUtils.DirectoryExists(build.ConfigPath)) then begin
            log.w('build > Could not find configuration directory: ' + build.ConfigPath);
            log.i('build > Will revert location configuration to default');

            build.ConfigPath := 'default';
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
   if(buildMode <> '') then
      mode := '.' + buildMode;

   fn := ConfigPath + 'build.' + platform + mode + '.config';
   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   FileUtils.NormalizePathEx(tools.build);
   FileUtils.NormalizePathEx(tools.path);
end;

procedure TBuildSystem.SaveLocationConfiguration();
var
   fn: string;

begin
   fn := appPath.HomeConfigurationDir('.' + SYSTEM_NAME) + 'location.config';

   log.i('build > Wrote location configuration at: ' + fn);
   dvarf.WriteText(dvgLocation, fn);
end;

procedure TBuildSystem.LoadUnits();
var
   fn: string;

begin
   fn := ConfigPath + 'units.config';

   if(FileUtils.Exists(fn) > 0) then begin
      {read units from unit configuration}
      dvarf.ReadText(dvgUnits, fn);
   end;
end;

function tryDetermineConfigPath(startPath: string): boolean;
var
   path,
   tryPath: String;

begin
   build.ConfigPath := IncludeTrailingPathDelimiter(startPath);
   path := build.ConfigPath;

   {TODO: Make this more robust}
   repeat
      tryPath := path + 'build' + DirectorySeparator + 'here.build';

      if(FileUtils.Exists(tryPath) > 0) then begin
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

   build.ConfigPath := path;
   Result := path <> '';
end;

procedure TBuildSystem.AutoDetermineConfigPath();
begin
   if(not tryDetermineConfigPath(GetParentDirectory(appPath.GetExecutablePath()))) then
      tryDetermineConfigPath(GetCurrentDir());

   log.w('build > Auto determined config path: ' + build.ConfigPath);
   AutoDeterminedConfigPath := true;
end;


function TBuildSystem.GetLPIFilename(const path: string): string;
begin
   if(ExtractFileExt(path) = '.lpi') then
      result := path
   else
      result := path + '.lpi';
end;

function TBuildSystem.GetToolProcess(): TProcess;
begin
   Result := TProcess.Create(nil);
   Result.Options := Result.Options + [poWaitOnExit];
end;

procedure TBuildSystem.Laz(const originalPath: string);
var
   p: TProcess;
   executableName: string;
   path: string;

begin
   path := originalPath;
   ReplaceDirSeparators(path);

   ResetOutput();

   log.i('build > Building lazarus project: ' + path);

   p := GetToolProcess();

   p.Executable := GetLazarus()^.Path +  GetExecutableName('lazbuild');
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
      executableName := GetExecutableNameFromLPI(path);

      if(executableName <> '') then
         output.executableName := ExtractFilePath(path) + executableName
      else
         output.executableName := ExtractAllNoExt(path);

      output.ExecutableName := GetExecutableName(output.executableName, Options.IsLibrary);

      output.success := true;
      log.k('build > Building successful');
   end else begin
      BuildingFailed(p);
   end;

   p.Free();
end;

VAR
   executableNameNext: boolean;
   executableName: string;

function readf(var parseData: TParseData): boolean;
begin
   result := true;

   if(parseData.currentLine = '<Target>') then begin
      executableNameNext := true;
   end else begin
      if(executableNameNext) then begin
         executableNameNext := false;

         if(pos('Filename', parseData.currentLine) > 0) then begin
            parseData.currentLine := CopyAfterDel(parseData.currentLine, '"');
            parseData.currentLine := CopyToDel(parseData.currentLine, '"');
            executableName := parseData.currentLine;
         end;
      end;
   end;
end;

function TBuildSystem.GetExecutableNameFromLPI(const path: string): string;
var
   p: TParseData;

begin
   executableName := '';
   executableNameNext := true;

   TParseData.Init(p);
   p.stripWhitespace := true;
   p.Read(GetLPIFilename(path), TParseMethod(@readf));

   result := executableName;
end;

procedure TBuildSystem.Pas(const originalPath: string);
var
   p: TProcess;
   path: string;
   i: loopint;

begin
   path := originalPath;
   ReplaceDirSeparators(path);

   output.success := false;

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
      output.ExecutableName := GetExecutableName(ExtractFilePath(path) + ExtractFileNameNoExt(path), Options.IsLibrary);
      output.Success := true;
      log.k('build > Building successful');
   end else begin
      BuildingFailed(p);
   end;

   p.Free();
end;

procedure TBuildSystem.BuildingFailed(const p: TProcess);
begin
   output.ErrorDecription := '';
   output.Success := false;

   if(not FileExists(p.Executable)) then
      output.ErrorDecription := 'tool not found: ' + p.Executable;

   if(p.ExitCode <> 0) then
      output.ErrorDecription := 'tool returned exit code: ' + sf(p.ExitCode);
   if(p.ExitStatus <> 0) then
      output.ErrorDecription := 'tool exited with status: ' + sf(p.ExitStatus);

   log.e('build > ' + output.ErrorDecription);

   LogOutput(p);
end;

procedure TBuildSystem.CopyTool(const path: string);
var
   fullPath, target: string;
   error: fileint;

begin
   output.success := false;

   if(path = '') then begin
      log.e('build > CopyTool given empty parameter.');
      exit;
   end;

   fullPath := path;
   ReplaceDirSeparators(fullPath);

   target := tools.path + ExtractFileName(fullPath);

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

   output.Success := true;
end;

procedure TBuildSystem.LazTool(const path: string);
begin
   Laz(path);

   if(output.success) then
      CopyTool(output.executableName);
end;

procedure TBuildSystem.PasTool(const path: string);
begin
   Pas(path);

   if(output.success) then
      CopyTool(output.executableName);
end;

procedure TBuildSystem.LogOutput(const p: TProcess);
var
   buffer: array[0..32768] of char;
   bufferRead: longint;

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

procedure TBuildSystem.RunCommand(const exename: string; const commands: array of string);
var
   outputString: string = '';

begin
   if(not process.RunCommand(exename, commands, outputString)) then
      log.e('Failed to run process: ' + exename);

   if(outputString <> '') then
      console.i(outputString);
end;

procedure TBuildSystem.RunCommandCurrentDir(const exename: string; const commands: array of string);
begin
   RunCommand(IncludeTrailingPathDelimiterNonEmpty(GetCurrentDir()) + exename, commands);
end;

function TBuildSystem.GetExecutableName(const name: string; isLibrary: boolean): string;
begin
   {$IFDEF WINDOWS}
   if(not isLibrary) then
      Result := name + '.exe'
   else
      Result := name + '.dll';
   {$ELSE}
   if(not isLibrary) then
      Result := name
   else
      Result := 'lib' + name + '.so';
   {$ENDIF}
end;

function TBuildSystem.LazarusInPathEnv(): boolean;
var
   path: string;

begin
   path := GetEnvironmentVariable('PATH');
   exit(Pos(DirectorySeparator + 'lazarus', path) <> 0)
end;

function TBuildSystem.FPCINPathEnv(): boolean;
var
   path: string;

begin
   path := GetEnvironmentVariable('PATH');
   exit(Pos(DirectorySeparator + 'fpc', path) <> 0)
end;

function TBuildSystem.GetIncludesPath(const basePath: string; const paths: TPreallocatedStringArrayList): string;
var
   p, relative: string;
   i: longint;

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

   result := p;
end;

function TBuildSystem.GetIncludesPath(const basePath: string; const paths: TPreallocatedStringArrayList; const existing: string): string;
var
   p, relative: string;
   existingItems: TAnsiStringArray;
   i, j: longint;
   exists: boolean;
   newPaths: TPreallocatedStringArrayList;

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

   result := p;
end;

procedure TBuildSystem.StoreOutput(p: TProcess);
begin
   output.ExitCode := p.ExitCode;

   if(poUsePipes in p.Options) then begin
      if(p.Stderr.NumBytesAvailable > 0) then
         output.ErrorDecription := p.Stderr.ReadAnsiString();
   end;
end;

procedure TBuildSystem.ResetOutput();
begin
   output.Success := false;
   output.ExecutableName := '';
   output.ErrorDecription := '';
end;

procedure TBuildSystem.Wait(p: TProcess);
begin
   repeat
      Sleep(1);
   until (not p.Running);
end;

function TBuildSystem.CopyLibrary(const name: string; const newName: string = ''): boolean;
var
   optimizationSource,
   usedSource: string;
   optimizationLevel: longint;

function getNewName(): string;
begin
   if(newName <> '') then
      Result := newName
   else
      Result := name;
end;

function getPath(): string;
begin
   Result := Libraries.Source + IncludeTrailingPathDelimiterNonEmpty(CurrentPlatform^.GetName());
end;

begin
   Result := false;
   optimizationLevel := Libraries.OptimizationLevel;
   usedSource := '';

   {find optimized library if one specified}
   if(Libraries.OptimizationLevel > 0) then begin
      optimizationLevel := Libraries.OptimizationLevel;

      repeat
         optimizationSource := getPath() +
            IncludeTrailingPathDelimiterNonEmpty(GetOptimizationLevelName(optimizationLevel)) + name;

         if(FileUtils.Exists(optimizationSource) > 0) then begin
            if(optimizationLevel <> Libraries.OptimizationLevel) then
               log.w('Could not find optimized library ' + name + ' at level ' +
                  GetOptimizationLevelNameHuman(Libraries.OptimizationLevel) + ', used ' +
                  GetOptimizationLevelNameHuman(optimizationLevel) + ' instead');

            usedSource := optimizationSource;
            break;
         end;

         dec(optimizationLevel);
      until optimizationLevel < 0;

      if(optimizationLevel <= 0) then begin
         log.w('Could not find library ' + name + ' in ' + optimizationSource);
         usedSource := getPath() + name;
      end;
   end else
      usedSource := getPath() + name;

   if(FileUtils.Exists(usedSource) <= 0) then begin
      log.e('Could not find library ' + name + ' in ' + usedSource);

      usedSource := '';

      if(optimizationLevel <= 0) then begin
         for optimizationLevel := 1 to CurrentPlatform^.OptimizationLevels.n do begin
            usedSource := getPath() +
               IncludeTrailingPathDelimiterNonEmpty(GetOptimizationLevelName(optimizationLevel)) + name;

            if(FileUtils.Exists(usedSource) > 0) then begin
               log.w('Using optimized library: ' + usedSource + ' because regular not found');
               break;
            end else
               usedSource := '';
         end;
      end;

      if(usedSource = '') then begin
         log.e('Failed to find library: ' + name + ' in ' + getPath());
         exit(false);
      end;
   end;

   if(FileUtils.Copy(usedSource, Libraries.Target + getNewName()) > 0) then begin
      log.k('Copied ' + getNewName() + ' library successfully');
      Result := true;
   end else
      log.e('Failed to copy library from ' + usedSource + ' to ' + Libraries.Target + getNewName());
end;

function TBuildSystem.GetOptimizationLevelName(optimizationLevel: longint): string;
begin
   if(optimizationLevel > 0) and (optimizationLevel <= CurrentPlatform^.OptimizationLevels.n) then
      Result := CurrentPlatform^.OptimizationLevels.List[optimizationLevel - 1]
   else
      Result := '';
end;

function TBuildSystem.GetOptimizationLevelNameHuman(optimizationLevel: longint): string;
begin
   Result := GetOptimizationLevelName(optimizationLevel);
   if(Result = '') then
      Result := 'none';
end;

function TBuildSystem.GetLazarusExecutable(): string;
begin
   Result := GetLazarus()^.Path + GetExecutableName('lazarus');
end;

function TBuildSystem.GetLazarusStartExecutable(): string;
begin
   Result := GetLazarus()^.Path + GetExecutableName('startlazarus');
end;

function TBuildSystem.GetPlatform(): PBuildPlatform;
begin
   Result := CurrentPlatform;

   if(CurrentPlatform = nil) then
      Result := @Platforms.List[0];
end;

function TBuildSystem.GetLazarus(): PBuildLazarusInstall;
begin
   Result := CurrentLazarus;

   if(Result = nil) then
      Result := @LazarusInstalls.List[0];
end;

function TBuildSystem.SetPlatform(const name: string): Boolean;
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

function TBuildSystem.SetLazarusInstall(const name: string): Boolean;
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

function TBuildSystem.FindPlatform(const name: string): PBuildPlatform;
begin
   Result := Platforms.FindByName(name);
end;

function TBuildSystem.FindLazarusInstall(const name: string): PBuildLazarusInstall;
begin
   Result := LazarusInstalls.FindByName(name);
end;

function TBuildSystem.GetCurrentPlatform(): string;
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

function TBuildSystem.GetFPCCommandLine(): string;
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

procedure TBuildSystem.GetSymbolParameters();
var
   cur,
   symbol: string;

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
   if(build.Symbols.FindLowercase('x11') < 0) or (build.Symbols.FindLowercase('wayland') < 0) then
      build.Symbols.Add('X11');
   {$ENDIF}
end;

procedure TBuildSystem.SetupDefaults();
begin
   if(build.DefaultPlatform^.Path = '') then begin
      log.v(build.ConfigPath);

      {$IF DEFINED(LINUX)}
      log.v('build > auto fpc defaults for linux');
      build.DefaultPlatform^.Path := '/usr/bin/';
      build.Tools.Path := '~/bin/';

      if(build.ConfigPath <> 'default') then
         build.Tools.Build :=  build.ConfigPath;

      FileUtils.NormalizePathEx(build.Tools.Path);
      FileUtils.NormalizePathEx(build.Tools.Build);
      {$ELSEIF DEFINED(DARWIN)}
      log.v('build > auto fpc defaults for darwin');
      build.DefaultPlatform^.Path := '/usr/local/bin/'
      build.Tools.Path := '~/bin/';

      if(build.ConfigPath <> 'default') then
         build.Tools.Build :=  build.ConfigPath;
      {$ELSEIF DEFINED(WINDOWS)}
      {TODO: Determine default fpc path for windows}
      log.v('build > auto fpc defaults for windows');
      if(build.ConfigPath <> 'default') then begin
         build.Tools.Path :=  ExpandFileName(IncludeTrailingPathDelimiterNonEmpty(build.ConfigPath) + '\..\tools');
         build.Tools.Build := build.ConfigPath;
      end;
      {$ENDIF}

      {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86_32)}
      build.DefaultPlatform^.OptimizationLevels.Add('sse');
      build.DefaultPlatform^.OptimizationLevels.Add('sse2');
      build.DefaultPlatform^.OptimizationLevels.Add('sse3');
      {$ENDIF}

      log.v('build > using auto defaults for fpc platform');
   end;

   if(build.DefaultLazarus^.Path = '') then begin
      {$IF DEFINED(LINUX)}
      log.v('build > auto lazarus defaults for linux');
      build.DefaultLazarus^.Path := '/usr/bin/';
      {$ELSEIF DEFINED(DARWIN)}
      log.v('build > auto lazarus defaults for darwin');
      build.DefaultLazarus^.Path := '/Developer/lazarus';
      {$ELSEIF DEFINED(WINDOW)}
      build.DefaultLazarus^.Path := 'C:\lazarus\';
      {$ENDIF}

      log.v('build > using auto defaults for lazarus install');
   end;

end;

function getBasePath(): string;
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

function doesIncludeAll(const path:  string): boolean;
begin
   Result := strutils.AnsiEndsStr('*', path);
end;

function isRelativePath(const path:  string): boolean;
begin
   Result := strutils.AnsiContainsStr(path, '..');
end;

VAR
   Walker: TFileTraverse;

function onUnit(const fn: string): boolean;
var
   path: string;

begin
   Result := true;

   path := ExtractFilePath(fn);

   if(build.Units.FindString(path) < 0) then begin
      build.Units.Add(path);

      log.v('Auto find unit path: ' + path);
   end;
end;

function onInclude(const fn: string): boolean;
var
   path: string;

begin
   Result := true;

   path := ExtractFilePath(fn);

   if(build.Includes.FindString(path) < 0) then begin
      build.Includes.Add(path);

      log.v('Auto find include path: ' + ExtractFilePath(fn));
   end;
end;

procedure scanUnits(const startPath: string);
begin
   log.v('build > Will scan path for units: ' + startPath);

   Walker.ResetExtensions();

   Walker.AddExtension('.pas');

   Walker.onFile := @onUnit;
   Walker.Run(startPath);
end;

procedure scanIncludes(const startPath: string);
begin
   log.v('build > Will scan path for includes: ' + startPath);

   Walker.ResetExtensions();

   Walker.AddExtension('.inc');

   Walker.onFile := @onInclude;
   Walker.Run(startPath);
end;

function processPath(var path: string): boolean;
begin
   Result := False;
   ReplaceDirSeparators(path);

   if(isRelativePath(path)) then begin
      {TODO: Use current config file path}
      path := ExpandFileName(build.ConfigPath + currentValue);
   end;

   if(doesIncludeAll(path)) then
      exit(True);
end;

procedure dvUnitNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   if(processPath(currentValue)) then
      scanUnits(ExtractFilePath(currentValue))
   else
      build.Units.Add(getBasePath() + currentValue);
end;

procedure dvIncludeNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   if(processPath(currentValue)) then
      scanIncludes(ExtractFilePath(currentValue))
   else
      build.Includes.Add(getBasePath() + currentValue);
end;

procedure dvNotifyBasePath({%H-}p: PDVar; {%H-}what: longword);
begin
   FileUtils.NormalizePathEx(string(p^.Variable^));
end;

procedure dvFPCNotify({%H-}p: PDVar; {%H-}what: longword);
var
   platform: TBuildPlatform;

begin
   currentMode := 'fpc';

   platform.Initialize(platform);
   platform.Name := currentValue;

   build.Platforms.Add(platform);
   currentPlatform := getdvCurrentPlatform();
end;

procedure dvLazarusNotify({%H-}p: PDVar; {%H-}what: longword);
var
   laz: TBuildLazarusInstall;

begin
   currentMode := 'lazarus';

   laz.Initialize(laz);
   laz.Name := currentValue;

   build.LazarusInstalls.Add(laz);
   currentLazarus := getdvCurrentLazInstall();
end;

procedure dvCPUNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   if(currentMode = 'fpc') and (currentPlatform <> nil) then begin
      if(currentValue = '64') then
         currentPlatform^.x64 := True;
   end;
end;

procedure dvPlatformNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.Platform := currentValue;
end;

procedure dvPathNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   FileUtils.NormalizePathEx(currentValue);

   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.Path := currentValue
   else if(currentMode = 'lazarus') and (currentLazarus <> nil) then
      currentLazarus^.Path := currentValue;
end;

procedure dvConfigPathNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   FileUtils.NormalizePathEx(currentValue);

   if(currentMode = 'fpc') and (currentPlatform <> nil) then
      currentPlatform^.ConfigPath := currentValue
   else if(currentMode = 'lazarus') and (currentLazarus <> nil) then
      currentLazarus^.ConfigPath := currentValue;
end;

procedure dvUseFPCNotify({%H-}p: PDVar; {%H-}what: longword);
var
   platform: PBuildPlatform;

begin
   {TODO: Check if specified fpc exists in build.Platforms}

   if(currentMode = 'lazarus') and (currentLazarus <> nil) then begin
      platform := build.Platforms.findByName(currentValue);

      if(platform <> nil) then begin
         {set the used fpc for the lazarus install}
         currentLazarus^.UseFpc := currentValue;
         currentLazarus^.FPC := platform;
      end else
         log.w('Could not find platform: ' + currentValue + ' used by ' + currentLazarus^.Name);
   end;
end;

procedure libOptimizationLevelsNotify({%H-}p: PDVar; {%H-}what: longword);
var
   i: loopint;
   optimizationLevels: TAnsiStringArray;

begin
   optimizationLevels := strExplode(currentValue, ',');

   if(currentPlatform <> nil) and (Length(optimizationLevels) > 0) then begin
      for i := 0 to High(optimizationLevels) do begin
         currentPlatform^.OptimizationLevels.Add(optimizationLevels[i]);
      end;
   end;
end;

INITIALIZATION
   TFileTraverse.Initialize(Walker);

   build.WriteLog := true;
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
END.
