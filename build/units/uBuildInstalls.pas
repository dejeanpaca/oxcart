{
   uBuildInstalls, handles fpc and lazarus installs for the build system
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uBuildInstalls;

INTERFACE

   USES
      process, sysutils, uLog, uProcessHelpers, uFileUtils,
      uStd, uFPCHelpers, uBuild;

TYPE
   PBuildPlatform = ^TBuildPlatform;

   { TBuildPlatform }
   {per platform configuration}
   TBuildPlatform = record
      Name,
      Path,
      ConfigPath,
      Executable,
      {fpc version}
      Version: StdString;

      CPU,
      OS: StdString;
      Platform: TFPCPlatformString;

      OptimizationLevels: TSimpleStringList;

      class procedure Initialize(out p: TBuildPlatform); static;
      function GetName(): StdString;
      function GetExecutablePath(): StdString;

      procedure SetPlatform(newPlatform: TFPCPlatformString);
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
      Name,
      Path,
      ConfigPath,
      Version: StdString;

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


   { TBuildSystemInstalls }

   TBuildSystemInstalls = record
      public

      {Configurations for various platforms (first one is default one for the current system), for cross-compiling}
      Platforms: TBuildPlatforms;

      {configurations for various lazarus installs}
      Lazarus: TBuildLazarusInstalls;

      CurrentPlatform: PBuildPlatform;
      CurrentLazarus: PBuildLazarusInstall;
      OptimizationLevels: TSimpleStringList;

      DefaultPlatform: PBuildPlatform;
      DefaultLazarus: PBuildLazarusInstall;

      {initialization start}
      procedure InitializeStart();
      {initialize the build system}
      procedure Initialize();
      {reinitialize the build system (e.g. after config path change)}
      procedure ReInitialize();

      {checks if lazarus is in environment path}
      function LazarusInPathEnv(): boolean;
      {checks if fpc is in environment path}
      function FPCINPathEnv(): boolean;

      {get lazarus executable}
      function GetLazarusExecutable(): StdString;
      function GetLazarusStartExecutable(): StdString;

      {get current platform}
      function GetPlatform(): PBuildPlatform;
      {find platform for specified target and fpc version}
      function FindPlatform(const target: string; const version: string = ''): PBuildPlatform;
      {find platform by name, returns nil if nothing found}
      function FindPlatformByName(const name: StdString): PBuildPlatform;
      {get current lazarus install}
      function GetLazarus(): PBuildLazarusInstall;
      {set current platform by its name}
      function SetPlatform(const name: StdString): Boolean;
      {set lazarus by name}
      function SetLazarusInstall(const name: StdString): Boolean;
      {find lazarus install by name, returns nil if nothing found}
      function FindLazarusInstall(const name: StdString): PBuildLazarusInstall;
      {find lazarus install by platform}
      function FindLazarusInstallForPlatform(platform: PBuildPlatform): PBuildLazarusInstall;
      {get the platform we're compiled with}
      function GetCurrentPlatform(): StdString;

      {test all platforms}
      procedure TestPlatforms();
      {test all lazarus installations}
      procedure TestLazarusInstallations();
      {sets the platform based on what is available}
      procedure SetupAvailablePlatform();
      {sets the lazarus install based on what is available}
      procedure SetupAvailableLazarus();

      {set default values if these were not set through config}
      procedure SetupDefaults();

      {get an optimization level name}
      function GetOptimizationLevelName(level: loopint): StdString;
      {get a human readable optimization level name}
      function GetOptimizationLevelNameHuman(level: loopint): StdString;

      {get process for running an executable}
      function GetProcess(): TProcess;
   end;

VAR
   BuildInstalls: TBuildSystemInstalls;

IMPLEMENTATION

procedure CreateDefaultPlatform();
var
   defaultPlatform: TBuildPlatform;

begin
   defaultPlatform.Initialize(defaultPlatform);
   defaultPlatform.Name := 'default';
   defaultPlatform.Platform := build.GetBuiltWithTarget();

   BuildInstalls.Platforms.Dispose();
   BuildInstalls.Platforms.Add(defaultPlatform);

   BuildInstalls.DefaultPlatform := BuildInstalls.Platforms.GetLast();
end;

procedure CreateDefaultLazarus();
var
   defaultLaz: TBuildLazarusInstall;

begin
   defaultLaz.Initialize(defaultLaz);

   defaultLaz.Name := 'default';
   defaultLaz.FPC := BuildInstalls.FindPlatformByName('default');
   BuildInstalls.Lazarus.Dispose();
   BuildInstalls.Lazarus.Add(defaultLaz);

   BuildInstalls.DefaultLazarus := BuildInstalls.Lazarus.GetLast();
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

function TBuildPlatform.GetExecutablePath(): StdString;
begin
   if(Executable = '') then
      Result := build.GetExecutableName(Path + 'fpc')
   else
      Result := Path + Executable;
end;

procedure TBuildPlatform.SetPlatform(newPlatform: TFPCPlatformString);
begin
   Platform := newPlatform;
   Platform.Separate(CPU, OS);
end;

{ TBuildSystemInstalls }

procedure TBuildSystemInstalls.ReInitialize();
begin
   CurrentLazarus := nil;
   CurrentPlatform := nil;

   Platforms.Dispose();
   Lazarus.Dispose();
end;

procedure TBuildSystemInstalls.InitializeStart();
begin
   CreateDefaultPlatform();
   CreateDefaultLazarus();
end;

procedure TBuildSystemInstalls.Initialize();
begin
   {setup default values if defaults were not overriden}
   SetupDefaults();

   {go through Platforms and find an available platform}
   SetupAvailablePlatform();
   SetupAvailableLazarus();

   TestPlatforms();
   TestLazarusInstallations();
end;

function TBuildSystemInstalls.LazarusInPathEnv(): boolean;
var
   path: StdString;

begin
   path := GetEnvironmentVariable('PATH');
   exit(Pos(DirectorySeparator + 'lazarus', path) <> 0)
end;

function TBuildSystemInstalls.FPCINPathEnv(): boolean;
var
   path: StdString;

begin
   path := GetEnvironmentVariable('PATH');
   exit(Pos(DirectorySeparator + 'fpc', path) <> 0)
end;

function TBuildSystemInstalls.GetLazarusExecutable(): StdString;
begin
   Result := GetLazarus()^.Path + build.GetExecutableName('lazarus');
end;

function TBuildSystemInstalls.GetLazarusStartExecutable(): StdString;
begin
   Result := GetLazarus()^.Path + build.GetExecutableName('startlazarus');
end;

function TBuildSystemInstalls.GetPlatform(): PBuildPlatform;
begin
   Result := CurrentPlatform;

   if(CurrentPlatform = nil) then
      Result := @Platforms.List[0];
end;

function TBuildSystemInstalls.FindPlatform(const target: string; const version: string): PBuildPlatform;
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

function TBuildSystemInstalls.FindPlatformByName(const name: StdString): PBuildPlatform;
begin
   Result := Platforms.FindByName(name);
end;

function TBuildSystemInstalls.GetLazarus(): PBuildLazarusInstall;
begin
   Result := CurrentLazarus;

   if(Result = nil) then
      Result := @Lazarus.List[0];
end;

function TBuildSystemInstalls.SetPlatform(const name: StdString): Boolean;
var
   p: PBuildPlatform;

begin
   p := FindPlatformByName(name);

   if(p <> nil) then begin
      if(CurrentPlatform <> p) then begin
         CurrentPlatform := p;
         log.v('Set platform: ' + CurrentPlatform^.GetName());
      end;

      exit(true);
   end;

   CurrentPlatform := @Platforms.List[0];
   Result := false;
end;

function TBuildSystemInstalls.SetLazarusInstall(const name: StdString): Boolean;
var
   p: PBuildLazarusInstall;

begin
   p := FindLazarusInstall(name);

   if(p <> nil) then begin
      CurrentLazarus := p;
      exit(true);
   end;

   CurrentLazarus := @Lazarus.List[0];
   Result := false;
end;

function TBuildSystemInstalls.FindLazarusInstall(const name: StdString): PBuildLazarusInstall;
begin
   Result := Lazarus.FindByName(name);
end;

function TBuildSystemInstalls.FindLazarusInstallForPlatform(platform: PBuildPlatform): PBuildLazarusInstall;
begin
   Result := Lazarus.FindByPlatform(platform);
end;

function TBuildSystemInstalls.GetCurrentPlatform(): StdString;
begin
   Result := LowerCase({$I %FPCTARGETOS%});
end;

procedure TBuildSystemInstalls.TestPlatforms();
var
   i: loopint;
   p: PBuildPlatform;
   process: TProcess;

begin
   for i := 0 to Platforms.n - 1 do begin
      p := @Platforms.List[i];

      process := GetProcess();
      process.Executable := build.GetExecutableName(p^.Path + 'fpc');
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

procedure TBuildSystemInstalls.TestLazarusInstallations();
var
   i,
   lineIndex: loopint;
   p: PBuildLazarusInstall;
   process: TProcess;
   strings: TSimpleStringList;

begin
   for i := 0 to Lazarus.n - 1 do begin
      p := @Lazarus.List[i];

      process := GetProcess();
      process.Executable := build.GetExecutableName(p^.Path + 'lazbuild');
      process.Parameters.Add('-v');
      process.Options := process.Options + [poUsePipes];

      try
         process.Execute();

         strings := process.GetOutputStrings(2);

         for lineIndex := 0 to strings.n - 1 do begin
            if(pos('using', strings.List[lineIndex]) = 0) then
               p^.Version := strings.List[lineIndex];
         end;

         log.v('Found lazbuild(' + p^.Version + ') executable for platform ' + p^.Name + ' at path ' + process.Executable);
      except
         on e: Exception do begin
            log.w('Could not execute lazbuild for ' + p^.Name + ' at path ' + process.Executable);
         end;
      end;

      FreeObject(process);
   end;
end;

procedure TBuildSystemInstalls.SetupAvailablePlatform();
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

procedure TBuildSystemInstalls.SetupAvailableLazarus();
var
   i: loopint;

begin
   if(CurrentLazarus = nil) then begin
      if(Lazarus.n > 0) then
         CurrentLazarus := @Lazarus.List[0]
      else
         exit;
   end;

   {don't touch the current lazarus install if we have one}
   if(not DirectoryExists(CurrentLazarus^.Path)) then begin
      for i := 0 to Lazarus.n - 1 do begin
         if(DirectoryExists(Lazarus.List[i].Path)) then begin
            log.i('build > Available lazarus install set to ' + Lazarus.List[i].Name);
            SetLazarusInstall(Lazarus.List[i].Name);
            exit;
         end;
      end;
   end;
end;

procedure TBuildSystemInstalls.SetupDefaults();
{$IFDEF WINDOWS}
var
   fn: StdString;
{$ENDIF}

begin
   if(DefaultPlatform^.Path = '') then begin
      {$IF DEFINED(LINUX)}
      if(build.VerboseLog) then
         log.v('build > auto fpc defaults for linux');

      DefaultPlatform^.Path := '/usr/bin/';
      {$ELSEIF DEFINED(DARWIN)}
      if(build.VerboseLog) then
         log.v('build > auto fpc defaults for darwin');

      DefaultPlatform^.Path := '/usr/local/bin/';
      {$ELSEIF DEFINED(WINDOWS)}
      fn := 'C:\lazarus\fpc\' + FPC_VERSION + '\bin\' + build.BuiltWithTarget + DirectorySeparator;

      if FileUtils.Exists(fn) <= 0 then begin
         fn := 'C:\fpc\' + FPC_VERSION + '\bin\' + build.BuiltWithTarget + DirectorySeparator;

         if FileUtils.Exists(fn) > 0 then
            DefaultPlatform^.Path := fn;
      end else
         DefaultPlatform^.Path := fn;

      if(build.VerboseLog) then
         log.v('build > auto fpc defaults for windows');
      {$ENDIF}

      if(build.VerboseLog) then
         log.v('build > using auto defaults for fpc platform');
   end;

   if(DefaultLazarus^.Path = '') then begin
      {$IF DEFINED(LINUX)}
      if(build.VerboseLog) then
         log.v('build > auto lazarus defaults for linux');

      DefaultLazarus^.Path := '/usr/bin/';
      {$ELSEIF DEFINED(DARWIN)}
      if(build.VerboseLog) then
         log.v('build > auto lazarus defaults for darwin');

      DefaultLazarus^.Path := '/Developer/lazarus/';
      {$ELSEIF DEFINED(WINDOW)}
      DefaultLazarus^.Path := 'C:\lazarus\';
      {$ENDIF}

      if(build.VerboseLog) then
         log.v('build > using auto defaults for lazarus install');
   end;

   if(DefaultPlatform^.OptimizationLevels.n = 0) then begin
      DefaultPlatform^.OptimizationLevels.Add('none');

      {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86_32)}
      DefaultPlatform^.OptimizationLevels.Add('sse');
      DefaultPlatform^.OptimizationLevels.Add('sse2');
      DefaultPlatform^.OptimizationLevels.Add('sse3');
      {$ENDIF}
   end;
end;

function TBuildSystemInstalls.GetOptimizationLevelName(level: loopint): StdString;
begin
   if(level > 0) and (level <= CurrentPlatform^.OptimizationLevels.n) then
      Result := CurrentPlatform^.OptimizationLevels.List[level - 1]
   else
      Result := '';
end;

function TBuildSystemInstalls.GetOptimizationLevelNameHuman(level: loopint): StdString;
begin
   Result := GetOptimizationLevelName(level);

   if(Result = '') then
      Result := 'none';
end;

function TBuildSystemInstalls.GetProcess(): TProcess;
begin
   Result := TProcess.Create(nil);

   Result.Options := Result.Options + [poWaitOnExit];
end;

procedure initializeStart();
begin
   BuildInstalls.InitializeStart();
end;

procedure initialize();
begin
   BuildInstalls.Initialize();
end;

procedure reinitialize();
begin
   BuildInstalls.ReInitialize();
end;

INITIALIZATION
   BuildInstalls.Platforms.Initialize(BuildInstalls.Platforms);
   BuildInstalls.Lazarus.Initialize(BuildInstalls.Lazarus);

   build.OnReinitialize.Add(@reinitialize);
   build.OnInitializeStart.Add(@initializeStart);
   build.OnInitialize.Add(@initialize);
END.
