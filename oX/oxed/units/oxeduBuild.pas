{
   oxeduBuild, oxed build system
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuild;

INTERFACE

   USES
      sysutils, uStd, uLog, uLPI, StringUtils, uTiming,
      uFileUtils, uFile, ufUtils,
      {build}
      uFPCHelpers, uPasSourceHelper,
      uBuild, uBuildInstalls, uBuildExec, uBuildConfiguration, uBuildLibraries, uBuildFPCConfig,
      {app}
      uApp, appuActionEvents,
      {ox}
      oxuThreadTask, oxuFeatures, oxuRenderer, oxeduEditorPlatform,
      {oxed}
      uOXED, oxeduConsole, oxeduPackageTypes, oxeduPackage, oxeduProject,
      oxeduPlatform, oxeduTasks, oxeduSettings,
      oxeduAppInfo,oxeduProjectScanner;

CONST
   OXED_BUILD_3RDPARTY_PATH = '3rdparty';

TYPE
   oxedTBuildTaskType = (
      {quick recode task (compile)}
      OXED_BUILD_TASK_RECODE,
      {rebuilds all the code}
      OXED_BUILD_TASK_REBUILD,
      {cleans up any temporary files}
      OXED_BUILD_TASK_CLEANUP,
      {recreates required project files}
      OXED_BUILD_TASK_RECREATE,
      {builds a standalone project}
      OXED_BUILD_TASK_STANDALONE,
      {recreates third party units}
      OXED_BUILD_TASK_REBUILD_THIRD_PARTY
   );

   oxedTBuildTarget = (
      OXED_BUILD_LIB,
      OXED_BUILD_STANDALONE
   );

   oxedTBuildMechanism = (
      OXED_BUILD_VIA_FPC,
      OXED_BUILD_VIA_LAZ
   );

   { oxedTBuildTask }

   oxedTBuildTask = class(oxedTTask)
      constructor Create(); override;
      procedure Run(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   { oxedTBuildGlobal }

   oxedTBuildGlobal = record
      {called before build starts, to prepare everything}
      OnPrepare,
      {called when build is done}
      OnDone: TProcedures;

      BuildType: oxedTBuildTaskType;
      BuildTarget: oxedTBuildTarget;
      BuildStart: TDateTime;
      BuildArch: oxedTPlatformArchitecture;
      BuildMechanism: oxedTBuildMechanism;

      {properties of the current build task, determined based on Build* settings}
      Props: record
         {source file used for build}
         Source,
         {config file used to build the source (an lpi or fpc config file)}
         ConfigFile: StdString;
      end;

      Features: oxTFeaturePDescriptorList;

      {is there a task currently running}
      Task: oxedTBuildTask;
      {should we include third party units in the current build}
      IncludeThirdParty,
      {indicates to run after a project scan has been done}
      RunAfterScan: boolean;
      {what task type to run after scan}
      RunAfterScanTaskType: oxedTBuildTaskType;

      {where we output our stuff}
      TargetPath,
      {where we output temporary files in order to make a build}
      WorkArea: string;

      class procedure Initialize(); static;
      class procedure Deinitialize(); static;

      {tells whether the build system is enabled and functional}
      function BuildEnabled(): boolean;
      {tells whether the project is currently buildable}
      function Buildable(ignoreRunning: boolean = false): boolean;
      {get a list of features for this build}
      function GetFeatures(): oxTFeaturePDescriptorList;
      {are we building a library}
      function IsLibrary(): boolean;

      {recreate project files (force if you want to force an update)}
      class function Recreate(force: boolean = false): boolean; static;
      {recreate project config file (lpi or fpc config)}
      class function RecreateConfig(whatFor: oxedTBuildMechanism; force: boolean = false): boolean; static;
      {recreate all project files (for laz or fpc)}
      class function RecreateProjectFiles(whatFor: oxedTBuildMechanism): boolean; static;
      {run the build process}
      procedure RunBuild();
      {clean up resources at the end of a build}
      procedure DoneBuild();
      {copy the built executable to target path}
      procedure MoveExecutable();
      {copy required run-time libraries for this build}
      procedure CopyLibraries();

      {run cleanup in a task}
      class procedure BuildStandaloneTask(arch: oxedTPlatformArchitecture); static;

      {run currently set build task (should only be called internally)}
      procedure RunTask();

      {run a task of the specified type and architecture}
      procedure StartTask(taskType: oxedTBuildTaskType; architecture: oxedTPlatformArchitecture);
      {run a task of the specified type}
      procedure StartTask(taskType: oxedTBuildTaskType);

      {setup the required build platform}
      function SetupPlatform(): boolean;
      {get target path for current target}
      function GetTargetPath(): StdString;
      {get path for the working area}
      function GetWorkingAreaPath(): StdString;
      {get path for the working area}
      function GetPlatformPath(const base: StdString): StdString;
      {get the target executable file name}
      function GetTargetExecutableFileName(): StdString;
      {get lpi filename based on current target}
      function GetFPCConfigFilename(): StdString;
      {get lpi filename based on current target}
      function GetLPIFilename(): StdString;

      {Reset build targets and options. Should be called after a build so the next one doesn't use leftover settings.}
      procedure Reset();
   end;

VAR
   oxedBuild: oxedTBuildGlobal;

IMPLEMENTATION

function CompareAndReplace(const source, target: StdString): boolean;
begin
   Result := fUtils.CompareAndReplace(source, target);

   if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_NO_CHANGE) then
      log.v('No change for ' + target + ', from: ' + source)
   else if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_UPDATE) then
      log.v('Updated ' + target + ', from: ' + source)
   else if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_CREATE) then
      log.v('Created ' + target + ', from: ' + source)
   else if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_NO_SOURCE) then
      log.e('Update from file not found: ' + source);
