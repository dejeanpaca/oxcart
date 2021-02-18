{
   oxeduProjectScanner, project scanning
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectScanner;

INTERFACE

   USES
      sysutils, uStd, uLog, uFileUtils, uFileTraverse, uBuild,
      {app}
      appuActionEvents,
      {ox}
      oxuRunRoutines, oxuThreadTask, oxuTimer,
      {oxed}
      uOXED,
      oxeduPackage, oxeduPackageTypes,
      oxeduProject, oxeduProjectManagement, oxeduTasks, oxeduActions,
      oxeduAssets, oxeduProjectWalker;

TYPE
   { oxedTProjectScannerTask }

   oxedTProjectScannerTask = class(oxedTTask)
      constructor Create(); override;
      procedure Run(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   { oxedTProjectScanner }

   oxedTProjectScanner = class(oxedTProjectWalker)
      Task: oxedTProjectScannerTask;

      constructor Create(); override;

      procedure Scan();
      class procedure RunTask(); static;

      protected
         function HandlePackage(var {%H-}package: oxedTPackage): boolean; override;
         function HandleDirectory(var dir: StdString; const fd: TFileTraverseData): boolean; override;
   end;

VAR
   oxedProjectScanner: oxedTProjectScanner;

IMPLEMENTATION

{ oxedTProjectScanner }

constructor oxedTProjectScanner.Create();
begin
   inherited Create();

   Task := oxedTProjectScannerTask.Create();
   Task.EmitAllEvents();
end;

procedure oxedTProjectScanner.Scan();
begin
   if(oxTThreadTask.IsRunning(Task)) then begin
      log.w('Project scanner already running');
      exit();
   end;

   Task.Start();
end;

class procedure oxedTProjectScanner.RunTask();
begin
   oxedProjectScanner.Scan();
end;

function oxedTProjectScanner.HandlePackage(var package: oxedTPackage): boolean;
begin
   Result := true;
   log.v('Scanning: ' + oxedProjectScanner.Current.Path);
end;

function oxedTProjectScanner.HandleDirectory(var dir: StdString; const fd: TFileTraverseData): boolean;
var
   path: oxedPPackagePath;

begin
   Result := true;

   {load package path properties if we have any}
   if(FileExists(fd.f.Name + DirSep + OX_PACKAGE_PROPS_FILE_NAME)) then begin
      path := Current.Package^.Paths.Get(dir);
      path^.LoadPathProperties(oxedProjectScanner.Current.Path);
   end;
end;

{ oxedTProjectScannerTask }

constructor oxedTProjectScannerTask.Create();
begin
   inherited;

   Name := 'Project Scanner';
end;

procedure oxedTProjectScannerTask.Run();
begin
   inherited Run;

   log.v('Project scan started ...');

   oxedProjectScanner.Run();

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

procedure initialize();
begin
   oxedProjectScanner := oxedTProjectScanner.Create();
end;

procedure deinitialize();
begin
   if(oxedProjectScanner <> nil) then
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

   oxedProjectScanner.Scan();
end;

INITIALIZATION
   oxed.Init.Add('project_scanner', @initialize, @deinitialize);

   oxedProjectManagement.OnOpen.Add(@projectOpen);
   oxedProjectManagement.OnClosed.Add(@projectClosed);

   oxedActions.RESCAN := appActionEvents.SetCallback(@oxedProjectScanner.RunTask);

END.
