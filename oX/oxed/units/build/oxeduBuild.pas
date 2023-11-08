{
   oxeduBuild, oxed build system
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuild;

INTERFACE

   USES
      sysutils, uStd, uLog, uLPI, StringUtils, uTiming,
      uFileUtils, uFile, ufUtils,
      {build}
      uFPCHelpers, uPasSourceHelper,
      uBuild, uBuildInstalls, uBuildExec, uBuildConfiguration, uBuildLibraries, uBuildFPCConfig,
      {app}
      uApp, appuActionEvents, appuSysInfo,
      {ox}
      oxuThreadTask, oxuFeatures, oxuRenderer, oxeduEditorPlatform,
      {oxed}
      uOXED, oxeduConsole, oxeduPackageTypes, oxeduPackage, oxeduProject,
      oxeduPlatform, oxeduTasks, oxeduSettings,
      oxeduAppInfo,oxeduProjectScanner,
      {build}
      oxeduBuildLog, oxeduAssets, oxeduBuildAssets;

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
      OXED_BUILD_EXECUTABLE
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
      {called when build is starting to run, to setup additional build options}
      OnStartRun,
      {called when build is finishing}
      OnFinish,
      {called when build is done}
      OnDone,
      {called when the build has failed}
      OnFailed,
      {called when assets need to be built}
      OnAssets: TProcedures;

      {current build task type}
      BuildType: oxedTBuildTaskType;
      {current build target}
      BuildTarget: oxedTBuildTarget;
      {current build start}
      BuildStart: TDateTime;
      {current build architecture}
      BuildArch,
      {previously used build architecture}
      PreviousBuildArch: oxedTPlatformArchitecture;
      {building for platform}
      BuildPlatform: oxedTPlatform;
      {current build mechanism}
      BuildMechanism: oxedTBuildMechanism;
      {signal the build process to abort}
      BuildAbort,
      {compile a binary for target platform}
      BuildBinary,
      {build assets}
      BuildAssets: boolean;

      {build parameters}
      Parameters: record
         PreIncludeUses,
         IncludeUses,
         ExportSymbols: TSimpleStringList;
      end;

      Options: record
         {completely rebuild standalone}
         StandaloneRebuild: boolean;
      end;

      BuildCPU,
      BuildOS: StdString;

      {is the last build ok}
      BuildOk,
      BuildFailed,
      {is it intended to run within the editor (yes, in case it is library and editor arch)}
      InEditor: boolean;

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

      {recreate the work area (temp )directory if missing}
      procedure RecreateWorkArea();
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
      function MoveExecutable(): boolean;
      {copy required run-time libraries for this build}
      function CopyLibraries(): boolean;

      {run cleanup in a task}
      class procedure BuildStandaloneTask(arch: oxedTPlatformArchitecture); static;

      {run currently set build task (should only be called internally)}
      procedure RunTask();

      {run a task of the specified type and architecture}
      procedure StartTask(taskType: oxedTBuildTaskType; architecture: oxedTPlatformArchitecture);
      {run a task of the specified type}
      procedure StartTask(taskType: oxedTBuildTaskType);

      procedure Abort();

      {setup the required build platform}
      function SetupPlatform(): boolean;
      {setup the required build platform}
      function SetupFPCPlatform(): boolean;

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

      {move file from source to target (overwrites target and logs if indicated to do so)}
      procedure MoveFile(const source, target, what: StdString; log: boolean = true);

      {fail the build}
      procedure Fail(const reason: StdString);

      {Reset build targets and options. Should be called after a build so the next one doesn't use leftover settings.}
      procedure Reset();

      private
      procedure FurtherSteps();
   end;

VAR
   oxedBuild: oxedTBuildGlobal;

IMPLEMENTATION

function CompareAndReplace(const source, target: StdString): boolean;
begin
   Result := fUtils.CompareAndReplace(source, target);

   if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_NO_CHANGE) then
      oxedBuildLog.v('No change for ' + target + ', from: ' + source)
   else if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_UPDATE) then
      oxedBuildLog.v('Updated ' + target + ', from: ' + source)
   else if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_CREATE) then
      oxedBuildLog.v('Created ' + target + ', from: ' + source)
   else if(fUtils.ReplaceResult = fCOMPARE_AND_REPLACE_NO_SOURCE) then
      oxedBuildLog.e('Update from file not found: ' + source);