end;


{ TBuildTask }

constructor oxedTBuildTask.Create();
begin
   inherited Create;

   Name := 'Build';
   TaskType := oxedTBuildTask;
end;

procedure oxedTBuildTask.Run();
begin
   inherited Run;

   oxedBuild.RunTask();
end;

procedure oxedTBuildTask.ThreadStart();
begin
   inherited;

   oxedBuild.OnPrepare.Call();
end;

procedure oxedTBuildTask.ThreadDone();
begin
   inherited;

   oxedBuild.OnDone.Call();
end;

procedure buildInitialize();
var
   ok: boolean;

procedure fail(const what: StdString);
begin
   oxedConsole.e(what);
   ok := false;
end;

begin
   build.Initialize();
   lpi.Initialize();

   log.i('Done with build system initialization');

   ok := true;

   if(not oxedBuild.BuildEnabled()) then
      fail('Build system failed to initialize. You will not be able to run the project.');

   if(not lpi.IsInitialized()) then
      fail('LPI system failed to initialize. Cannot create project lpi files.');

   if(lpi.Initialized and build.Initialized) then begin
      if(not oxedBuild.SetupPlatform()) then
         fail('Could not setup fpc/lazarus to use with editor');
   end;

   if(not ok) then
      fail('Failed to initialize build system');
end;

{ oxedTBuildGlobal }

class procedure oxedTBuildGlobal.Initialize();
begin
   buildInitialize();

   oxedBuild.Task := oxedTBuildTask.Create();
   oxedBuild.Task.EmitAllEvents();
end;

class procedure oxedTBuildGlobal.Deinitialize();
begin
   FreeObject(oxedBuild.Task);
end;

function oxedTBuildGlobal.BuildEnabled(): boolean;
begin
   Result := build.Initialized and lpi.IsInitialized();
end;

function oxedTBuildGlobal.Buildable(ignoreRunning: boolean): boolean;
var
   count: loopint;

begin
   if(not ignoreRunning) then
      count := oxedTasks.Running(nil)
   else
      count := oxedTasks.Running(nil, oxedTBuildTask);

   Result := count > 0;

   Result := (not Result) and oxedBuild.BuildEnabled() and oxedProjectValid() and (not oxedProject.Running);
end;

function oxedTBuildGlobal.GetFeatures(): oxTFeaturePDescriptorList;
var
   i: loopint;
   feature: oxPFeatureDescriptor;
   lib: boolean;

