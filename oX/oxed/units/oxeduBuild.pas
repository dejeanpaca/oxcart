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
      uFPCHelpers, uBuild, uBuildConfiguration, uBuildLibraries, uPasSourceHelper,
      {app}
      uApp, appuActionEvents,
      {ox}
      oxuThreadTask, oxuFeatures, oxuRenderer,
      {oxed}
      uOXED, oxeduConsole, oxeduPackageTypes, oxeduPackage, oxeduProject,
      oxeduPlatform, oxeduTasks, oxeduActions, oxeduSettings,
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
      OnPrepare: TProcedures;
      {called when build is done}
      OnDone: TProcedures;

      BuildType: oxedTBuildTaskType;
      BuildTarget: oxedTBuildTarget;
      BuildStart: TDateTime;
      BuildArch: oxedTPlatformArchitecture;

      Features: oxTFeaturePDescriptorList;

      {is there a task currently running}
      Task: oxedTBuildTask;
      {should we include third party units in the current build}
      IncludeThirdParty,
      {indicates to run after a project scan has been done}
      RunAfterScan: boolean;
      {what task type to run after scan}
      RunAfterScanTaskType: oxedTBuildTaskType;

      {TODO: Use working area for temporary stuff in a build}

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

      {recreate project files}
      class function Recreate(): boolean; static;
      {run the build process}
      procedure RunBuild();
      {clean up resources at the end of a build}
      procedure DoneBuild();
      {copy the built executable to target path}
      procedure MoveExecutable();
      {copy required run-time libraries for this build}
      procedure CopyLibraries();
      {rebuild the entire project}
      class procedure Rebuild(); static;
      {build the part of project that changed}
      class procedure Recode(); static;
      {cleanup build and other temporary files}
      class procedure Cleanup(); static;
      {cleanup build and other temporary files}
      class procedure RecreateFiles(); static;

      {run a rebuild in a task}
      class procedure RebuildTask(); static;
      {run a recode in a task}
      class procedure RecodeTask(); static;
      {run cleanup in a task}
      class procedure CleanupTask(); static;
      {run recreate in a task}
      class procedure RecreateTask(); static;
      {run cleanup in a task}
      class procedure RebuildThirdPartyTask(); static;
      {run cleanup in a task}
      class procedure BuildStandaloneTask(arch: oxedTPlatformArchitecture); static;

      {run currently set build task}
      procedure RunTask(taskType: oxedTBuildTaskType);

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

   oxedBuild.RunTask(oxedBuild.BuildType);
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
   platform: string;
   lib: boolean;

begin
   Result.Initialize(Result);
   lib := IsLibrary();

   platform := build.GetCurrentPlatform();

   for i := 0 to oxFeatures.List.n - 1 do begin
      feature := @oxFeatures.List.List[i];

      if(oxFeatures.IsSupportedFeature(feature^, platform, isLibrary)) then begin
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

function getRelativePath(const basePath: StdString; const unitFile: oxedTPackageUnit): string;
begin
   Result := ExtractRelativepath(oxedBuild.WorkArea, basePath + ExtractFilePath(unitFile.Path));
end;

procedure recreateSymbols(var f: TLPIFile);
var
   i: loopint;

begin
   for i := 0 to oxedBuild.Features.n - 1 do begin
      f.AddCustomOption('-d' + oxedBuild.Features.List[i]^.Symbol);
   end;
end;

procedure lpiLoadedCommon(var f: TLPIFile);
var
   i: loopint;
   relativePath: string;

procedure processPackage(var p: oxedTPackage; const path: StdString);
var
   idx: loopint;

begin
   for idx := 0 to p.Units.n - 1 do begin
      relativePath := getRelativePath(path, p.Units.List[idx]);
      f.AddUnitPath(relativePath);
   end;

   for idx := 0 to p.IncludeFiles.n - 1 do begin
      relativePath := getRelativePath(path, p.IncludeFiles.List[idx]);
      f.AddIncludePath(relativePath);
   end;
end;

