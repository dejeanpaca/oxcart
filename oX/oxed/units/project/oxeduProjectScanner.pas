{
   oxeduProjectScanner, project scanning
   Copyright (C) 2017. Dejan Boras

   Started On:    24.08.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectScanner;

INTERFACE

   USES
      sysutils, uStd, uLog, StringUtils, uFileUtils, uBuild,
      {app}
      appuRun, appuActionEvents,
      {ox}
      oxuThreadTask,
      {oxed}
      uOXED, oxeduProject, oxeduProjectManagement, oxeduTasks, oxeduActions, oxeduPasScanner;

TYPE
   { oxedTProjectScannerTask }

   oxedTProjectScannerTask = class(oxedTTask)
      constructor Create(); override;
      procedure Run(); override;

      procedure TaskStart(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   { oxedTProjectScannerGlobal }

   oxedTProjectScannerGlobal = record
      Walker: TFileTraverse;
      Task: oxedTProjectScannerTask;

      OnStart,
      OnDone: TProcedures;

      procedure Run();
      class procedure Initialize(); static;
      class procedure RunTask(); static;
   end;

VAR
   oxedProjectScanner: oxedTProjectScannerGlobal;

IMPLEMENTATION

function scanFile(const fn: string): boolean; forward;

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
      Walker := TFileTraverse.Create();
      Walker.AddExtension('.pas');
      Walker.AddExtension('.inc');

      Walker.onFile := @scanFile;

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
begin
   inherited Run;

   log.v('Project scan started ...');

   try
     oxedProjectScanner.Walker.Run();
   except
      on e: Exception do begin
         log.e('Project scanner failed running');
         log.e(DumpExceptionCallStack(e));
      end;
   end;

   oxedProject.Session.InitialScanDone := true;
   log.v('Done project scan');
end;

procedure oxedTProjectScannerTask.TaskStart();
begin
   inherited TaskStart;

   oxedProject.Units.Dispose();
   oxedProject.IncludeFiles.Dispose();

   oxedPasScanner.fpcCommandLine := build.GetFPCCommandLine();
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

function scanFile(const fn: string): boolean;
var
   unitFile: oxedTProjectUnit;
   ext: string;
   pasResult: oxedTPasScanResult;

begin
   Result := true;

   {ignore stuff in the temp directory}
   if(Pos(oxPROJECT_TEMP_DIRECTORY, fn) = 1) then
      exit;

   ext := ExtractFileExt(fn);
   unitFile.Name := ExtractFileNameNoExt(fn);
   unitFile.Path := fn;

   if(oxedProjectScanner.Task.Terminated) then
      Result := false;

   if(ext = '.pas') or (ext = '.pp') then begin
      pasResult := oxedPasScanner.Scan(fn);

      if(pasResult.IsUnit) then
         oxedProject.Units.Add(unitFile);
   end else if(ext = '.inc') then
      oxedProject.IncludeFiles.Add(unitFile);

   if(oxedProjectScanner.Task.Terminated) then
      Result := false;
end;

procedure deinit();
begin
   FreeObject(oxedProjectScanner.Walker);
   FreeObject(oxedProjectScanner.Task);
end;

procedure projectClosed();
begin
   oxedProjectScanner.Walker.Stop();

   // wait to stop running
   while(oxedProjectScanner.Walker.Running) do begin
      appRun.Sleep(1);
   end;
end;

procedure projectOpen();
begin
   projectClosed();

   oxedProjectScanner.Run();
end;

INITIALIZATION
   oxed.Init.Add('project_scanner', @oxedProjectScanner.Initialize, @deinit);

   TProcedures.Initialize(oxedProjectScanner.OnStart);
   TProcedures.Initialize(oxedProjectScanner.OnDone);

   oxedProjectManagement.OnProjectOpen.Add(@projectOpen);
   oxedProjectManagement.OnProjectClosed.Add(@projectClosed);

   oxedActions.RESCAN := appActionEvents.SetCallback(@oxedProjectScanner.RunTask);

END.
