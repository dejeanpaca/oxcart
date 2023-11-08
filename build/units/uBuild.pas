{
   uBuild
   Copyright (C) 2015. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uBuild;

INTERFACE

   USES
      sysutils, ParamUtils,
      uStd, uLog, uFileUtils, StringUtils, uTiming,
      uFPCHelpers;

CONST
   { build system name }
   SYSTEM_NAME = 'fpbuild';

TYPE

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

      {base oX path}
      RootPath,
      {build configuration path}
      ConfigPath: StdString;

      {fpc target options}
      Target: record
         OS,
         CPU,

         CPUType,
         FPUType,
         BinUtilsPrefix: StdString;
      end;

      {debug information}
      Debug: record
         {include debug information (-g))}
         Include,
         {include line info unit (-gl)}
         LineInfo,
         {include debug information from an external file (-Xg)}
         External,
         {generate debug code for valgrind (-gv)}
         Valgrind,
         {stabs}
         Stabs: boolean;

         {debug information options}
         Information: record
            DwarfSets: boolean;
         end;

         {dwarf debug information level}
         DwarfLevel: loopint;
      end;

      {selected optimization level}
      OptimizationLevel: loopint;

      FPCOptions: record
         {compiler mode}
         CompilerMode: StdString;
         {where to output units (-FU)}
         UnitOutputPath,
         {what fpc config to use for building (@)}
         UseConfig,
         {compiler utilities path (-FF)}
         CompilerUtilitiesPath: StdString;
         {don't use default fpc config file (-n)}
         DontUseDefaultConfig,
         {Allow goto and label (-Sg)}
         AllowGotoAndLabel,
         {Allow C like operators (-Sc)}
         CLikeOperators,
         {Use reference counted strings (ansistrings, -Sh)}
         ReferenceCountedString,
         {Turn on inlining of routines marked as inline (-Si)}
         TurnOnInlining,
         {position independent code (-Cg)}
         PositionIndependentCode: boolean;
      end;

      ExecutableOptions: record
         ExcludeDefaultLibraryPath: boolean;
      end;

      Options: record
         {we're building a library}
         IsLibrary,
         {rebuilds everything}
         Rebuild: boolean;
      end;

      {fpc optimization options}
      Optimization: record
         Level: loopint;
      end;

      Checks: record
         IO,
         Range,
         Overflow,
         Stack,
         Assertions,
         VerifyMethodCalls: boolean;
      end;

      Units,
      Includes,
      Symbols,
      Libraries,
      OptimizationLevels,
      CustomOptions: TSimpleStringList;

      OnInitializeStart,
      OnInitialize,
      OnReinitialize,
      OnDeinitialize,
      OnLoadConfiguration,
      OnSaveConfiguration: TProcedures;

      {initialize the build system}
      procedure Initialize();
      {reinitialize the build system (e.g. after config path change)}
      procedure ReInitialize();
      {deinitialize build}
      procedure DeInitialize();

      {get the semicolon separated includes path from a list of strings relative the base path}
      function GetIncludesPath(const basePath: StdString; const paths: TSimpleStringList): StdString;
      {get the semicolon separated includes path from a list of strings relative the base path, including the existing items}
      function GetIncludesPath(const basePath: StdString; const paths: TSimpleStringList; const existing: StdString): StdString;

      {get an optimization level by name}
      function GetOptimizationLevelByName(const name: StdString): loopint;

      {get all commmand line defined symbol parameters}
      procedure GetSymbolParameters();
      {set default symbols for current platform}
      procedure SetDefaultSymbols();

      {set default values if these were not set through config}
      procedure SetupDefaults();

      {reset all options}
      procedure ResetOptions();

      {get the target name with which the current build was made}
      class function GetBuiltWithTarget(): TFPCPlatformString; static;
      {get the name of an executable}
      function GetExecutableName(const name: StdString; isLibrary: boolean = false): StdString;
   end;

VAR
   build: TBuildSystem;

IMPLEMENTATION

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
   DeInitialize();

   OnReinitialize.Call();
   Initialize();
end;

procedure TBuildSystem.DeInitialize();
begin
   OnDeinitialize.Call();

   Units.Dispose();
   Includes.Dispose();
   Symbols.Dispose();

   Tools.Build := '';
   Tools.Path := '';

   Initialized := false;
end;

procedure TBuildSystem.Initialize();
var
   start: TDateTime;

begin
   if(Initialized) then
      exit;

   start := Now;

   OnInitializeStart.Call();
   OnLoadConfiguration.Call();

   {setup default values if defaults were not overriden}
   SetupDefaults();

   OnInitialize.Call();

   log.v('build > Initialized (Elapsed: ' + start.ElapsedfToString() + 's)');

   Initialized := true;
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

function TBuildSystem.GetOptimizationLevelByName(const name: StdString): loopint;
var
   i: loopint;

begin
   for i := 0 to OptimizationLevels.n - 1 do begin
      if(OptimizationLevels[i] = name) then
         exit(i);
   end;

   Result := -1;
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
   if(VerboseLog) then
      log.v('Build config path: ' + ConfigPath);

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
      if(VerboseLog) then
         log.v('build > auto tools/build defaults for windows');

      Tools.Path := ExpandFileName(IncludeTrailingPathDelimiterNonEmpty(ConfigPath) + '..\tools');
      {$ENDIF}

      FileUtils.NormalizePathEx(Tools.Path);

      if(VerboseLog) then
         log.v('Auto tools path: ' + Tools.Path);
   end else
      log.v('Tools path: ' + Tools.Path);

   if(ConfigPath <> 'default') or (Tools.Build = '') then begin
      Tools.Build := ConfigPath;
      FileUtils.NormalizePathEx(Tools.Build);

      if(VerboseLog) then
         log.v('Auto build path: ' + Tools.Build);
   end;

   RootPath := '';
   if(ConfigPath <> 'default') then
      RootPath := IncludeTrailingPathDelimiterNonEmpty(GetParentDirectory(ConfigPath));
end;

procedure TBuildSystem.ResetOptions();
begin
   Target.OS := '';
   Target.CPU := '';
   Target.CPUType := '';
   Target.FPUType := '';
   Target.BinUtilsPrefix := '';

   Debug.Include := false;
   Debug.LineInfo := false;
   Debug.External := false;
   Debug.DwarfLevel := 0;
   Debug.Stabs := false;
   Debug.Valgrind := false;

   OptimizationLevel := 0;

   Checks.IO := false;
   Checks.Range := false;
   Checks.Overflow := false;
   Checks.Stack := false;
   Checks.Assertions := false;
   Checks.VerifyMethodCalls := false;

   FPCOptions.CompilerMode := 'objfpc';
   FPCOptions.UnitOutputPath := '';
   FPCOptions.UseConfig := '';
   FPCOptions.CompilerUtilitiesPath := '';
   FPCOptions.DontUseDefaultConfig := false;
   FPCOptions.AllowGotoAndLabel := true;
   FPCOptions.CLikeOperators := true;
   FPCOptions.ReferenceCountedString := true;
   FPCOptions.TurnOnInlining := true;
   FPCOptions.PositionIndependentCode := false;

   ExecutableOptions.ExcludeDefaultLibraryPath := false;

   Optimization.Level := 1;

   Libraries.Dispose();

   Options.IsLibrary := false;
   Options.Rebuild := false;

   CustomOptions.Dispose();
end;

class function TBuildSystem.GetBuiltWithTarget(): TFPCPlatformString;
begin
   Result := LowerCase(FPC_TARGETCPU + '-' + FPC_TARGETOS);
end;

function TBuildSystem.GetExecutableName(const name: StdString; isLibrary: boolean): StdString;
begin
   Result := name;

   {$IFDEF WINDOWS}
   if(ExtractFileExt(name) = '') then begin
      if(not isLibrary) then
         Result := name + '.exe'
      else
         Result := name + '.dll';
   end;
   {$ELSE}
   if(isLibrary) then begin
      if(ExtractFileExt(name) = '') then
         Result := 'lib' + name + '.so';
   end;
   {$ENDIF}
end;

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
   TProcedures.Initialize(build.OnInitializeStart);
   TProcedures.Initialize(build.OnInitialize);
   TProcedures.Initialize(build.OnReinitialize);
   TProcedures.Initialize(build.OnDeinitialize);
   TProcedures.Initialize(build.OnLoadConfiguration);
   TProcedures.Initialize(build.OnSaveConfiguration);

   build.ConfigPath := 'default';

   TSimpleStringList.Initialize(build.Units);
   TSimpleStringList.Initialize(build.Includes);
   TSimpleStringList.Initialize(build.Symbols);
   TSimpleStringList.Initialize(build.OptimizationLevels);
   TSimpleStringList.Initialize(build.Libraries);
   TSimpleStringList.Initialize(build.CustomOptions);

   parameters.AddHandler(paramHandler, 'build', '--build-verbose', @processParam);

   { determine our built with target and version }

   build.BuiltWithTarget := TBuildSystem.GetBuiltWithTarget();

   if(Pos('-', FPC_VERSION) > 0) then
      build.BuiltWithVersion := copy(FPC_VERSION, 1, Pos('-', FPC_VERSION))
   else
      build.BuiltWithVersion := FPC_VERSION;
END.
