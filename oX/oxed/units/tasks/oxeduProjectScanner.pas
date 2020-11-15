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

   { oxedTProjectScannerGlobal }

   oxedTProjectScannerGlobal = record
      Walker: TFileTraverse;
      Task: oxedTProjectScannerTask;

      CurrentPackage: oxedPPackage;
      CurrentPath: StdString;

      OnStart,
      OnDone: TProcedures;
      OnFile: oxedTProjectScannerFileProcedures;

      procedure Run();
      class procedure Initialize(); static;
      class procedure RunTask(); static;
   end;

VAR
   oxedProjectScanner: oxedTProjectScannerGlobal;

IMPLEMENTATION

function scanFile(const fd: TFileTraverseData): boolean;
var
   ext: StdString;
   f: oxedTScannerFile;

begin
   Result := true;

   ext := ExtractFileExt(fd.f.Name);
   f.FileName := fd.f.Name;
   f.Extension := ext;
   f.fd := fd.f;

   f.Package := oxedProjectScanner.CurrentPackage;
   f.PackagePath := oxedProjectScanner.CurrentPath;
   f.PackageFileName := ExtractRelativepath(f.PackagePath, f.FileName);
   f.ProjectFileName := oxedProject.GetPackageRelativePath(f.Package^) + f.PackageFileName;

   oxedProjectScanner.OnFile.Call(f);

   if(oxedProjectScanner.Task.Terminated) then
      exit(false);
end;

function onDirectory(const fd: TFileTraverseData): boolean;
var
   packagePath: StdString;
   path: oxedPPackagePath;

begin
   Result := true;

   {ignore project config directory}
   if(fd.f.Name = oxedProject.Path + oxPROJECT_DIRECTORY) then
      exit(false);

   {ignore project temporary directory}
   if(fd.f.Name = oxedProject.Path + oxPROJECT_TEMP_DIRECTORY) then
      exit(false);

   {load package path properties if we have any}
   if(FileExists(fd.f.Name + DirectorySeparator + OX_PACKAGE_PROPS_FILE_NAME)) then begin
      packagePath := ExtractRelativepath(oxedProjectScanner.CurrentPath, fd.f.Name);
      path := oxedProjectScanner.CurrentPackage^.Paths.Get(packagePath);
      path^.LoadPathProperties(oxedProjectScanner.CurrentPath);
   end;
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

{ TBuildTask }

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
   oxedProjectScanner.CurrentPackage := @p;
   oxedProjectScanner.CurrentPath := oxedProject.GetPackagePath(p);

   log.v('Scanning: ' + oxedProjectScanner.CurrentPath);
   oxedProjectScanner.Walker.Run(oxedProjectScanner.CurrentPath);
end;

begin
   inherited Run;

   log.v('Project scan started ...');

   try
      scanPackage(oxedAssets.oxPackage);
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

   oxedProjectScanner.CurrentPackage := nil;

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
