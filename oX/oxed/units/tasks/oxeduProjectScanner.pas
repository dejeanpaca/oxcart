{
   oxeduProjectScanner, project scanning
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectScanner;

INTERFACE

   USES
      sysutils, uStd, uError, uLog, StringUtils, uFileUtils, uBuild,
      {app}
      appuActionEvents,
      {ox}
      oxuRunRoutines, oxuThreadTask, oxuTimer,
      {oxed}
      uOXED,
      oxeduPackage, oxeduPackageTypes,
      oxeduProject, oxeduProjectManagement, oxeduTasks, oxeduActions,
      oxeduAssets;

TYPE
   { oxedTProjectScannerTask }

   oxedTProjectScannerTask = class(oxedTTask)
      constructor Create(); override;
      procedure Run(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   oxedTScannerFile = record
      {complete file name (including package path)}
      FileName,
      {file name within the package}
      PackageFileName,
      {file name relative to the project path}
      ProjectFileName,
      {file extension}
      Extension,
      {path of the package}
      PackagePath: StdString;

      Package: oxedPPackage;

      fd: TFileDescriptor;
   end;

   oxedTProjectScannerFileProcedure = procedure(var f: oxedTScannerFile);
   oxedTProjectScannerFileProcedures = specialize TSimpleList<oxedTProjectScannerFileProcedure>;

   { oxedTScannerOnFileProceduresHelper }

   oxedTScannerOnFileProceduresHelper = record helper for oxedTProjectScannerFileProcedures
      procedure Call(var f: oxedTScannerFile);
   end;

   { oxedTProjectScannerCurrent }

   {holds information about the current state of the project scanner while a scan is done}
   oxedTProjectScannerCurrent = record
      Package: oxedPPackage;
      Path: StdString;

      procedure FormFile(out f: oxedTScannerFile; const fd: TFileDescriptor);
   end;

   { oxedTProjectScannerGlobal }

   oxedTProjectScannerGlobal = record
      Walker: TFileTraverse;
      Task: oxedTProjectScannerTask;

      Current: oxedTProjectScannerCurrent;

      OnStart,
      OnDone: TProcedures;
      OnFile: oxedTProjectScannerFileProcedures;

      procedure Run();
      class procedure Initialize(); static;
      class procedure RunTask(); static;

      {checks if the path is valid (not ignored or excluded)}
      function ValidPath(const packagePath, fullPath: StdString): Boolean;
      {get valid path}
      function GetValidPath(const basePath, fullPath: StdString): StdString;
   end;

VAR
   oxedProjectScanner: oxedTProjectScannerGlobal;

IMPLEMENTATION

function scanFile(const fd: TFileTraverseData): boolean;
var
   f: oxedTScannerFile;

begin
   Result := true;

   oxedProjectScanner.Current.FormFile(f, fd.f);

   oxedProjectScanner.OnFile.Call(f);

   if(oxedProjectScanner.Task.Terminated) then
      exit(false);
end;

function onDirectory(const fd: TFileTraverseData): boolean;
var
   dir: StdString;
   path: oxedPPackagePath;

begin
   Result := true;

   dir := oxedProjectScanner.GetValidPath(oxedProjectScanner.Current.Path, fd.f.Name);

   if(dir <> '') then begin
      {load package path properties if we have any}
      if(FileExists(fd.f.Name + DirSep + OX_PACKAGE_PROPS_FILE_NAME)) then begin
         path := oxedProjectScanner.Current.Package^.Paths.Get(dir);
         path^.LoadPathProperties(oxedProjectScanner.Current.Path);
      end;
   end else
      Result := false;
end;

{ oxedTProjectScannerCurrent }

procedure oxedTProjectScannerCurrent.FormFile(out f: oxedTScannerFile; const fd: TFileDescriptor);
begin
   ZeroOut(f, SizeOf(f));

   f.FileName := fd.Name;
   f.Extension := ExtractFileExt(fd.Name);
   f.fd := fd;

   f.Package := Package;
   f.PackagePath := Path;
   f.PackageFileName := ExtractRelativepath(f.PackagePath, f.FileName);
   f.ProjectFileName := oxedProject.GetPackageRelativePath(f.Package^) + f.PackageFileName;
end;

{ oxedTScannerOnFileProceduresHelper }

procedure oxedTScannerOnFileProceduresHelper.Call(var f: oxedTScannerFile);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](f);
   end;
end;

{ oxedTProjectScannerGlobal }

procedure oxedTProjectScannerGlobal.Run();
begin
   if(oxTThreadTask.IsRunning(Task)) then begin
      log.w('Project scanner already running');
      exit();
   end;

   Task.Start();
end;

class procedure oxedTProjectScannerGlobal.Initialize();
begin
   with oxedProjectScanner do begin
      TFileTraverse.Initialize(Walker);

      Walker.OnFile:= @scanFile;
      Walker.OnDirectory := @onDirectory;

      Task := oxedTProjectScannerTask.Create();
      Task.EmitAllEvents();
   end;
end;

class procedure oxedTProjectScannerGlobal.RunTask();
begin
   oxedProjectScanner.Run();
end;

function oxedTProjectScannerGlobal.ValidPath(const packagePath, fullPath: StdString): Boolean;
begin
   Result := true;

   {ignore project config directory}
   if(packagePath = oxPROJECT_DIRECTORY) then
      exit(false);

   {ignore project temporary directory}
   if(packagePath = oxPROJECT_TEMP_DIRECTORY) then
      exit(false);

   {ignore folder if .noassets file is declared in it}
   if FileUtils.Exists(fullPath + DirSep + OX_NO_ASSETS_FILE) >= 0 then
      exit(False);

   {ignore directory if included in ignore lists}
   if(oxedAssets.ShouldIgnoreDirectory(packagePath)) then
      exit(False);
end;

function oxedTProjectScannerGlobal.GetValidPath(const basePath, fullPath: StdString): StdString;
begin
   Result := Copy(fullPath, Length(basePath) + 1, Length(fullPath));

   if(not oxedProjectScanner.ValidPath(Result, fullPath)) then
      exit('');
end;

{ oxedTProjectScannerTask }

constructor oxedTProjectScannerTask.Create();
begin
   inherited;

   Name := 'Project Scanner';
end;

procedure oxedTProjectScannerTask.Run();
var
   i: loopint;

procedure scanPackage(var p: oxedTPackage);
begin
   oxedProjectScanner.Current.Package := @p;
   oxedProjectScanner.Current.Path := oxedProject.GetPackagePath(p);

   log.v('Scanning: ' + oxedProjectScanner.Current.Path);
   oxedProjectScanner.Walker.Run(oxedProjectScanner.Current.Path);
end;

begin
   inherited Run;

   log.v('Project scan started ...');

   try
      scanPackage(oxedAssets.oxPackage);
      scanPackage(oxedAssets.oxDataPackage);
      scanPackage(oxedProject.MainPackage);

      for i := 0 to oxedProject.Packages.n - 1 do begin
         scanPackage(oxedProject.Packages.List[i]);
      end;
   except
      on e: Exception do begin
         log.e('Project scanner failed running');
         log.e(DumpExceptionCallStack(e));
      end;
   end;

   oxedProjectScanner.Current.Package := nil;

   oxedProject.Session.InitialScanDone := true;
   log.v('Done project scan');
end;

procedure oxedTProjectScannerTask.ThreadStart();
var
   i: loopint;

begin
   inherited;

   oxedProject.MainPackage.DisposeList();
   oxedAssets.oxPackage.DisposeList();

   for i := 0 to oxedProject.Packages.n - 1 do begin
      oxedProject.Packages.List[i].DisposeList();
   end;

   oxedProjectScanner.OnStart.Call();
end;

procedure oxedTProjectScannerTask.ThreadDone();
begin
   inherited;

   oxedProjectScanner.OnDone.Call();
end;

procedure deinit();
begin
   FreeObject(oxedProjectScanner.Task);
end;

procedure projectClosed();
begin
   oxedProjectScanner.Walker.Stop();

   {wait to stop running}
   while(oxedProjectScanner.Walker.Running) do begin
      oxTimer.SloppySleep(1);
   end;
end;

procedure projectOpen();
begin
   projectClosed();

   oxedProjectScanner.Run();
end;

INITIALIZATION
   oxed.Init.Add('project_scanner', @oxedProjectScanner.Initialize, @deinit);

   TProcedures.InitializeValues(oxedProjectScanner.OnStart);
   TProcedures.InitializeValues(oxedProjectScanner.OnDone);
   oxedTProjectScannerFileProcedures.InitializeValues(oxedProjectScanner.OnFile);

   oxedProjectManagement.OnOpen.Add(@projectOpen);
   oxedProjectManagement.OnClosed.Add(@projectClosed);

   oxedActions.RESCAN := appActionEvents.SetCallback(@oxedProjectScanner.RunTask);

END.