begin
   Result.Initialize(Result);
   lib := IsLibrary();

   for i := 0 to oxFeatures.List.n - 1 do begin
      feature := @oxFeatures.List.List[i];

      if(oxFeatures.IsSupportedFeature(feature^, BuildInstalls.CurrentPlatform^.OS, isLibrary)) then begin
         if(lib) then begin
            {skip renderer features as we'll include only a single renderer}
            if(pos('renderer.', feature^.Name) = 1) then
               continue;

            {skip if the feature cannot work in library mode}
            if(not feature^.IsEnabled('library')) then
               continue;

            {console needs to be enabled}
            if(feature^.Name = 'feature.console') and (not oxedProject.Session.EnableConsole) then
               continue;
         end;

         Result.Add(feature);
      end;
   end;

   if(lib) then begin
      {only include renderer we need}
      feature := oxFeatures.Find(oxRenderer.Id);
      assert(feature <> nil, 'Renderer ' + oxRenderer.Id +  ' feature must never be nil');
      Result.Add(feature);
   end;
end;

function oxedTBuildGlobal.IsLibrary(): boolean;
begin
   Result := BuildTarget <> OXED_BUILD_STANDALONE;
end;

function getRelativePath(const basePath: StdString; const unitPath: StdString): StdString;
begin
   Result := ExtractRelativepath(oxedBuild.WorkArea, basePath + unitPath);
end;

function getAbsolutePath(const basePath: StdString; const unitPath: StdString): StdString;
begin
   Result := basePath + unitPath;
end;

function getSymbols(): TSimpleStringList;
var
   i: loopint;

begin
   TSimpleStringList.Initialize(Result);

   Result.Add('-dOXED');
   Result.Add('-dOX_NO_DEFAULT_FEATURES');

   {$IFDEF OX_DEBUG}
   Result.Add('-dOX_DEBUG');
   Result.Add('-dDEBUG');
   {$ENDIF}

   if(oxedProject.Session.DebugResources) then
      Result.Add('-dOX_RESOURCE_DEBUG');

   {$IFDEF NO_THREADS}
   if(oxedBuild.IsLibrary()) then
      Result.Add('-dNO_THREADS');
   {$ENDIF}

   for i := 0 to oxedBuild.Features.n - 1 do begin
      Result.Add('-d' + oxedBuild.Features.List[i]^.Symbol);
   end;

   if(oxedBuild.IsLibrary()) then begin
      Result.Add('-dLIBRARY');
      Result.Add('-dOX_LIBRARY');
   end;
end;

procedure lpiLoaded(var f: TLPIFile);
var
   i: loopint;
   relativePath: string;
   symbols: TSimpleStringList;

procedure processPackage(var p: oxedTPackage; const path: StdString);
var
   idx: loopint;

begin
   for idx := 0 to p.UnitPaths.n - 1 do begin
      relativePath := getRelativePath(path, p.UnitPaths.List[idx]);
      f.AddUnitPath(relativePath);
   end;

   for idx := 0 to p.IncludePaths.n - 1 do begin
      relativePath := getRelativePath(path, p.IncludePaths.List[idx]);
      f.AddIncludePath(relativePath);
   end;
end;

begin
   if(build.IncludeDebugInfo) then begin
      oxedConsole.w('Including debug info');
      f.AddCustomOption('-g');
   end;

   f.SetTitle(oxedProject.Name);
   f.compiler.applyConventions := false;

   if(oxedBuild.BuildType <> OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then begin
      processPackage(oxedProject.MainPackage, oxedProject.Path);

      for i := 0 to oxedProject.Packages.n - 1 do begin
         processPackage(oxedProject.Packages.List[i], oxedProject.GetPackagePath(oxedProject.Packages.List[i]));
      end;
   end;

   symbols := getSymbols();

   for i := 0 to symbols.n - 1 do begin
      f.AddCustomOption(symbols.List[i]);
   end;

   f.SetValue(f.compiler.targetFilename, ExtractFileName(oxedBuild.GetTargetExecutableFileName()));
end;

VAR
   previousBuildUnits: TSimpleStringList;

procedure setupBuildUnits();
var
   i: loopint;
   thirdparty: string;

begin
   previousBuildUnits := build.Units;
   build.Units.Dispose();

   thirdparty := OXED_BUILD_3RDPARTY_PATH + DirectorySeparator;

   for i := 0 to previousBuildUnits.n - 1 do begin
      if(oxedBuild.IncludeThirdParty or (pos(thirdparty, previousBuildUnits.List[i]) = 0)) then
         build.Units.Add(previousBuildUnits.List[i]);
   end;
end;

procedure restoreBuildUnits();
begin
   build.Units.Dispose();
   build.Units := previousBuildUnits;
end;

function RecreateLPI(): boolean;
var
   context: TLPIContext;
   fnTemp,
   fn,
   source, lpifn: String;

begin
   ZeroOut(context, SizeOf(context));

   context.Loaded := @lpiLoaded;

   setupBuildUnits();

   source := oxedBuild.Props.Source;
   lpifn := oxedBuild.GetLPIFilename();

   context.Target := ExtractAllNoExt(source);

   fnTemp := oxedBuild.WorkArea + '-Temp-' + source;
   fn := oxedBuild.WorkArea + lpifn;

   lpi.Create(fnTemp, @context);

   if(lpi.Error = 0) then
      CompareAndReplace(lpi.OutFileName, fn);

   restoreBuildUnits();

   Result := lpi.Error = 0;
end;

procedure InsertPackageIntoConfig(var config: TBuildFPCConfiguration; var package: oxedTPackage; const path: StdString);
var
   i: loopint;

begin
   if(package.IsEmpty()) then
      exit;

   config.Add('');
   if(@package <> @oxedProject.MainPackage) then
      config.Add('# Package: ' + package.Name)
   else
      config.Add('# Project: ' + package.Name);

   config.Add('# Path: ' + path);
   config.Add('');

   for i := 0 to package.UnitPaths.n - 1 do begin;
      config.Add('-Fu' + getAbsolutePath(path, package.UnitPaths.List[i]));
   end;

   for i := 0 to package.IncludePaths.n - 1 do begin;
      config.Add('-Fi' + getAbsolutePath(path, package.IncludePaths.List[i]));
   end;
end;

procedure InsertPackagesIntoConfig(var config: TBuildFPCConfiguration);
var
   i: loopint;

begin
   InsertPackageIntoConfig(config, oxedProject.MainPackage, oxedProject.Path);

   for i := 0 to oxedProject.Packages.n - 1 do begin
      InsertPackageIntoConfig(config, oxedProject.Packages.List[i], oxedProject.GetPackagePath(oxedProject.Packages.List[i]));
   end;
end;

function RecreateFPCConfig(): boolean;
var
   fn: StdString;
   config: TBuildFPCConfiguration;
   symbols: TSimpleStringList;

begin
   TBuildFPCConfiguration.Initialize(config);
   config.Construct();

   InsertPackagesIntoConfig(config);

   config.Add('');

   symbols := getSymbols();
   config.Add(symbols);

   fn := oxedBuild.WorkArea + oxedBuild.Props.ConfigFile;

   Result := config.WriteFile(fn);

   if(not Result) then
      log.e('Failed to write fpc config file for project: ' + fn)
   else
      log.v('Created fpc config file for project: ' + fn);
end;

function getSourceHeader(includeFunctional: boolean = true): TAppendableString;
var
   i: loopint;

begin
   Result := oxedAppInfo.GetSourceHeader(false);

   if(oxedBuild.Features.n > 0) then begin
      Result.Add(LineEnding + '   Features included:');

      for i := 0 to oxedBuild.Features.n - 1 do begin
         Result.Add('   - ' + oxedBuild.Features.List[i]^.Name);
      end;
   end;

   Result.Add('}' + LineEnding);

   if(includeFunctional) then
      Result.Add('{$INCLUDE oxdefines.inc}');
end;

function GetComponentUses(): TAppendableString;
begin
   Result := '';
   Result.Add('{components}');
   Result.Add('oxuPrimitiveModelComponent, oxuCameraComponent');
end;

function isCMEM(): boolean;
begin
   Result := oxed.UseCMEM;
   log.v('Using cmem: ' + sf(Result));
end;

function GetUsesString(): TAppendableString;

   procedure processPackage(var p: oxedTPackage);
   var
      i: loopint;

   begin
      for i := 0 to p.Units.n - 1 do begin
         if(i < p.Units.n - 1) then
            Result.Add('   {%H-}' + p.Units.List[i].Name + ',')
         else
            Result.Add('   {%H-}' + p.Units.List[i].Name);
      end;
   end;

begin
   Result := '';

   if(isCMEM()) then begin
      {include cmem only if not already included by something else}
      Result.Add('{$IF NOT DECLARED(cmem)}cmem,{$ENDIF}');
   end;

   Result.Add('{$INCLUDE oxappuses.inc},');
   Result.Add(GetComponentUses());

   if(oxedProject.MainUnit <> '') then begin
      Result := Result + ',';
      Result.Add('{main unit}');
      Result.Add('    {%H-}' + oxedProject.MainUnit);
   end else begin
      if(oxedProject.MainPackage.Units.n > 0) then begin
         Result := Result + ',';
         Result.Add('{units}');

         processPackage(oxedProject.MainPackage);
      end;
   end;
end;

procedure RecreateProgram();
var
   p: TAppendableString;
   u: TPascalSourceBuilder;

begin
   u.Header := getSourceHeader();
   u.Name := oxedProject.Identifier;
   u.sUses := GetUsesString();
   u.sMain := '{$INCLUDE ./appinfo.inc}';
   u.sMain.Add('oxRun.Go()');

   p := u.BuildProgram();

   FileUtils.WriteString(oxedBuild.WorkArea + oxPROJECT_MAIN_SOURCE, p);
end;

procedure RecreateLib();
var
   p: TAppendableString;
   u: TPascalSourceBuilder;
   fn, target: string;

begin
   u.Name := oxedProject.Identifier;
   u.Header := getSourceHeader();
   u.sUses := GetUsesString() + ',';
   u.sUses.Add('{library}');
   u.sUses.Add('oxuDynlib');
   u.sExports := 'ox_library_load,';
   u.sExports.Add('ox_library_unload,');
   u.sExports.Add('ox_library_version');
   u.sInitialization.Add('{$INCLUDE ./appinfo.inc}');

   p := u.BuildLibrary();

   fn := oxedBuild.WorkArea + oxedBuild.Props.Source + '.tmp';

   FileUtils.WriteString(fn, p);

   target := oxedBuild.WorkArea + oxedBuild.Props.Source;

   if(CompareAndReplace(fn, target)) then
      log.v('Recreated ' + target);
end;

function ShouldRecreate(const fn: string): boolean;
begin
   Result := (FileUtils.Exists(oxedBuild.WorkArea + fn) <= 0) or (oxedBuild.BuildType = OXED_BUILD_TASK_REBUILD);
end;

class function oxedTBuildGlobal.Recreate(force: boolean): boolean;
begin
   oxedProject.RecreateTempDirectory();

   if(not FileUtils.CreateDirectory(build.FPCOptions.UnitOutputDirectory)) then begin
      oxedConsole.e('Failed to create unit output directory: ' + build.FPCOptions.UnitOutputDirectory);
      exit(false);
   end;

   if force or (ShouldRecreate(oxPROJECT_APP_INFO_INCLUDE)) then
      oxedAppInfo.Recreate(oxedBuild.WorkArea + oxPROJECT_APP_INFO_INCLUDE);

   {check if main unit exists}
   if(oxedProject.MainUnit <> '') then begin
      if(oxedProject.MainPackage.Units.Find(oxedProject.MainUnit) = nil) then begin
         oxedConsole.e('Specified main unit ' + oxedProject.MainUnit + ' not found.');
         exit(false);
      end;
   end;

   {recreate library}
   if(force or ShouldRecreate(oxedBuild.Props.Source)) then begin
      if(oxedBuild.BuildTarget = OXED_BUILD_LIB) then
         RecreateLib()
      else
         RecreateProgram();
   end;

   Result := true;
end;

class function oxedTBuildGlobal.RecreateConfig(whatFor: oxedTBuildMechanism; force: boolean): boolean;
begin
   if(force or ShouldRecreate(oxedBuild.Props.ConfigFile)) then begin
      if(whatFor = OXED_BUILD_VIA_FPC) then begin
         if(not RecreateFPCConfig()) then begin
            oxedConsole.e('Failed to create project fpc config file.');
            exit(false);
         end;
      end else begin
         if(not RecreateLPI()) then begin
            oxedConsole.e('Failed to create project library lpi file. lpi error: ' + sf(lpi.Error));
            exit(false);
         end;
      end;
   end;

   Result := true;
end;

class function oxedTBuildGlobal.RecreateProjectFiles(whatFor: oxedTBuildMechanism): boolean;
begin
   Result := Recreate(true);

   if(Result) then begin
      Result := RecreateConfig(whatFor, true);
   end;
end;

procedure BuildLPI();
begin
   if(not oxedBuild.Buildable(true)) then
      exit;

   BuildExec.Laz(oxedBuild.WorkArea + oxedBuild.Props.ConfigFile);
end;

procedure BuildFPC();
var
   i: loopint;
   parameters: TSimpleStringList;

begin
   build.FPCOptions.UseConfig := oxedBuild.WorkArea + oxedBuild.Props.ConfigFile;

   parameters := TBuildFPCConfiguration.GetFPCCommandLineForConfig();
   parameters.Add('-O1');
   parameters.Add('-vewnhi');
   parameters.Add('-l');

   if(build.IncludeDebugInfo) then
      parameters.Add('-gl');

   if(oxedBuild.IsLibrary()) then begin
      parameters.Add('-Cg');
   end;

   if(parameters.n > 0) then begin
      log.Collapsed('FPC parameters for build');

      for i := 0 to parameters.n - 1 do begin
         log.i(parameters.List[i]);
      end;

      log.Leave();
   end;

   BuildExec.Pas(oxedBuild.WorkArea + oxedBuild.Props.Source, @parameters);
end;

procedure FailBuild(const reason: StdString);
begin
   oxedBuild.DoneBuild();
   oxedConsole.e('Failed build: ' + reason);
end;

procedure ExecuteBuild();
var
   previousRedirect: boolean;

begin
   BuildExec.ResetOutput();

   previousRedirect := BuildExec.Output.Redirect;
   BuildExec.Output.Redirect := true;

   if(oxedBuild.BuildMechanism = OXED_BUILD_VIA_FPC) then
      BuildFPC()
   else
      BuildLPI();

   BuildExec.Output.Redirect := previousRedirect;
end;

function createPath(const name, path: StdString): boolean;
begin
   if(not FileUtils.DirectoryExists(path)) then begin
      if(ForceDirectories(path)) then begin
         log.v('Created ' + name + ' path: ' + path)
      end else begin
         FailBuild('Failed to create ' + name + ' path: ' + path);
         exit(false);
      end;
   end;

   Result := true;
end;

procedure oxedTBuildGlobal.RunBuild();
var
   modeString,
   targetString: string;

begin
   log.v('Building platform: ' + BuildArch.GetPlatformString());
   log.v('Building into: ' + TargetPath);
   log.v('Working area: ' + WorkArea);

   if(oxed.UseHeapTrace) and (IsLibrary()) then
      oxedConsole.w('OXED built with heaptrc included, running library may be unstable');

   assert(TargetPath <> '', 'Failed to set target path for build');
   assert(WorkArea <> '', 'Failed to set working area for build');

   if(BuildType <> OXED_BUILD_TASK_STANDALONE) then begin
      {if we're missing target path, rebuild}
      if(not FileUtils.DirectoryExists(TargetPath)) then
         BuildType := OXED_BUILD_TASK_REBUILD;
   end else begin
      {remove target path}
      if(FileUtils.DirectoryExists(TargetPath)) then
         FileUtils.RmDir(TargetPath);

      {remove work area}
      if(FileUtils.DirectoryExists(WorkArea)) then
         FileUtils.RmDir(WorkArea);
   end;

   createPath('work area', WorkArea);
   createPath('target', TargetPath);

   modeString := 'unknown';
   if(BuildType = OXED_BUILD_TASK_REBUILD) then
      modeString := 'rebuild'
   else if(BuildType = OXED_BUILD_TASK_RECODE) then
      modeString := 'recode'
   else if(BuildType = OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then
      modeString := 'rebuild third party'
   else if(BuildType = OXED_BUILD_TASK_STANDALONE) then
      modeString := 'build';

   if(IsLibrary()) then
      targetString := 'lib'
   else
      targetString := 'standalone';

   oxedConsole.i(modeString + ' started (' + targetString + ')');

   if(not Recreate()) then begin
      FailBuild('Failed to recreate project files');
      exit;
   end;

   if(not RecreateConfig(BuildMechanism)) then begin
      FailBuild('Failed to recreate project config files');
      exit;
   end;

   if(IsLibrary()) then begin
      {check if used fpc version matches us}
      if(pos(FPC_VERSION, BuildInstalls.CurrentPlatform^.Version) <> 1) then begin
         oxedConsole.e('Library fpc version mismatch. Got ' + BuildInstalls.CurrentPlatform^.Version + ' but require ' + FPC_VERSION);
         exit;
      end;
   end;

   ExecuteBuild();

   if(BuildExec.Output.Success) then begin
      oxedConsole.k(modestring + ' success (elapsed: ' + BuildStart.ElapsedfToString() + 's)');

      MoveExecutable();
      CopyLibraries();
   end else
      oxedConsole.e(modestring + ' failed (elapsed: ' + BuildStart.ElapsedfToString() + 's)');

   {if successful rebuild, we've made an initial build}
   oxedProject.Session.InitialBuildDone := true;

   {cleanup}
   DoneBuild();
end;

procedure oxedTBuildGlobal.DoneBuild();
begin
   Features.Dispose();
end;

procedure oxedTBuildGlobal.MoveExecutable();
var
   source,
   destination: StdString;

begin
   if(BuildTarget <> OXED_BUILD_STANDALONE) then
      exit;

   source := BuildExec.Output.ExecutableName;
   destination := TargetPath + ExtractFileName(BuildExec.Output.ExecutableName);

   {remove destination first}
   FileUtils.Erase(destination);

   {move the file}
   if(RenameFile(source, destination)) then
      log.v('Moving: ' + source + ' to ' + destination)
   else
      FailBuild('Failed to move: ' + source + ' to ' + destination);

end;

procedure oxedTBuildGlobal.CopyLibraries();
begin
   if(BuildTarget <> OXED_BUILD_STANDALONE) then
      exit;

   {$IFDEF WINDOWS}
   buildLibraries.Target := TargetPath;

   buildLibraries.CopyLibrary('oal_soft.dll', 'openal32.dll');
   buildLibraries.CopyLibrary('freetype-6.dll');
   buildLibraries.CopyLibrary('zlib1.dll');
   {$ENDIF}
end;

procedure DoCleanup();
begin
   if(FileUtils.DirectoryExists(oxedBuild.WorkArea)) then begin
      if(FileUtils.RmDir(oxedBuild.WorkArea)) then
         oxedConsole.i('Cleanup finished')
      else
         oxedConsole.w('Failed to remove temporary files');
   end else
      oxedConsole.i('Seems to be already clean');
end;


class procedure oxedTBuildGlobal.BuildStandaloneTask(arch: oxedTPlatformArchitecture);
begin
   oxedBuild.BuildArch := arch;
   oxedBuild.StartTask(OXED_BUILD_TASK_STANDALONE);
end;

procedure RebuildThirdParty();
var
   previousThirdParty: boolean;

begin
   previousThirdParty := oxedBuild.IncludeThirdParty;
   oxedBuild.IncludeThirdParty := true;
   build.Options.Rebuild := true;
   oxedBuild.RunBuild();
   oxedProject.Session.ThirdPartyBuilt := true;
   oxedBuild.IncludeThirdParty := previousThirdParty;
end;

procedure RecreateAll();
begin
   log.i('Recreating project files');

   {recreate general files}
   oxedBuild.Recreate(true);

   {recreate fpc config files}
   oxedBuild.RecreateConfig(OXED_BUILD_VIA_FPC, true);

   {recreate laz config files}
   oxedBuild.RecreateConfig(OXED_BUILD_VIA_LAZ, true);
end;

procedure oxedTBuildGlobal.RunTask();
begin
   if(not oxedBuild.Buildable(true)) or (not oxedProject.Valid()) then begin
      Reset();
      exit;
   end;

   BuildStart := Now;

   build.ResetOptions();
   build.Options.IsLibrary := IsLibrary();

   {determine if we need third party units}
   oxedBuild.IncludeThirdParty := (not oxedProject.Session.ThirdPartyBuilt) or oxedProject.Session.IncludeThirdPartyUnits;
   log.v('Third party units included: ' + sf(oxedBuild.IncludeThirdParty));

   {rebuild instead of recode if initial build not done}
   if(BuildType = OXED_BUILD_TASK_RECODE) and (not oxedProject.Session.InitialBuildDone) and (oxedSettings.RequireRebuildOnOpen) then begin
      oxedConsole.i('Rebuild instead of recode on initial build');
      BuildType := OXED_BUILD_TASK_REBUILD;
   end;

   if(IsLibrary()) then
      Props.Source := oxPROJECT_LIB_SOURCE
   else
      Props.Source := oxPROJECT_MAIN_SOURCE;

   if(oxedBuild.BuildMechanism = OXED_BUILD_VIA_FPC) then
      props.ConfigFile := GetFPCConfigFilename()
   else
      Props.ConfigFile := GetLPIFilename();

   TargetPath := GetTargetPath();
   WorkArea := GetWorkingAreaPath();
   Features := GetFeatures();

   {$IFOPT D+}
   build.IncludeDebugInfo := true;
   {$ELSE}
   build.IncludeDebugInfo := false;
   {$ENDIf}

   build.TargetCPU := BuildArch.Architecture;
   build.TargetOS := oxedTPlatform(BuildArch.PlatformObject).OS;
   build.FPCOptions.UnitOutputDirectory := oxedBuild.WorkArea  + 'lib';

   if(BuildType = OXED_BUILD_TASK_RECODE) then begin
      build.Options.Rebuild := false;
      RunBuild();
   end else if(BuildType = OXED_BUILD_TASK_REBUILD) then begin
      build.Options.Rebuild := true;
      RunBuild();
   end else if(BuildType = OXED_BUILD_TASK_CLEANUP) then
      DoCleanup()
   else if(BuildType = OXED_BUILD_TASK_RECREATE) then begin
      RecreateAll();
   end else if(BuildType = OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then begin
      RebuildThirdParty();
   end else if(BuildType = OXED_BUILD_TASK_STANDALONE) then begin
      build.Options.Rebuild := true;
      RunBuild();
   end;

   Reset();
   log.v('oxed > Build task done');
end;

procedure oxedTBuildGlobal.StartTask(taskType: oxedTBuildTaskType; architecture: oxedTPlatformArchitecture);
begin
   BuildArch := architecture;
   StartTask(taskType);
end;

procedure oxedTBuildGlobal.StartTask(taskType: oxedTBuildTaskType);
begin
   if(not oxedBuild.Buildable(true)) or (not oxedProject.Valid()) then begin
      Reset();
      exit;
   end;

   assert(BuildArch <> nil, 'Build architecture not set before StartTask()');

   RunAfterScan := false;

   if(not oxedProject.Session.InitialScanDone) and (taskType <> OXED_BUILD_TASK_CLEANUP) then begin
      RunAfterScan := true;
      RunAfterScanTaskType := taskType;

      {only run scan if one already not running}
      if(not oxTThreadTask.IsRunning(oxedProjectScanner.Task)) then
         oxedProjectScanner.RunTask();

      exit;
   end;

   BuildType := taskType;

   Task.Start();
end;

function oxedTBuildGlobal.SetupPlatform(): boolean;
var
   platform: PBuildPlatform;
   laz: PBuildLazarusInstall;

begin
   Result := false;

   if(IsLibrary()) then begin
      platform := BuildInstalls.FindPlatform(build.BuiltWithTarget, build.BuiltWithVersion);

      if(platform = nil) then begin
         oxedConsole.e('Failed to find suitable compiler for ' + build.BuiltWithTarget + ' and FPC ' + FPC_VERSION);
         exit(false);
      end;

      BuildInstalls.SetPlatform(platform^.Name);

      laz := BuildInstalls.FindLazarusInstallForPlatform(platform);

      if(laz <> nil) then
         BuildInstalls.SetLazarusInstall(laz^.Name)
      else begin
         log.w('Failed to find a lazarus install for fpc: ' + platform^.Name);
         BuildInstalls.GetLazarus();
      end;

      log.v('Using platform: ' + BuildInstalls.CurrentPlatform^.Name + ', fpc ' + BuildInstalls.CurrentPlatform^.Version);
      log.v('Using lazbuild: ' + BuildInstalls.CurrentLazarus^.Name + ', at ' + BuildInstalls.CurrentLazarus^.Path);

      exit(true);
   end;
end;

function oxedTBuildGlobal.GetTargetPath(): StdString;
begin
   Result := GetPlatformPath(oxedProject.TempPath + 'build');
end;

function oxedTBuildGlobal.GetWorkingAreaPath(): StdString;
begin
   Result := GetPlatformPath(oxedProject.TempPath + 'build-temp');
end;

function oxedTBuildGlobal.GetPlatformPath(const base: StdString): StdString;
begin
   if(BuildTarget = OXED_BUILD_LIB) then begin
      {we're building for editor}
      if(BuildArch = oxedEditorPlatform.Architecture) then
         Result := oxedProject.TempPath
      else
         Result := oxedProject.TempPath + BuildArch.GetPlatformString() + DirectorySeparator;
   end else
      Result := IncludeTrailingPathDelimiterNonEmpty(base) + oxedBuild.BuildArch.GetPlatformString() + DirectorySeparator;
end;

function oxedTBuildGlobal.GetTargetExecutableFileName(): StdString;
begin
   Result := WorkArea;

   if(IsLibrary()) then
      Result := Result + build.GetExecutableName(oxPROJECT_LIBRARY_NAME, true)
   else
      Result := Result + build.GetExecutableName(oxedProject.ShortName, false);
end;

function oxedTBuildGlobal.GetFPCConfigFilename(): StdString;
begin
   if(IsLibrary()) then
      Result := oxPROJECT_LIB_FPC_CFG
   else
      Result := oxPROJECT_MAIN_FPC_CFG;
end;

function oxedTBuildGlobal.GetLPIFilename(): StdString;
begin
   if(IsLibrary()) then
      Result := oxPROJECT_LIB_LPI
   else
      Result := oxPROJECT_MAIN_LPI;
end;

procedure oxedTBuildGlobal.Reset();
begin
   BuildType := OXED_BUILD_TASK_RECODE;
   BuildTarget := OXED_BUILD_LIB;
   BuildArch := oxedEditorPlatform.Architecture;
   BuildMechanism := OXED_BUILD_VIA_FPC;
end;

procedure CreateSourceFile(const fn: string);
var
   p: TAppendableString;
   u: TPascalSourceBuilder;

begin
   ZeroOut(u, SizeOf(u));

   u.Header := getSourceHeader();
   u.Name := 'main';

   p := u.BuildUnit();

   FileUtils.WriteString(fn, p);
end;

procedure onScanDone();
begin
   if(oxedBuild.RunAfterScan) then begin
      log.v('Run build after scan');
      oxedBuild.StartTask(oxedBuild.RunAfterScanTaskType);
   end;
end;

INITIALIZATION
   oxed.Init.Add('build', @oxedTBuildGlobal.Initialize, @oxedTBuildGlobal.Deinitialize);

   TProcedures.InitializeValues(oxedBuild.OnPrepare);
   TProcedures.InitializeValues(oxedBuild.OnDone);

   oxedBuild.BuildTarget := OXED_BUILD_LIB;

   oxedProjectScanner.OnDone.Add(@onScanDone);

END.