begin
   f.AddCustomOption('-dOXED');
   f.AddCustomOption('-dOX_NO_DEFAULT_FEATURES');

   {$IFDEF OX_DEBUG}
   f.AddCustomOption('-dOX_DEBUG');
   f.AddCustomOption('-dDEBUG');
   {$ENDIF}

   if(oxedProject.Session.DebugResources) then
      f.AddCustomOption('-dOX_RESOURCE_DEBUG');

   {$IFOPT D+}
   oxedConsole.w('Including debug info');
   f.AddCustomOption('-g');
   {$ENDIF}

   if(oxed.UseHeapTrace) then
      oxedConsole.w('OXED built with heaptrc included, running library may be unstable');

   f.SetTitle(oxedProject.Name);
   f.compiler.applyConventions := false;

   if(oxedBuild.BuildType <> OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then begin
      processPackage(oxedProject.MainPackage, oxedProject.Path);

      for i := 0 to oxedProject.Packages.n - 1 do begin
         processPackage(oxedProject.Packages.List[i], oxedProject.GetPackagePath(oxedProject.Packages.List[i]));
      end;
   end;

   recreateSymbols(f);
   f.SetValue(f.compiler.targetFilename, ExtractFileName(oxedBuild.GetTargetExecutableFileName()));
end;

procedure lpiLoaded(var f: TLPIFile);
begin
   lpiLoadedCommon(f);
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

procedure libLPILoaded(var f: TLPIFile);
begin
   lpiLoadedCommon(f);

   f.AddCustomOption('-dLIBRARY');
   f.AddCustomOption('-dOX_LIBRARY');
end;

function RecreateLPI(lib: boolean): boolean;
var
   context: TLPIContext;
   fnTemp,
   fn,
   source, lpifn: String;

begin
   ZeroOut(context, SizeOf(context));
   if(lib) then
      context.Loaded := @libLPILoaded
   else
      context.Loaded := @lpiLoaded;

   setupBuildUnits();

   if(lib) then begin
      source := oxPROJECT_LIB_SOURCE;
      lpifn := oxPROJECT_LIB_LPI;
   end else begin
      source := oxPROJECT_MAIN_SOURCE;
      lpifn := oxPROJECT_MAIN_LPI;
   end;

   context.Target := ExtractAllNoExt(source);

   fnTemp := oxedBuild.WorkArea + '-Temp-' + source;
   fn := oxedBuild.WorkArea + lpifn;

   lpi.Create(fnTemp, @context);

   if(lpi.Error = 0) then
      CompareAndReplace(lpi.OutFileName, fn);

   restoreBuildUnits();

   Result := lpi.Error = 0;
end;

function getSourceHeader(includeFunctional: boolean = true): TAppendableString;
var
   i: loopint;

begin
   Result := oxedAppInfo.GetSourceHeader(false);

   Result.Add(LineEnding + '   Features included:');

   for i := 0 to oxedBuild.Features.n - 1 do begin
      Result.Add('   - ' + oxedBuild.Features.List[i]^.Name);
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

   if(isCMEM()) then
      Result.Add('cmem,');

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

   fn := oxedBuild.WorkArea + oxPROJECT_LIB_SOURCE + '.tmp';

   FileUtils.WriteString(fn, p);

   target := oxedBuild.WorkArea + oxPROJECT_LIB_SOURCE;

   if(CompareAndReplace(fn, target)) then
      log.v('Recreated ' + target);
end;

function ShouldRecreate(const fn: string): boolean;
begin
   Result := (FileUtils.Exists(oxedBuild.WorkArea + fn) <= 0) or (oxedBuild.BuildType = OXED_BUILD_TASK_REBUILD);
end;

class function oxedTBuildGlobal.Recreate(): boolean;
begin
   oxedProject.RecreateTempDirectory();

   if(ShouldRecreate(oxPROJECT_APP_INFO_INCLUDE)) then
      oxedAppInfo.Recreate(oxedBuild.WorkArea + oxPROJECT_APP_INFO_INCLUDE);

   {check if main unit exists}
   if(oxedProject.MainUnit <> '') then begin
      if(oxedProject.MainPackage.Units.Find(oxedProject.MainUnit) = nil) then begin
         oxedConsole.e('Specified main unit ' + oxedProject.MainUnit + ' not found.');
         exit(false);
      end;
   end;

   {recreate library}
   if(oxedBuild.BuildTarget = OXED_BUILD_LIB) then begin
      if(ShouldRecreate(oxPROJECT_LIB_SOURCE)) then
         RecreateLib();

      if(ShouldRecreate(oxPROJECT_LIB_LPI)) then begin
         if(not RecreateLPI(true)) then begin
            oxedConsole.e('Failed to create project library lpi file. lpi error: ' + sf(lpi.Error));
            exit(false);
         end;
      end;
   {recreate standalone project}
   end else if(oxedBuild.BuildTarget = OXED_BUILD_STANDALONE) then begin
      if(ShouldRecreate(oxPROJECT_MAIN_SOURCE)) then
         RecreateProgram();

      if(ShouldRecreate(oxPROJECT_MAIN_LPI)) then begin
         if(not RecreateLPI(false)) then begin
            oxedConsole.e('Failed to create project lpi file. lpi error: ' + sf(lpi.Error));
            exit(false);
         end;
      end;
   end;

   Result := true;
end;

procedure BuildLPI(const whichLpi: string);
var
   previousRedirect: boolean;

begin
   if(not oxedBuild.Buildable(true)) then
      exit;

   previousRedirect := build.Output.Redirect;

   build.Output.Redirect := true;

   build.Laz(oxedBuild.WorkArea + whichLpi);

   build.Output.Redirect := previousRedirect;
end;

procedure FailBuild(const reason: StdString);
begin
   oxedBuild.DoneBuild();
   oxedConsole.e('Failed build: ' + reason);
end;

procedure oxedTBuildGlobal.RunBuild();
var
   modeString,
   targetString: string;

begin
   if(not Buildable(true)) then
      exit;

   if(not oxedProject.Valid()) then
      exit;

   build.Options.IsLibrary := IsLibrary();
   BuildStart := Now;
   Features := GetFeatures();

   TargetPath := GetTargetPath();
   WorkArea := GetWorkingAreaPath();

   log.v('Building into: ' + TargetPath);
   log.v('Working area: ' + WorkArea);

   assert(TargetPath <> '', 'Failed to set target path for build');
   assert(WorkArea <> '', 'Failed to set working area for build');

   if(BuildType <> OXED_BUILD_TASK_STANDALONE) then begin
      {if we're missing target path, rebuild}
      if(not FileUtils.DirectoryExists(TargetPath)) then
         BuildType := OXED_BUILD_TASK_REBUILD;
   end else begin
      {create working area directory}

      if(TargetPath <> WorkArea) then begin
         FileUtils.RmDir(WorkArea);

         if(ForceDirectories(WorkArea)) then begin
            log.v('Created working area directory: ' + WorkArea)
         end else begin
            FailBuild('Failed to create working area directory: ' + WorkArea);
            exit;
         end;
      end;

      {create target directory}

      FileUtils.RmDir(TargetPath);

      if(ForceDirectories(TargetPath)) then
         log.v('Created directory: ' + TargetPath)
      else begin
         FailBuild('Failed to create output directory: ' + TargetPath);
         exit;
      end;
   end;

   if(BuildType = OXED_BUILD_TASK_REBUILD) then
      modeString := 'rebuild'
   else if(BuildType = OXED_BUILD_TASK_RECODE) then
      modeString := 'recode'
   else if(BuildType = OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then
      modeString := 'rebuild third party'
   else if(BuildType = OXED_BUILD_TASK_STANDALONE) then
      modeString := 'build';

   if(BuildTarget = OXED_BUILD_LIB) then
      targetString := 'lib'
   else
      targetString := 'standalone';

   oxedConsole.i(modeString + ' started (' + targetString + ')');

   if(not Recreate()) then begin
      FailBuild('Failed to recreate project files');
      exit;
   end;

   if(BuildTarget = OXED_BUILD_LIB) then begin
      {check if used fpc version matches us}
      if(pos(FPC_VERSION, build.CurrentPlatform^.Version) <> 1) then begin
         oxedConsole.e('Library fpc version mismatch. Got ' + build.CurrentPlatform^.Version + ' but require ' + FPC_VERSION);
         exit;
      end;

      BuildLPI(oxPROJECT_LIB_LPI);
   end else
      BuildLPI(oxPROJECT_MAIN_LPI);

   if(build.Output.Success) then begin
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

   source := build.Output.ExecutableName;
   destination := TargetPath + ExtractFileName(build.Output.ExecutableName);

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

class procedure oxedTBuildGlobal.Rebuild();
begin
   oxedBuild.RunTask(OXED_BUILD_TASK_REBUILD);
end;

class procedure oxedTBuildGlobal.Recode();
begin
   oxedBuild.RunTask(OXED_BUILD_TASK_RECODE);
end;

class procedure oxedTBuildGlobal.Cleanup();
begin
   oxedBuild.RunTask(OXED_BUILD_TASK_CLEANUP);
end;

class procedure oxedTBuildGlobal.RecreateFiles();
begin
   oxedBuild.RunTask(OXED_BUILD_TASK_RECREATE);
end;

class procedure oxedTBuildGlobal.RebuildTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_REBUILD);
end;

class procedure oxedTBuildGlobal.RecodeTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_RECODE);
end;

class procedure oxedTBuildGlobal.CleanupTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_CLEANUP);
end;

