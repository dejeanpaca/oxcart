{
   oxeduBuild, oxed build system
   Copyright (C) 2017. Dejan Boras

   Started On:    03.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuild;

INTERFACE

   USES
      sysutils, process, uStd, uLog, uBuild, uLPI, uFileUtils, StringUtils, uTiming, uFile, uFiles,
      uApp, appuActionEvents,
      {ox}
      oxuThreadTask, oxuFeatures, oxuRenderer,
      {oxed}
      uOXED, oxeduMessages, oxeduProject, oxeduTasks, oxeduActions, oxeduSettings, oxeduProjectScanner;

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
      OnPreBuild: TProcedures;
      {called when build is done}
      OnBuildDone: TProcedures;

      BuildType: oxedTBuildTaskType;
      BuildTarget: oxedTBuildTarget;
      BuildStart: TDateTime;

      {is there a task currently running}
      Task: oxedTBuildTask;
      {should we include third party units in the current build}
      IncludeThirdParty,
      {indicates to run after a project scan has been done}
      RunAfterScan: boolean;
      {what task type to run after scan}
      RunAfterScanTaskType: oxedTBuildTaskType;

      class procedure Initialize(); static;
      class procedure Deinitialize(); static;

      {tells whether the build system is enabled and functional}
      function BuildEnabled(): boolean;
      {tells whether the project is currently buildable}
      function Buildable(ignoreRunning: boolean = false): boolean;

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

      {run currently set build task}
      procedure RunTask(taskType: oxedTBuildTaskType);

      {run a task of the specified type}
      procedure StartTask(taskType: oxedTBuildTaskType);
      {open lazarus ide for this project}
      class procedure OpenLazarus(); static;
      {open project directory}
      class procedure OpenProjectDirectory(); static;
   end;

VAR
   oxedBuild: oxedTBuildGlobal;

IMPLEMENTATION

VAR
   fBuf1,
   fBuf2: array[0..16383] of byte;

{Compares two files. It'll replace the second one with the first one if they mismatch.
Otherwise it discards the first file. This is helpful to minimize file change warnings when content was not changed.}
function CompareAndReplace(fn1, fn2: string): boolean;
var
   f1, f2: TFile;
   mismatch: fileint;

begin
   Result := false;

   if(FileUtils.Exists(fn2) >= 0) then begin
      fFile.Init(f1);
      fFile.Init(f2);

      f1.Open(fn1);
      f2.Open(fn2);

      {speed things up}
      f1.ExternalBuffer(@fBuf1[0], Length(fBuf1));
      f2.ExternalBuffer(@fBuf2[0], Length(fBuf2));

      mismatch := fFile.Compare(f1, f2);

      f1.Close();
      f2.Close();

      if(mismatch = 0) then begin
         FileUtils.Erase(fn1);
         log.v('No change for ' + fn2 + ', from: ' + fn1);
      end else begin
         FileUtils.Erase(fn2);
         RenameFile(fn1, fn2);
         log.v('Updated ' + fn2 + ', from: ' + fn1);

         Result := true;
      end;
   end else begin
      RenameFile(fn1, fn2);
      log.v('Created ' + fn2 + ', from: ' + fn1);

      Result := true;
   end;
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

   oxedBuild.OnPreBuild.Call();
end;

procedure oxedTBuildTask.ThreadDone();
begin
   inherited;

   oxedBuild.OnBuildDone.Call();
end;

{ oxedTBuildGlobal }

class procedure oxedTBuildGlobal.Initialize();
begin
   build.Initialize();
   lpi.Initialize();

   log.i('Done with build system initialization');

   if(not oxedBuild.BuildEnabled()) then
      oxedMessages.e('Build system failed to initialize. You will not be able to run the project.');

   if(not lpi.IsInitialized()) then
      oxedMessages.e('LPI system failed to initialize. Cannot create project lpi files.');

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
      count := oxedTasks.Running(Nil)
   else
      count := oxedTasks.Running(nil, oxedTBuildTask);

   Result := count > 0;

   Result := (not Result) and oxedBuild.BuildEnabled() and oxedProjectValid() and (not oxedProject.Running);
end;

function getRelativePath(const unitFile: oxedTProjectUnit): string;
begin
   Result := '..' + DirectorySeparator + ExtractFilePath(unitFile.Path);
end;

function getFeatures(isLibrary: boolean = false): oxTFeaturePDescriptorList;
var
   i: loopint;
   feature: oxPFeatureDescriptor;
   platform: string;

begin
   Result.Initialize(Result);
   platform := build.GetCurrentPlatform();

   for i := 0 to oxFeatures.List.n - 1 do begin
      feature := @oxFeatures.List.List[i];

      if(oxFeatures.IsSupportedFeature(feature^, platform, isLibrary)) then begin
         if(isLibrary and (pos('renderer.', feature^.Name) = 1)) then
            continue;

         Result.Add(feature);
      end;
   end;

   if(oxedProject.Session.EnableConsole) then begin
      feature := oxFeatures.Find('feature.console');
      assert(feature <> nil, 'feature.console not found amongst default ox features');
      Result.Add(feature);
   end;

   if(isLibrary) then begin
      feature := oxFeatures.Find(oxRenderer.Id);
      assert(feature <> nil, 'Renderer ' + oxRenderer.Id +  ' feature must never be nil');
      Result.Add(feature);
   end;
end;

procedure recreateSymbols(var f: TLPIFile; isLibrary: boolean);
var
   i: loopint;
   features: oxTFeaturePDescriptorList;

begin
   features := getFeatures(isLibrary);

   for i := 0 to features.n - 1 do begin
      f.AddCustomOption('-d' + features.List[i]^.Symbol);
   end;
end;

procedure lpiLoadedCommon(var f: TLPIFile; IsLibrary: boolean = false);
var
   i: loopint;
   relativePath: string;

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
   oxedMessages.w('Including debug info');
   f.AddCustomOption('-g');
   {$ENDIF}

   if(oxed.UseHeapTrace) then
      oxedMessages.w('OXED built with heaptrc included, running library may be unstable');

   f.SetTitle(oxedProject.Name);
   f.compiler.applyConventions := false;

   if(oxedBuild.BuildType <> OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then begin
      for i := 0 to oxedProject.Units.n - 1 do begin
         relativePath := getRelativePath(oxedProject.Units.List[i]);
         f.AddUnitPath(relativePath);
      end;

      for i := 0 to oxedProject.IncludeFiles.n - 1 do begin
         relativePath := getRelativePath(oxedProject.IncludeFiles.List[i]);
         f.AddIncludePath(relativePath);
      end;
   end;

   recreateSymbols(f, IsLibrary);
   f.SetValue(f.compiler.targetFilename, oxedProject.GetLibraryPath(false));
end;

procedure lpiLoaded(var f: TLPIFile);
begin
   lpiLoadedCommon(f);
end;

VAR
   previousBuildUnits: TPreallocatedStringArrayList;

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
   lpiLoadedCommon(f, True);

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

   fnTemp := oxedProject.TempPath + '-Temp-' + source;
   fn := oxedProject.TempPath + lpifn;

   lpi.Create(fnTemp, @context);

   if(lpi.Error = 0) then
      CompareAndReplace(lpi.OutFileName, fn);

   restoreBuildUnits();

   Result := lpi.Error = 0;
end;

function getSourceHeader(includeFunctional: boolean = true): TAppendableString;
begin
   Result := '{';
   Result.Add('   ' + oxedProject.Name + ' (' + oxedProject.Identifier + ')');

   if(oxedProject.Organization <> '') then
      Result.Add('   ' + oxedProject.Organization + ' (' + oxedProject.OrganizationShort + ')');

   Result.Add('   Automatically generated by OXED, any modifications will be lost');
   Result.Add('}');

   if(includeFunctional) then
      Result.Add('{$INCLUDE oxdefines.inc}');
end;

procedure RecreateAppInfo();
var
   p: TAppendableString;

begin
   p := getSourceHeader(false);
   p.Add('');

   p.Add('appInfo.SetName(''' + oxedProject.Name + ''');');

   if(oxedProject.ShortName <> '') then
      p.Add('appInfo.NameShort := ''' + oxedProject.ShortName + ''';');

   p.Add('appInfo.SetOrganization(''' + oxedProject.Organization + ''');');

   if(oxedProject.OrganizationShort <> '') then
      p.Add('appInfo.OrgShort := ''' + oxedProject.OrganizationShort + ''';');

   p.Add('appInfo.SetVersion(1, 0);' + LineEnding);

   FileUtils.WriteString(oxedProject.TempPath + oxPROJECT_APP_INFO_INCLUDE, p);
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
var
   i: loopint;

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
      if(oxedProject.Units.n > 0) then begin
         Result := Result + ',';
         Result.Add('{units}');

         for i := 0 to oxedProject.Units.n - 1 do begin
            if(i < oxedProject.Units.n - 1) then
               Result.Add('   ' + oxedProject.Units.List[i].Name + ',')
            else
               Result.Add('   ' + oxedProject.Units.List[i].Name);
         end;
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

   FileUtils.WriteString(oxedProject.TempPath + oxPROJECT_MAIN_SOURCE, p);
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

   fn := oxedProject.TempPath + oxPROJECT_LIB_SOURCE + '.tmp';

   FileUtils.WriteString(fn, p);

   target := oxedProject.TempPath + oxPROJECT_LIB_SOURCE;

   if(CompareAndReplace(fn, target)) then
      log.v('Recreated ' + target);
end;

function ShouldRecreate(const fn: string): boolean;
begin
   Result := (FileUtils.Exists(oxedProject.TempPath + fn) <= 0) or (oxedBuild.BuildType = OXED_BUILD_TASK_REBUILD);
end;

function Recreate(): boolean;
begin
   oxedProject.RecreateTempDirectory();

   if(ShouldRecreate(oxPROJECT_APP_INFO_INCLUDE)) then
      RecreateAppInfo();

   {check if main unit exists}
   if(oxedProject.MainUnit <> '') then begin
      if(oxedProject.Units.Find(oxedProject.MainUnit) = nil) then begin
         oxedMessages.e('Specified main unit ' + oxedProject.MainUnit + ' not found.');
         exit(false);
      end;
   end;

   {recreate library}
   if(oxedBuild.BuildTarget = OXED_BUILD_LIB) then begin
      if(ShouldRecreate(oxPROJECT_LIB_SOURCE)) then
         RecreateLib();

      if(ShouldRecreate(oxPROJECT_LIB_LPI)) then begin
         if(not RecreateLPI(true)) then begin
            oxedMessages.e('Failed to create project library lpi file. lpi error: ' + sf(lpi.Error));
            exit(false);
         end;
      end;
   {recreate standalone project}
   end else if(oxedBuild.BuildTarget = OXED_BUILD_STANDALONE) then begin
      if(ShouldRecreate(oxPROJECT_MAIN_SOURCE)) then
         RecreateProgram();

      if(ShouldRecreate(oxPROJECT_MAIN_LPI)) then begin
         if(not RecreateLPI(false)) then begin
            oxedMessages.e('Failed to create project lpi file. lpi error: ' + sf(lpi.Error));
            exit(false);
         end;
      end;
   end;

   Result := true;
end;

procedure BuildLPI(const whichLpi: string);
begin
   if(not oxedBuild.Buildable(true)) then
      exit;

   uBuild.build.Laz(oxedProject.TempPath + whichLpi);
end;

procedure DoBuild();
var
   modeString,
   targetString: string;

begin
   if(not oxedBuild.Buildable(true)) then
      exit;

   oxedBuild.BuildStart := Now;

   if(not oxedProject.Valid()) then
      exit;

   {if we're missing everything, rebuild}
   if(not FileUtils.DirectoryExists(oxedProject.TempPath)) then
      oxedBuild.BuildType := OXED_BUILD_TASK_REBUILD;

   if(oxedBuild.BuildType = OXED_BUILD_TASK_REBUILD) then
      modeString := 'rebuild'
   else
      modeString := 'recode';

   if(oxedBuild.BuildTarget = OXED_BUILD_LIB) then
      targetString := 'lib'
   else
      targetString := 'standalone';

   oxedMessages.i(modeString + ' started (' + targetString + ')');

   if(not Recreate()) then begin
      oxedMessages.e('Failed to recreate project files');
      exit;
   end;

   uBuild.build.Options.IsLibrary := oxedBuild.BuildTarget = OXED_BUILD_LIB;

   if(uBuild.build.Options.IsLibrary) then
      BuildLPI(oxPROJECT_LIB_LPI)
   else
      BuildLPI(oxPROJECT_MAIN_LPI);

   if(build.Output.Success) then begin
      oxedMessages.k(modestring + ' success (elapsed: ' + sf(oxedBuild.BuildStart.Elapsedf(), 2) + 's)');
   end else
      oxedMessages.e(modestring + ' failed (elapsed: ' + sf(oxedBuild.BuildStart.Elapsedf(), 2) + 's)');

   {if successful rebuild, we've made an initial build}
   oxedProject.Session.InitialBuildDone := true;
end;

procedure RebuildThirdParty();
var
   modeString,
   targetString: string;

begin
   if(not oxedBuild.Buildable(true)) then
      exit;

   oxedBuild.BuildStart := Now;

   {if we're missing everything, rebuild}
   if(not FileUtils.DirectoryExists(oxedProject.TempPath)) then
      oxedBuild.BuildType := OXED_BUILD_TASK_REBUILD;

   if(oxedBuild.BuildType = OXED_BUILD_TASK_REBUILD) then
      modeString := 'rebuild'
   else if(oxedBuild.BuildType = OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then
      modeString := 'third party rebuild'
   else
      modeString := 'recode';

   if(oxedBuild.BuildTarget = OXED_BUILD_LIB) then
      targetString := 'lib'
   else
      targetString := 'standalone';

   oxedMessages.i(modeString + ' started (' + targetString + ')');

   if(not Recreate()) then begin
      oxedMessages.e('Failed to recreate project files');
      exit;
   end;

   if(oxedBuild.BuildTarget = OXED_BUILD_LIB) then
      BuildLPI(oxPROJECT_LIB_LPI)
   else
      BuildLPI(oxPROJECT_MAIN_LPI);

   if(build.Output.Success) then
      oxedMessages.k(modestring + ' success (elapsed: ' + sf(oxedBuild.BuildStart.Elapsedf(), 2) + 's)')
   else
      oxedMessages.e(modestring + ' failed (elapsed: ' + sf(oxedBuild.BuildStart.Elapsedf(), 2) + 's)');
end;

procedure DoCleanup();
begin
   if(FileUtils.DirectoryExists(oxedProject.TempPath)) then begin
      if(FileUtils.RmDir(oxedProject.TempPath)) then
         oxedMessages.i('Cleanup finished')
      else
         oxedMessages.w('Failed to remove temporary files');
   end else
      oxedMessages.i('Seems to be already clean');
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

procedure oxedTBuildGlobal.RunTask(taskType: oxedTBuildTaskType);
begin
   if(not oxedBuild.Buildable(true)) then
      exit;

   BuildType := taskType;

   {determine if we need third party units}
   oxedBuild.IncludeThirdParty := (not oxedProject.Session.ThirdPartyBuilt) or oxedProject.Session.IncludeThirdPartyUnits;
   log.v('Third party units included: ' + sf(oxedBuild.IncludeThirdParty));

   {rebuild instead of recode if initial build not done}
   if(BuildType = OXED_BUILD_TASK_RECODE) and (not oxedProject.Session.InitialBuildDone) and (oxedSettings.RequireRebuildOnOpen) then begin
      oxedMessages.i('Rebuild instead of recode on initial build');
      BuildType := OXED_BUILD_TASK_REBUILD;
   end;

   if(BuildType = OXED_BUILD_TASK_RECODE) then begin
      build.Options.Rebuild := false;
      DoBuild()
   end else if(BuildType = OXED_BUILD_TASK_REBUILD) then begin
      build.Options.Rebuild := true;
      DoBuild();
   end else if(BuildType = OXED_BUILD_TASK_CLEANUP) then
      DoCleanup()
   else if(BuildType = OXED_BUILD_TASK_RECREATE) then
      Recreate()
   else if(BuildType = OXED_BUILD_TASK_REBUILD_THIRD_PARTY) then begin
      oxedBuild.IncludeThirdParty := true;
      build.Options.Rebuild := true;
      RebuildThirdParty();
      oxedProject.Session.ThirdPartyBuilt := true;
   end;
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

VAR
   laz: TProcess;
   openLazarusFlag: boolean = false;

procedure openLazarusAfterRecreate();
begin
   if(openLazarusFlag) then begin
      openLazarusFlag := false;

      if(oxedBuild.BuildType <> OXED_BUILD_TASK_RECREATE) then
         exit;

      try
         laz.Options := laz.Options - [poWaitOnExit];

         if(Recreate()) then
            laz.Execute();
      except
         on e : Exception  do begin
            oxedMessages.e('Failed to run Lazarus ' + e.ToString());
         end;
      end;
   end;
end;

class procedure oxedTBuildGlobal.OpenLazarus();
begin
   if(oxedProjectValid()) then begin
      if(laz = nil) then begin
         laz := TProcess.Create(nil);
         laz.Executable := build.GetLazarusStartExecutable();
      end;

      if(not laz.Running) then begin
         laz.Parameters.Clear();
         laz.Parameters.Add('--no-splash-screen');
         laz.Parameters.Add('--force-new-instance');
         laz.Parameters.Add(oxedProject.TempPath + oxPROJECT_LIB_LPI);
      end else
         exit;

      {first recreate files}
      RecreateTask();
      openLazarusFlag := true;
   end;
end;

class procedure oxedTBuildGlobal.OpenProjectDirectory();
begin
   app.OpenFileManager(oxedProject.Path);
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

   TProcedures.Initialize(oxedBuild.OnPreBuild);
   TProcedures.Initialize(oxedBuild.OnBuildDone);

   oxedBuild.BuildTarget := OXED_BUILD_LIB;
   oxedBuild.OnBuildDone.Add(@openLazarusAfterRecreate);

   oxedActions.BUILD := appActionEvents.SetCallback(@oxedBuild.RebuildTask);
   oxedActions.RECODE := appActionEvents.SetCallback(@oxedBuild.RecodeTask);
   oxedActions.CLEANUP := appActionEvents.SetCallback(@oxedBuild.CleanupTask);
   oxedActions.REBUILD_THIRD_PARTY := appActionEvents.SetCallback(@oxedBuild.RebuildThirdPartyTask);

   oxedActions.OPEN_LAZARUS := appActionEvents.SetCallback(@oxedBuild.OpenLazarus);
   oxedActions.OPEN_PROJECT_DIRECTORY := appActionEvents.SetCallback(@oxedBuild.OpenProjectDirectory);

   oxedProjectScanner.OnDone.Add(@onScanDone);

END.