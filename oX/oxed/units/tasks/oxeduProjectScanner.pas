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
      oxuRunRoutines, oxuThreadTask, oxuRun,
      {oxed}
      uOXED, oxeduPackage, oxeduProject, oxeduProjectManagement, oxeduTasks, oxeduActions;

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

   {ignore stuff in the temp directory}
   if(Pos(oxPROJECT_TEMP_DIRECTORY, fd.f.Name) = 1) then
      exit;

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
begin
   Result := true;

   {ignore project config directory}
   if(fd.f.Name = oxedProject.Path + oxPROJECT_DIRECTORY) then
      exit(false);

   {ignore project temporary directory}
   if(fd.f.Name = oxedProject.Path + oxPROJECT_TEMP_DIRECTORY) then
      exit(false);
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
begin
   inherited;

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

   // wait to stop running
   while(oxedProjectScanner.Walker.Running) do begin
      oxRun.Sleep(1);
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