class procedure oxedTBuildGlobal.RecreateTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_RECREATE);
end;

class procedure oxedTBuildGlobal.RebuildThirdPartyTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_REBUILD_THIRD_PARTY);
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

procedure oxedTBuildGlobal.RunTask(taskType: oxedTBuildTaskType);
begin
   if(not oxedBuild.Buildable(true)) then
      exit;

   if(taskType <> OXED_BUILD_TASK_STANDALONE) then
      BuildTarget := OXED_BUILD_LIB
   else
      BuildTarget := OXED_BUILD_STANDALONE;

   BuildType := taskType;
   build.Options.IsLibrary := BuildTarget = OXED_BUILD_LIB;

   {determine if we need third party units}
   oxedBuild.IncludeThirdParty := (not oxedProject.Session.ThirdPartyBuilt) or oxedProject.Session.IncludeThirdPartyUnits;
   log.v('Third party units included: ' + sf(oxedBuild.IncludeThirdParty));

   {rebuild instead of recode if initial build not done}
   if(BuildType = OXED_BUILD_TASK_RECODE) and (not oxedProject.Session.InitialBuildDone) and (oxedSettings.RequireRebuildOnOpen) then begin
      oxedConsole.i('Rebuild instead of recode on initial build');
      BuildType := OXED_BUILD_TASK_REBUILD;
   end;

   TargetPath := GetTargetPath();
   WorkArea := GetWorkingAreaPath();

   if(BuildType = OXED_BUILD_TASK_RECODE) then begin
      build.Options.Rebuild := false;
      RunBuild();
   end else if(BuildType = OXED_BUILD_TASK_REBUILD) then begin
      build.Options.Rebuild := true;
      RunBuild();
   end else if(BuildType = OXED_BUILD_TASK_CLEANUP) then
      DoCleanup()
   else if(BuildType = OXED_BUILD_TASK_RECREATE) then
      Recreate()
   else if(BuildType = OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then begin
      RebuildThirdParty();
   end else if(BuildType = OXED_BUILD_TASK_STANDALONE) then begin
      build.Options.Rebuild := true;
      RunBuild();
   end;

   log.v('oxed > Build done');
end;

procedure oxedTBuildGlobal.StartTask(taskType: oxedTBuildTaskType);
begin
   if(not Buildable()) then
      exit;

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

   if(BuildTarget = OXED_BUILD_LIB) then begin
      platform := build.FindPlatform(build.BuiltWithTarget, build.BuiltWithVersion);

      if(platform = nil) then begin
         oxedConsole.e('Failed to find suitable compiler for ' + build.BuiltWithTarget + ' and FPC ' + FPC_VERSION);
         exit(false);
      end;

      build.SetPlatform(platform^.Name);

      laz := build.FindLazarusInstallForPlatform(platform);

      if(laz <> nil) then
         build.SetLazarusInstall(laz^.Name)
      else begin
         log.w('Failed to find a lazarus install for fpc: ' + platform^.Name);
         build.GetLazarus();
      end;

      log.v('Using platform: ' + build.CurrentPlatform^.Name + ', fpc ' + build.CurrentPlatform^.Version);
      log.v('Using lazbuild: ' + build.CurrentLazarus^.Name + ', at ' + build.CurrentLazarus^.Path);

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
   if(BuildTarget <> OXED_BUILD_STANDALONE) then
      Result := oxedProject.TempPath
   else
      Result := IncludeTrailingPathDelimiterNonEmpty(base) + oxedBuild.BuildArch.Platform + DirectorySeparator;
end;

function oxedTBuildGlobal.GetTargetExecutableFileName(): StdString;
begin
   Result := WorkArea;

   if(BuildTarget = OXED_BUILD_LIB) then
      Result := Result + build.GetExecutableName(oxPROJECT_LIBRARY_NAME, true)
   else
      Result := Result + build.GetExecutableName(oxedProject.ShortName, false);
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

   oxedActions.BUILD := appActionEvents.SetCallback(@oxedBuild.RebuildTask);
   oxedActions.RECODE := appActionEvents.SetCallback(@oxedBuild.RecodeTask);
   oxedActions.CLEANUP := appActionEvents.SetCallback(@oxedBuild.CleanupTask);
   oxedActions.REBUILD_THIRD_PARTY := appActionEvents.SetCallback(@oxedBuild.RebuildThirdPartyTask);

   oxedProjectScanner.OnDone.Add(@onScanDone);

END.