end;

function createPath(const name, path: StdString): boolean;
begin
   if(not FileUtils.DirectoryExists(path)) then begin
      if(ForceDirectories(path)) then begin
         oxedBuildLog.v('Created ' + name + ' path: ' + path)
      end else begin
         oxedBuild.Fail('Failed to create ' + name + ' path: ' + path);
         exit(false);
      end;
   end;

   Result := true;
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

   if(oxedBuild.BuildFailed) then
      oxedBuild.OnFailed.Call();
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
      fail('Failed to initialize build system')
   else begin
      {set ox package path to the root path}
      oxedAssets.oxPackage.Path := build.RootPath;
   end;
end;

procedure onScanDone(); forward;

{ oxedTBuildGlobal }

class procedure oxedTBuildGlobal.Initialize();
begin
   buildInitialize();

   oxedBuild.Task := oxedTBuildTask.Create();
   oxedBuild.Task.EmitAllEvents();

   {reset to set values from initialized build}
   oxedBuild.Reset();

   oxedProjectScanner.OnDone.Add(@onScanDone);
end;

class procedure oxedTBuildGlobal.Deinitialize();
begin
   oxedBuild.Reset();
   oxedBuild.BuildArch := nil;
   oxedBuild.PreviousBuildArch := nil;
   build.DeInitialize();
   lpi.DeInitialize();
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

      if(oxFeatures.IsSupported(feature^, BuildOS, IsLibrary())) then begin
         if(lib) then begin
            {skip renderer features as we'll include only a single renderer}
            if(pos('renderer.', feature^.Name) = 1) then
               continue;

            {skip if the feature cannot work in library mode}
            if(not feature^.Platforms.IsEnabled('library')) then
               continue;

            {console needs to be enabled}
            if(feature^.Name = 'feature.console') and (not oxedProject.Session.EnableConsole) then
               continue;
         end;

         if(feature^.IncludeByDefault) then
            Result.Add(feature);
      end;
   end;

   {in library mode, only include the renderer we need}
   if(lib) then begin
      feature := oxFeatures.FindByName('renderer.' + oxRenderer.Id);
      assert(feature <> nil, 'Renderer ' + oxRenderer.Id +  ' feature must never be nil');
      Result.Add(feature);
   end;
end;

function oxedTBuildGlobal.IsLibrary(): boolean;
begin
   Result := BuildTarget <> OXED_BUILD_EXECUTABLE;
end;

procedure oxedTBuildGlobal.RecreateWorkArea();
begin
   oxedProject.RecreateTempDirectory();
   createPath('work area', WorkArea);
end;

function getRelativePath(const basePath: StdString; const unitPath: StdString): StdString;
begin
   Result := ExtractRelativePath(oxedBuild.WorkArea, basePath + unitPath);
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

   {$IFDEF OX_DEBUG}
   Result.Add('OX_DEBUG');
   Result.Add('DEBUG');
   {$ENDIF}

   if oxedBuild.IsLibrary() then begin
      Result.Add('LIBRARY');

      if oxedBuild.InEditor then begin
         Result.Add('OX_LIBRARY');
         Result.Add('OX_LIBRARY_SUPPORT');
         Result.Add('OXED');
      end;

      if(oxedBuild.InEditor) then begin
      {$IFDEF NO_THREADS}
      Result.Add('NO_THREADS');
      {$ENDIF}
      end;
   end;

   Result.Add('OX_NO_DEFAULT_FEATURES');

   if oxedProject.Session.DebugResources then
      Result.Add('OX_RESOURCE_DEBUG');

   if oxedProject.NilProject then begin
      Result.Add('OX_NIL');
   end;

   for i := 0 to oxedBuild.Features.n - 1 do begin
      Result.Add(oxedBuild.Features.List[i]^.Symbol);
   end;

   for i := 0 to oxedBuild.BuildPlatform.Symbols.n - 1 do begin
      Result.Add(oxedBuild.BuildPlatform.Symbols.List[i]);
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
   for idx := 0 to p.Paths.n - 1 do begin
      if(p.Paths.List[idx].IsSupported(oxedBuild.BuildOS, oxedBuild.IsLibrary())) then begin
         relativePath := getRelativePath(path, p.Paths.List[idx].Path);

         if(p.Paths.List[idx].Units.n > 0) then
            f.AddUnitPath(relativePath);

         if(p.Paths.List[idx].IncludeFiles.n > 0) then
            f.AddIncludePath(relativePath);
      end;
   end;
end;

begin
   f.SetTitle(oxedProject.Name);
   f.compiler.applyConventions := false;

   if(oxedBuild.BuildType <> OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then begin
      processPackage(oxedAssets.oxPackage, oxedAssets.oxPackage.Path);
      processPackage(oxedProject.MainPackage, oxedProject.Path);

      for i := 0 to oxedProject.Packages.n - 1 do begin
         processPackage(oxedProject.Packages.List[i], oxedProject.GetPackagePath(oxedProject.Packages.List[i]));
      end;
   end;

   symbols := getSymbols();

   for i := 0 to symbols.n - 1 do begin
      f.AddSymbol(symbols.List[i]);
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

   thirdparty := OXED_BUILD_3RDPARTY_PATH + DirSep;

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
   if(@package <> @oxedAssets.oxPackage) then begin
      if(@package <> @oxedProject.MainPackage) then
         config.Add('# Package: ' + package.Name)
      else
         config.Add('# Project: ' + package.Name);
   end else
      config.Add('# OX');

   config.Add('# Path: ' + path);
   config.Add('');

   for i := 0 to package.Paths.n - 1 do begin;
      if(package.Paths.List[i].Units.n > 0) then
         config.Add('-Fu' + getAbsolutePath(path, package.Paths.List[i].Path));
   end;

   for i := 0 to package.Paths.n - 1 do begin;
      if(package.Paths.List[i].IncludeFiles.n > 0) then
         config.Add('-Fi' + getAbsolutePath(path, package.Paths.List[i].Path));
   end;
end;

procedure InsertPackagesIntoConfig(var config: TBuildFPCConfiguration);
var
   i: loopint;

begin
   InsertPackageIntoConfig(config, oxedAssets.oxPackage, oxedAssets.oxPackage.Path);
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

   {construct defaults}
   config.Construct();

   {default target fpc units}
   config.Add();
   config.Add('## default target fpc units (' + BuildInstalls.CurrentPlatform^.Platform + ')');
   config.ConstructDefaultIncludes(BuildInstalls.CurrentPlatform^.GetBaseUnitsPath());

   {$IFDEF LINUX}
   fn := '/usr/lib/gcc/x86_64-redhat-linux/10/';

   if(DirectoryExists(fn)) then begin
      config.Add();
      config.Add('### default objects path for linker');
      config.Add('-Fl' + fn);
   end;
   {$ENDIF}

   {add packages}
   InsertPackagesIntoConfig(config);

   {add symbols}
   config.Add('');

   symbols := getSymbols();
   config.AddSymbols(symbols.List, symbols.n);

   { write config file }

   fn := oxedBuild.WorkArea + oxedBuild.Props.ConfigFile;

   Result := config.WriteFile(fn);

   if(not Result) then
      oxedBuildLog.e('Failed to write fpc config file for project: ' + fn)
   else
      oxedBuildLog.v('Created fpc config file for project: ' + fn);
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

function isCMEM(): boolean;
begin
   Result := oxed.UseCMEM;

   if(not Result) then
      Result := oxedBuild.BuildPlatform.RequireCMEM;

   oxedBuildLog.v('Using cmem: ' + sf(Result));
end;

procedure CreateIncludesList(const list: TSimpleStringList; var s: TAppendableString; prefix: StdString = '');
var
   i: loopint;

begin
   if list.n > 0 then begin
      for i := 0 to list.n - 1 do begin
         {check for comment}
         if pos('{', list.List[i]) <> 1 then begin
           if i < list.n - 1 then
              s.Add(prefix + list.List[i] + ',')
           else
              s.Add(prefix + list.List[i]);
         end else
            s.Add(prefix + list.List[i]);
      end;
   end;
end;

procedure GetUsesUnits(var units: TSimpleStringList);
var
   i: loopint;

   procedure processPackage(var p: oxedTPackage);
   var
      i,
      j: loopint;
      ppath: oxedPPackagePath;

   begin
      {include all supported units}
      for i := 0 to p.Paths.n - 1 do begin
         ppath := @p.Paths.List[i];

         if(ppath^.IsSupported(oxedBuild.BuildOS, oxedBuild.IsLibrary())) then begin
            for j := 0 to ppath^.Units.n - 1 do begin
               units.Add(ppath^.Units.List[j]);
            end;
         end;
      end;
   end;

begin
   if(oxedBuild.Parameters.PreIncludeUses.n > 0) then begin
     units.Add('{build included first}');

     for i := 0 to oxedBuild.Parameters.PreIncludeUses.n - 1 do begin
        units.Add(oxedBuild.Parameters.PreIncludeUses.List[i]);
     end;
   end;

   if(oxedProject.MainUnit <> '') then begin
      units.Add('{main unit}');
      units.Add(oxedProject.MainUnit);
   end else begin
      if(oxedProject.MainPackage.Paths.n > 0) then begin
         units.Add('{project units}');
         processPackage(oxedProject.MainPackage);
      end;
   end;

   if(oxedBuild.Parameters.IncludeUses.n > 0) then begin
      units.Add('{build included}');

      for i := 0 to oxedBuild.Parameters.IncludeUses.n - 1 do begin
         units.Add(oxedBuild.Parameters.IncludeUses.List[i]);
      end;
   end;

end;

function GetUsesString(): TAppendableString;
var
   units: TSimpleStringList;

begin
   Result := '';

   if(isCMEM()) then begin
      {include cmem only if not already included by something else}
      Result.Add('{$IF NOT DECLARED(calloc)}cmem,{$ENDIF}');
   end;

   Result.Add('{$INCLUDE oxappuses.inc}');

   if(not oxedProject.NilProject) then
      Result := Result + ',';

   TSimpleStringList.Initialize(units, 128);

   GetUsesUnits(units);

   CreateIncludesList(units, Result, '   ');

   units.Dispose();
end;

procedure SetupSource(out u: TPascalSourceBuilder);
begin
   TPascalSourceBuilder.Initialize(u);

   u.Header := getSourceHeader();
   u.Name := oxedProject.Identifier;

   u.sUses := GetUsesString();
   CreateIncludesList(oxedBuild.Parameters.ExportSymbols, u.sExports, '   ');
end;

procedure RecreateProgram();
var
   p: TAppendableString;
   u: TPascalSourceBuilder;

begin
   SetupSource(u);

   if(not oxedProject.NilProject) then begin
      u.sMain := '   {$INCLUDE ./appinfo.inc}';
      u.sMain.Add('   oxRun.Go()');
   end;

   p := u.BuildProgram();

   FileUtils.WriteString(oxedBuild.WorkArea + oxPROJECT_MAIN_SOURCE, p);
end;

procedure RecreateLib();
var
   p: TAppendableString;
   u: TPascalSourceBuilder;
   fn,
   target: string;

begin
   SetupSource(u);

   if(not oxedProject.NilProject) then
      u.sInitialization.Add('{$INCLUDE ./appinfo.inc}');

   p := u.BuildLibrary();

   fn := oxedBuild.WorkArea + oxedBuild.Props.Source + '.tmp';

   FileUtils.WriteString(fn, p);

   target := oxedBuild.WorkArea + oxedBuild.Props.Source;

   if(CompareAndReplace(fn, target)) then
      oxedBuildLog.v('Recreated ' + target);
end;

function ShouldRecreate(const fn: string): boolean;
begin
   Result := (FileUtils.Exists(oxedBuild.WorkArea + fn) <= 0) or (oxedBuild.BuildType = OXED_BUILD_TASK_REBUILD);
end;

class function oxedTBuildGlobal.Recreate(force: boolean): boolean;
begin
   if(not FileUtils.CreateDirectory(build.FPCOptions.UnitOutputPath)) then begin
      oxedBuildLog.e('Failed to create unit output directory: ' + build.FPCOptions.UnitOutputPath);
      exit(false);
   end;

   if force or (ShouldRecreate(oxPROJECT_APP_INFO_INCLUDE)) then
      oxedAppInfo.Recreate(oxedBuild.WorkArea + oxPROJECT_APP_INFO_INCLUDE);

   {check if main unit exists}
   if(oxedProject.MainUnit <> '') then begin
      if(oxedProject.MainPackage.Paths.FindPackageUnit(oxedProject.MainUnit) = nil) then begin
         oxedBuildLog.e('Specified main unit ' + oxedProject.MainUnit + ' not found.');
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
            oxedBuildLog.e('Failed to create project fpc config file.');
            exit(false);
         end;
      end else begin
         if(not RecreateLPI()) then begin
            oxedBuildLog.e('Failed to create project library lpi file. lpi error: ' + sf(lpi.Error));
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
   {don't use default FPC config}
   build.FPCOptions.DontUseDefaultConfig := true;
   {use our config}
   build.FPCOptions.UseConfig := oxedBuild.WorkArea + oxedBuild.Props.ConfigFile;

   parameters := TBuildFPCConfiguration.GetFPCCommandLineForConfig();

   {verbosity level}
   parameters.Add('-vewnhiq');
   {output FPC logo}
   parameters.Add('-l');

   if(parameters.n > 0) then begin
      oxedBuildLog.Collapsed('FPC parameters for build');

      for i := 0 to parameters.n - 1 do begin
         oxedBuildLog.i(parameters.List[i]);
      end;

      oxedBuildLog.Leave();
   end;

   BuildExec.Pas(oxedBuild.WorkArea + oxedBuild.Props.Source, @parameters);
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

procedure oxedTBuildGlobal.RunBuild();
var
   modeString,
   targetString: string;

begin
   OnStartRun.Call();

   {OnStartRun failed the build, quit}
   if(not BuildOk) then
      exit;

   oxedBuildLog.v('Building platform: ' + BuildArch.GetPlatformString());
   oxedBuildLog.v('Building into: ' + TargetPath);
   oxedBuildLog.v('Working area: ' + WorkArea);

   if(oxed.UseHeapTrace) and (IsLibrary()) then
      oxedBuildLog.w('OXED built with heaptrc included, running library may be unstable');

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

      if(Options.StandaloneRebuild) then begin
         {remove work area}
         if(FileUtils.DirectoryExists(WorkArea)) then
            FileUtils.RmDir(WorkArea);
      end;
   end;

   RecreateWorkArea();
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

   oxedBuildLog.i(modeString + ' started (' + targetString + ')');

   if(BuildBinary) then begin
      if(not Recreate()) then begin
         Fail('Failed to recreate project files');
         exit;
      end;

      if(not RecreateConfig(BuildMechanism)) then begin
         Fail('Failed to recreate project config files');
         exit;
      end;

      if(IsLibrary()) then begin
         {check if used fpc version matches us}
         if(pos(FPC_VERSION, BuildInstalls.CurrentPlatform^.Version) <> 1) then begin
            oxedBuildLog.e('Library fpc version mismatch. Got ' + BuildInstalls.CurrentPlatform^.Version + ' but require ' + FPC_VERSION);
            exit;
         end;
      end;

      ExecuteBuild();

      if(not BuildExec.Output.Success) then
         Fail(modestring + ' failed (elapsed: ' + BuildStart.ElapsedfToString() + 's)');
   end else begin
      {fake a successful build}
      BuildExec.ResetOutput();
      BuildExec.Output.Success := true;
   end;

   if(BuildOk) then begin
      FurtherSteps();

      OnFinish.Call();

      if(BuildOk) then begin
         oxedBuildLog.k(modestring + ' success (elapsed: ' + BuildStart.ElapsedfToString() + 's)');

         {if successful rebuild, we've made an initial build}
         oxedProject.Session.InitialBuildDone := true;
      end;
   end;

   {cleanup}
   DoneBuild();
end;

procedure oxedTBuildGlobal.DoneBuild();
begin
   Features.Dispose();
end;

function oxedTBuildGlobal.MoveExecutable(): boolean;
var
   source,
   destination: StdString;

begin
   {nothing to do here}
   if(BuildTarget <> OXED_BUILD_EXECUTABLE) then
      exit(true);

   Result := false;

   source := BuildExec.Output.ExecutableName;
   destination := TargetPath + ExtractFileName(BuildExec.Output.ExecutableName);

   {remove destination first}
   FileUtils.Erase(destination);

   {move the file}
   if(RenameFile(source, destination)) then begin
      oxedBuildLog.v('Moved: ' + source + ' to ' + destination);

      if(build.Debug.Include) then begin
         {try to move debug information, if any}
         source := ExtractAllNoExt(source) + '.dbg';
         destination := ExtractAllNoExt(destination) + '.dbg';

         if(FileExists(source)) then
            MoveFile(source, destination, 'debug info');
      end;

      Result := true;
   end else
      Fail('Failed to move: ' + source + ' to ' + destination);
end;

function CopyLibrary(const source: StdString; const target: StdString = ''): boolean;
begin
   if(not buildLibraries.CopyLibrary(source, target)) then begin
      if(target <> '') then
         oxedBuild.Fail('Failed to copy library ' + source + ' as ' + target)
      else
         oxedBuild.Fail('Failed to copy library ' + source);

      exit(false);
   end;

   Result := true;
end;

function oxedTBuildGlobal.CopyLibraries(): boolean;
{$IFDEF WINDOWS}
var
   requireZlib: boolean;
{$ENDIF}

begin
   {nothing to do here}
   if(BuildTarget <> OXED_BUILD_EXECUTABLE) then
      exit(true);

   Result := false;

   {$IFDEF WINDOWS}
   buildLibraries.Target := TargetPath;
   requireZlib := false;

   if(Features.FindByName('audio.al') <> nil) then begin
      if(not CopyLibrary('oal_soft.dll', 'openal32.dll')) then
         exit(false);
   end;

   if(Features.FindByName('freetype') <> nil) then begin
      if(not CopyLibrary('freetype-6.dll', 'freetype.dll')) then
         exit(false);
   end;

   if(requireZlib) then
      CopyLibrary('zlib1.dll');
   {$ENDIF}

   Result := true;
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
   oxedBuild.StartTask(OXED_BUILD_TASK_STANDALONE, arch);
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
   oxedBuildLog.i('Recreating project files');

   oxedBuild.RecreateWorkArea();

   {recreate general files}
   oxedBuild.Recreate(true);

   {recreate fpc config files}
   oxedBuild.RecreateConfig(OXED_BUILD_VIA_FPC, true);

   {recreate laz config files}
   oxedBuild.RecreateConfig(OXED_BUILD_VIA_LAZ, true);
end;

procedure SetupFPCBuildOptions();
var
   arch: oxedTPlatformArchitecture;
   fn: StdString;

begin
   arch := oxedBuild.BuildArch;

   {setup build options}
   build.ResetOptions();
   build.Options.IsLibrary := oxedBuild.IsLibrary();

   build.FPCOptions.UnitOutputPath := oxedBuild.WorkArea  + 'lib';

   {setup base options}
   build.Target.CPU := oxedBuild.BuildCPU;
   build.Target.OS := oxedBuild.BuildOS;

   build.Target.CPUType := arch.DefaultCPUType;
   build.Target.FPUType := arch.DefaultFPUType;
   build.Target.BinUtilsPrefix := arch.BinUtilsPrefix;

   if oxedBuild.IsLibrary() and oxedBuild.BuildPlatform.RequiresPIC then
      build.FPCOptions.PositionIndependentCode := true;

   {debug checks}
   build.Checks.IO := true;
   build.Checks.Range := true;
   build.Checks.Overflow := true;
   build.Checks.Stack := true;
   build.Checks.Assertions := true;

   {$IFOPT D+}
   build.Debug.Include := true;
   build.Debug.LineInfo := true;
   {$ENDIF}

   {platforn}
   build.ExecutableOptions.ExcludeDefaultLibraryPath := oxedBuild.BuildPlatform.ExcludeDefaultLibraryPath;

   if(build.Debug.Include) then begin
      if(oxedBuild.BuildPlatform.SupportsExternalDebugSymbols) then
         build.Debug.External := true;
   end;

   {optimization}
   build.Optimization.Level := 1;

   {custom options file, if one is present in the config directory}
   fn := oxedProject.GetConfigFilePath('fpc.cfg');

   if(FileExists(fn)) then
      build.CustomOptions.Add('#INCLUDE ' + fn);
end;

procedure SetupEditorBuildOptions();
begin
   if(oxedBuild.InEditor) then begin
      oxedBuild.Parameters.IncludeUses.Add('{library}');
      oxedBuild.Parameters.IncludeUses.Add('oxuDynlib');

      oxedBuild.Parameters.ExportSymbols.Add('ox_library_load');
      oxedBuild.Parameters.ExportSymbols.Add('ox_library_unload');
      oxedBuild.Parameters.ExportSymbols.Add('ox_library_version');
   end;
end;

procedure oxedTBuildGlobal.RunTask();
begin
   if(not oxedBuild.Buildable(true)) or (not oxedProject.Valid()) then
      exit;

   {we start off assuming things are fine}
   BuildOk := true;
   BuildFailed := false;
   BuildStart := Now;

   if(BuildType = OXED_BUILD_TASK_STANDALONE) then begin
      BuildAssets := true;
      BuildBinary := true;
   end;

   {start off empty}
   oxedBuildLog.Log.Reset();

   {get cpu and OS from arch}
   BuildArch.GetPlatformString().Separate(BuildCPU, BuildOS);

   {determine if we need third party units}
   oxedBuild.IncludeThirdParty := (not oxedProject.Session.ThirdPartyBuilt) or
      oxedProject.Session.IncludeThirdPartyUnits;

   oxedBuildLog.v('Third party units included: ' + sf(oxedBuild.IncludeThirdParty));

   {rebuild instead of recode if initial build not done}
   if(BuildType = OXED_BUILD_TASK_RECODE) and (not oxedProject.Session.InitialBuildDone) and
   (oxedSettings.RequireRebuildOnOpen) then begin
      oxedBuildLog.i('Rebuild instead of recode on initial build');
      BuildType := OXED_BUILD_TASK_REBUILD;
   end;

   InEditor := IsLibrary() and (BuildArch.Name = 'editor');

   if(IsLibrary()) then
      Props.Source := oxPROJECT_LIB_SOURCE
   else
      Props.Source := oxPROJECT_MAIN_SOURCE;

   if(BuildBinary) then begin
      if(not SetupFPCPlatform()) then begin
         Reset();
         exit;
      end;
   end;

   if(oxedBuild.BuildMechanism = OXED_BUILD_VIA_FPC) then
      props.ConfigFile := GetFPCConfigFilename()
   else
      Props.ConfigFile := GetLPIFilename();

   TargetPath := GetTargetPath();
   WorkArea := GetWorkingAreaPath();
   Features := GetFeatures();

   SetupFPCBuildOptions();
   SetupEditorBuildOptions();

   {run tasks}
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
      build.Options.Rebuild := Options.StandaloneRebuild;
      RunBuild();
   end;

   {we're done}
   PreviousBuildArch := BuildArch;

   Reset();
   oxedBuildLog.v('oxed > Build task done');
end;

procedure oxedTBuildGlobal.StartTask(taskType: oxedTBuildTaskType; architecture: oxedTPlatformArchitecture);
begin
   BuildArch := architecture;
   BuildPlatform := oxedTPlatform(BuildArch.PlatformObject);
   StartTask(taskType);
end;

procedure oxedTBuildGlobal.StartTask(taskType: oxedTBuildTaskType);
begin
   if(not oxedBuild.Buildable(true)) or (not oxedProject.Valid()) then
      exit;

   if(taskType = OXED_BUILD_TASK_STANDALONE) then
      BuildTarget := OXED_BUILD_EXECUTABLE;

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

procedure oxedTBuildGlobal.Abort();
begin
   BuildAbort := true;
   BuildExec.Abort();
end;

function oxedTBuildGlobal.SetupPlatform(): boolean;
var
   laz: PBuildLazarusInstall;

begin
   Result := SetupFPCPlatform();

   if(Result) then begin
      laz := BuildInstalls.FindLazarusInstallForPlatform(BuildInstalls.CurrentPlatform);

      if(laz <> nil) then
         BuildInstalls.SetLazarusInstall(laz^.Name)
      else begin
         log.w('Failed to find a lazarus install for fpc: ' + BuildInstalls.CurrentPlatform^.Name);
         BuildInstalls.GetLazarus();
         exit(false);
      end;

      log.v('Using lazbuild: ' + BuildInstalls.CurrentLazarus^.Name + ', at ' + BuildInstalls.CurrentLazarus^.Path);
      exit(true);
   end;
end;

function oxedTBuildGlobal.SetupFPCPlatform(): boolean;
var
   platform: PBuildPlatform;

begin
   Result := false;

   if(BuildArch = nil) or (InEditor) then begin
      BuildInstalls.SetDefaultPlatform();
      exit(True);
   end;

   platform := BuildInstalls.FindPlatform(BuildArch.GetPlatformString(), Build.BuiltWithVersion);

   if(platform = nil) then begin
      oxedBuildLog.e('Failed to find suitable compiler for ' + BuildArch.GetPlatformString() + ' and FPC ' + Build.BuiltWithVersion);
      exit(false);
   end;

   BuildInstalls.SetPlatform(platform^.Name);

   oxedBuildLog.v('Using platform: ' + BuildInstalls.CurrentPlatform^.Name +
      ', fpc ' + BuildInstalls.CurrentPlatform^.Version +
      ', location: ' + BuildInstalls.CurrentPlatform^.GetExecutablePath());


   exit(true);
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
         Result := oxedProject.TempPath + BuildArch.GetPlatformString() + DirSep;
   end else
      Result := IncludeTrailingPathDelimiterNonEmpty(base) + oxedBuild.BuildArch.GetPlatformString() + DirSep;
end;

function oxedTBuildGlobal.GetTargetExecutableFileName(): StdString;
begin
   Result := WorkArea;

   if(IsLibrary()) then
      Result := Result + BuildArch.LibraryPrefix + oxPROJECT_LIBRARY_NAME + BuildArch.LibraryExtension
   else
      Result := Result + oxedProject.ShortName + BuildArch.ExecutableExtension;
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

procedure oxedTBuildGlobal.MoveFile(const source, target, what: StdString; log: boolean);
var
   ok: boolean;

begin
   {erase data file first}
   if(FileUtils.Exists(target) > 0) then
      FileUtils.Erase(target);

   {move data file}
   ok := RenameFile(source, target);

   if(not ok) then
      oxedBuild.Fail('Failed to move ' + what + ' from "' + source + '" to "' + target + '"');

   if log and ok then
      oxedBuildLog.k('Moved ' + what + ' from "' + source + '" to "' + target + '"');
end;

procedure oxedTBuildGlobal.Fail(const reason: StdString);
begin
   DoneBuild();
   BuildOk := false;
   BuildFailed := true;
   oxedBuildLog.e('Failed build: ' + reason);
end;

procedure oxedTBuildGlobal.Reset();
begin
   PreviousBuildArch := nil;
   BuildOk := false;
   BuildFailed := false;
   InEditor := false;
   BuildType := OXED_BUILD_TASK_RECODE;
   BuildTarget := OXED_BUILD_LIB;

   BuildArch := nil;
   if(oxedEditorPlatform <> nil) then
      BuildArch := oxedEditorPlatform.Architecture;

   BuildMechanism := OXED_BUILD_VIA_FPC;
   BuildAbort := false;
   BuildBinary := true;
   BuildAssets := false;

   Parameters.ExportSymbols.Dispose();
   Parameters.PreIncludeUses.Dispose();
   Parameters.IncludeUses.Dispose();

   BuildInstalls.SetDefaultPlatform();
end;

procedure oxedTBuildGlobal.FurtherSteps();
begin
   if(BuildBinary) then begin
      if(BuildType = OXED_BUILD_TASK_STANDALONE) then begin
         if(BuildTarget <> OXED_BUILD_LIB) then begin
            if(not MoveExecutable()) then
               exit;
         end;

         if(not CopyLibraries()) then
            exit;
      end;
   end;

   if(BuildAssets) then begin
      oxedBuildAssets.Deploy(oxedBuild.TargetPath);

      if(not oxedBuild.BuildOk) then
         exit;

      OnAssets.Call();
   end;

   if(BuildType = OXED_BUILD_TASK_STANDALONE) then begin
      {open target file path when    done}
      app.OpenFileManager(TargetPath);
   end;
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
      oxedBuildLog.v('Run build after scan');
      oxedBuild.StartTask(oxedBuild.RunAfterScanTaskType);
   end;
end;

INITIALIZATION
   oxed.Init.Add('build', @oxedTBuildGlobal.Initialize, @oxedTBuildGlobal.Deinitialize);

   TProcedures.InitializeValues(oxedBuild.OnStartRun);
   TProcedures.InitializeValues(oxedBuild.OnFinish);
   TProcedures.InitializeValues(oxedBuild.OnPrepare);
   TProcedures.InitializeValues(oxedBuild.OnDone);
   TProcedures.InitializeValues(oxedBuild.OnFailed);
   TProcedures.InitializeValues(oxedBuild.OnAssets);

   TSimpleStringList.InitializeValues(oxedBuild.Parameters.ExportSymbols);
   TSimpleStringList.InitializeValues(oxedBuild.Parameters.PreIncludeUses);
   TSimpleStringList.InitializeValues(oxedBuild.Parameters.IncludeUses);

   {don't load default units, we'll load ox units as a package}
   BuildConfiguration.DoLoadUnits := false;

END.
