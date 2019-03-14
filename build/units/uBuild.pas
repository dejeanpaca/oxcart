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
      process, sysutils, classes,
      uStd, uLog, uFileUtils, StringUtils, ConsoleUtils, uSimpleParser, ParamUtils,
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
      FpcPath,
      FpcConfigPath: string;
      OptimizationLevels: TPreallocatedStringArrayList;

      class procedure Initialize(out platform: TBuildPlatform); static;
   end;

   TBuildPlatforms = specialize TPreallocatedArrayList<TBuildPlatform>;

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
      Initialized: boolean;

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
      {lazarus path}
      LazarusPath,
      {build mode}
      BuildMode: string;

      {Configurations for various platforms (first one is default one for the current system), for cross-compiling}
      Platforms: TBuildPlatforms;

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
      OptimizationLevels: TPreallocatedStringArrayList;

      {initialize the build system}
      procedure Initialize();
      {load configuration}
      procedure LoadConfiguration();
      {save location configuration}
      procedure SaveLocationConfiguration();
      {load configured units}
      procedure LoadUnits();

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
      {set current platform by its name}
      function SetPlatform(const name: string): Boolean;
      {find platform by name, returns nil if nothing found}
      function FindPlatform(const name: string): PBuildPlatform;
      {get the platform we're compiled with}
      function GetCurrentPlatform(): string;

      {test all platforms}
      procedure TestPlatforms();
      {sets the platform based on what is available}
      procedure SetupAvailablePlatform();

      {get current platform and settings as an fpc command line string}
      function GetFPCCommandLine(): string;

      {get all commmand line defined symbol parameters}
      procedure GetSymbolParameters();
      {set default symbols for current platform}
      procedure SetDefaultSymbols();
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

   dvPlatform,
   dvCPU,
   dvLazarusPath,
   dvFPCPath,
   dvToolsPath,
   dvBuildPath,
   dvBuildLibOptimizationLevels: TDVar;

   {cpu bits}
   cpuBits,
   {current unit read from units.config}
   currentUnit,
   {current include read from units.config}
   currentInclude,
   {current platform}
   currentPlatform,
   {library optimization levels}
   libOptimizationLevels,
   {current base path read from units.config}
   winBasePath,
   unixBasePath,
   darwinBasePath,
   {temporary holder}
   tempPath: string;

   temporaryPlatform: PBuildPlatform;

procedure SetupDVars();
var
   platform: PBuildPlatform;

begin
   platform := @build.Platforms.List[build.Platforms.n - 1];

   dvFPCPath.Variable := @platform^.FpcPath;
end;

procedure CreateDefaultPlatform();
var
   defaultPlatform: TBuildPlatform;

begin
   defaultPlatform.Initialize(defaultPlatform);

   defaultPlatform.Name := 'default';
   build.Platforms.Dispose();
   build.Platforms.Add(defaultPlatform);

   temporaryPlatform := @build.Platforms.List[build.Platforms.n - 1];

   SetupDVars();
end;

{ TBuildPlatform }

class procedure TBuildPlatform.Initialize(out platform: TBuildPlatform);
begin
   ZeroOut(platform, SizeOf(platform));
   platform.OptimizationLevels.InitializeValues(platform.OptimizationLevels);
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
begin
   if(Initialized) then
      exit;

   CreateDefaultPlatform();

   LoadConfiguration();

   if(configPath = 'default') then
      exit;

   {setup unit paths}
   LoadUnits();

   {go through platforms and find an available platform}
   SetupAvailablePlatform();

   TestPlatforms();

   Initialized := true;
end;

procedure TBuildSystem.LoadConfiguration();
var
   tempConfigPath,
   fn,
   platform,
   mode: string;
   writeConfig: boolean = false;

begin
   tempConfigPath := appPath.HomeConfigurationDir('.' + SYSTEM_NAME);

   fn := tempConfigPath + 'location.config';

   if(FileUtils.Exists(fn) > 0) then begin
      {load config_path configuration if one exists}
      dvarf.ReadText(dvgLocation, fn);

      {if can't find the specified location, restore default}
      if (build.configPath <> 'default') then begin
         FileUtils.NormalizePathEx(build.configPath);
         build.configPath := IncludeTrailingPathDelimiter(build.configPath);

         if not(FileUtils.DirectoryExists(build.configPath)) then begin
            log.w('build > Could not find configuration directory: ' + build.configPath);
            log.i('build > Will revert location configuration to default');
            build.configPath := 'default';
            writeConfig := true;
         end;
      end;
   end else
      {could not find config_path configuration, so will create default}
      writeConfig := true;

   {need to recreate default configuration file}
   if(writeConfig) then
      SaveLocationConfiguration();

   if(configPath = 'default') then begin
      log.e('build > Configuration location is not set (location config at: ' + fn + ')');
      exit;
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
   fn := configPath + 'build.config';
   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   {read per platform mode configuration}
   mode := '';
   if(buildMode <> '') then
      mode := '.' + buildMode;

   fn := configPath + 'build.' + platform + mode + '.config';
   if(FileUtils.Exists(fn) > 0) then
      dvarf.ReadText(dvgConfig, fn);

   FileUtils.NormalizePathEx(lazarusPath);
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
   fn := configPath + 'units.config';

   if(FileUtils.Exists(fn) > 0) then begin
      {read units from unit configuration}
      dvarf.ReadText(dvgUnits, fn);
   end;
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

   p.Executable := lazarusPath +  GetExecutableName('lazbuild');
   if(Options.Rebuild) then
      p.Parameters.Add('-B');

   p.Parameters.Add('-q');

   p.Parameters.Add(GetLPIFilename(path));

   try
      p.Execute();
   except
      on e: Exception do begin
         log.e('build > Failed to execute lazbuild: ' + lazarusPath + ' (' + e.ToString() + ')');
         p.Free();
         exit;
      end;
   end;

   repeat
   until (not p.Running);

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

   p.Executable := GetExecutableName(GetPlatform()^.FpcPath + 'fpc');
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

(*   repeat
   until (not p.Running);*)

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
   output.exitCode := p.ExitCode;
end;

procedure TBuildSystem.ResetOutput();
begin
   output.success := false;
   output.ExecutableName := '';
   output.ErrorDecription := '';
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
   Result := Libraries.Source + IncludeTrailingPathDelimiterNonEmpty(CurrentPlatform^.Name);
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
   Result := LazarusPath + GetExecutableName('lazarus');
end;

function TBuildSystem.GetLazarusStartExecutable(): string;
begin
   Result := LazarusPath + GetExecutableName('startlazarus');
end;

function TBuildSystem.GetPlatform(): PBuildPlatform;
begin
   Result := CurrentPlatform;

   if(CurrentPlatform = nil) then
      Result := @Platforms.List[0];
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

function TBuildSystem.FindPlatform(const name: string): PBuildPlatform;
var
   i: loopint;

begin
   for i := 0 to Platforms.n - 1 do begin
      if(Platforms.List[i].Name = name) then
         exit(@Platforms.List[i]);
   end;

   Result := nil;
end;

function TBuildSystem.GetCurrentPlatform(): string;
begin
   Result := lowercase({$I %FPCTARGETOS%});
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
      process.Executable := GetExecutableName(p^.FpcPath + 'fpc');
      process.Parameters.Add('-iW');
      process.Options := process.Options + [poUsePipes];

      try
         process.Execute();

         log.v('Found fpc executable for platform ' + p^.Name + ' at path ' + process.Executable);
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
   if(not DirectoryExists(CurrentPlatform^.FpcPath)) then begin
      for i := 0 to Platforms.n - 1 do begin
         if(DirectoryExists(Platforms.List[i].FpcPath)) then begin
            log.i('build > Available platform set to ' + Platforms.List[i].Name);
            SetPlatform(Platforms.List[i].Name);
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

procedure dvUnitNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   ReplaceDirSeparators(currentUnit);
   build.Units.Add(getBasePath() + currentUnit);
end;

procedure dvIncludeNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   ReplaceDirSeparators(currentInclude);
   build.Includes.Add(getBasePath() + currentInclude);
end;

procedure dvNotifyBasePath({%H-}p: PDVar; {%H-}what: longword);
begin
   FileUtils.NormalizePathEx(string(p^.Variable^));
end;

procedure dvPlatformNotify({%H-}p: PDVar; {%H-}what: longword);
var
   platform: TBuildPlatform;

begin
   platform.Initialize(platform);
   platform.Name := currentPlatform;

   build.Platforms.Add(platform);
   temporaryPlatform := @build.Platforms.List[build.Platforms.n - 1];
   SetupDVars();
end;

procedure dvCPUNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   if(cpuBits = '64') then
      temporaryPlatform^.x64 := True;
end;

procedure dvFPCPathNotify({%H-}p: PDVar; {%H-}what: longword);
begin
   FileUtils.NormalizePathEx(string(p^.Variable^));
end;

procedure libOptimizationLevelsNotify({%H-}p: PDVar; {%H-}what: longword);
var
   i: loopint;
   optimizationLevels: TAnsiStringArray;

begin
   optimizationLevels := strExplode(libOptimizationLevels, ',');

   if(Length(optimizationLevels) > 0) then begin
      for i := 0 to High(optimizationLevels) do begin
         temporaryPlatform^.OptimizationLevels.Add(optimizationLevels[i]);
      end;
   end;
end;

INITIALIZATION
   build.writeLog := true;
   build.configPath := 'default';

   build.dvgLocation := dvar.RootGroup;
   build.dvgLocation.Add(dvConfigLocation, 'location', dtcSTRING, @build.ConfigPath);

   build.Units.Initialize(build.Units);
   build.Includes.Initialize(build.Includes);
   build.Symbols.Initialize(build.Symbols);
   build.Platforms.Initialize(build.Platforms);
   build.OptimizationLevels.Initialize(build.OptimizationLevels);

   { CONFIGURATION }
   build.dvgConfig := dvar.RootGroup;

   build.dvgConfig.Add(dvPlatform, 'platform', dtcSTRING, @currentPlatform);
   dvPlatform.pNotify := @dvPlatformNotify;
   build.dvgConfig.Add(dvCPU, 'cpu', dtcSTRING, @cpuBits);
   dvCPU.pNotify := @dvCPUNotify;

   build.dvgConfig.Add(dvLazarusPath, 'lazarus_path', dtcSTRING, @build.LazarusPath);
   build.dvgConfig.Add(dvFPCPath, 'fpc_path', dtcSTRING, @tempPath);
   dvFPCPath.pNotify := @dvFPCPathNotify;
   build.dvgConfig.Add(dvToolsPath, 'tools_path', dtcSTRING, @build.Tools.Path);
   build.dvgConfig.Add(dvBuildPath, 'build_path', dtcSTRING, @build.Tools.Build);
   build.dvgConfig.Add(dvBuildLibOptimizationLevels, 'lib_optimization_levels', dtcSTRING, @libOptimizationLevels);
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


   build.dvgUnits.Add(dvUnitsUnit, 'unit', dtcSTRING, @currentUnit);
   dvUnitsUnit.pNotify := @dvUnitNotify;
   build.dvgUnits.Add(dvUnitsInclude, 'include', dtcSTRING, @currentInclude);
   dvUnitsInclude.pNotify := @dvIncludeNotify;

   CreateDefaultPlatform();
END.

