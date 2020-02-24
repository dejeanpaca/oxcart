{
   oxeduTestsPlugin, test framework
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduTestsPlugin;

INTERFACE

   USES
      uStd, uLog, uFileUtils, uBuild, StringUtils, sysutils, udvars,
      {tests}
      uTest, uTestRunner,
      {ox}
      oxuRunRoutines, oxuThreadTask,
      {oxed}
      uOXED, oxeduPlugins, oxeduTasks, oxeduProject;

TYPE
   oxedTTestTaskType = (
      OXED_TEST_TASK_SCAN,
      OXED_TEST_TASK_RUN
   );

   { oxedTTestsTask }

   oxedTTestsTask = class(oxedTTask)
      constructor Create(); override;
      procedure Run(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   { oxedTTests }

   oxedTTests = record
      {list of paths in which to run tests}
      Paths: TSimpleStringList;
      Task: oxedTTestsTask;
      TaskType: oxedTTestTaskType;

      OnTaskStart: TProcedures;
      OnTaskDone: TProcedures;

      {include oX engine tests}
      IncludeOx: boolean;

      procedure AddPath(const path: StdString);

      {run a specific task}
      procedure RunTask(typeOfTask: oxedTTestTaskType);
      {start new task}
      procedure StartTask(typeOfTask: oxedTTestTaskType);

      {can a task currently be run}
      function CanTask(ttype: oxedTTestTaskType): boolean;
      {can test tasks be done}
      function CanTest(ttype: oxedTTestTaskType): boolean;

      {run scan task}
      procedure Scan();
      {run tests task}
      procedure RunTests();

      {get path for oX tests}
      function GetOXPAth(): StdString;
   end;

VAR
   oxedTests: oxedTTests;

IMPLEMENTATION

VAR
   dvgTests: TDVarGroup;
   dvIncludeOx: TDVar;

{ oxedTTestsTask }

constructor oxedTTestsTask.Create();
begin
   inherited Create;

   Name := 'Tests';
end;

procedure oxedTTestsTask.Run();
begin
   inherited Run;

   oxedTests.RunTask(oxedTests.TaskType);
end;

procedure oxedTTestsTask.ThreadStart();
begin
   inherited;

   oxedTests.OnTaskStart.Call();
end;

procedure oxedTTestsTask.ThreadDone();
begin
   inherited;

   oxedTests.OnTaskDone.Call();
end;

{ oxedTTests }

procedure oxedTTests.AddPath(const path: StdString);
var
   properPath: StdString;

begin
   if(path <> '') then begin
      properPath := path;
      FileUtils.NormalizePathEx(properPath);

      Paths.Add(properPath);
      log.v('Added tests path: ' + properPath);
   end;
end;

procedure oxedTTests.RunTask(typeOfTask: oxedTTestTaskType);
var
   i: loopint;
   dir: StdString;

begin
   if(not CanTest(typeOfTask)) then
      exit;

   TaskType := typeOfTask;
   TestRunner.CurrentDirectory := false;
   UnitTests.SelfTest := true;

   if(TaskType = OXED_TEST_TASK_SCAN) then begin
      UnitTests.InfoMode := TaskType = OXED_TEST_TASK_SCAN;
      UnitTests.Destroy();
   end;

   dir := GetOXPAth();

   if(oxedTests.IncludeOx) then begin
      if(oxedTests.Paths.FindString(dir) = -1) then
         oxedTests.Paths.Add(dir);

      log.v('Included ox tests from ' + dir);
   end else begin
      i := oxedTests.Paths.Find(dir);

      if(i > -1) then
         oxedTests.Paths.Remove(i);
   end;

   if(Paths.n > 0) then begin
      for i := 0 to Paths.n - 1 do begin
         dir := Paths.List[i];
         TestRunner.Directory := ExcludeTrailingPathDelimiter(dir);

         if(TaskType = OXED_TEST_TASK_SCAN) then
            log.v('Scanning tests in ' + dir)
         else if(TaskType = OXED_TEST_TASK_RUN) then
            log.v('Running tests in ' + dir);

         TestRunner.Run();
      end;
   end else begin
      log.v('No paths for tests');
   end;

   if(TaskType = OXED_TEST_TASK_SCAN) then begin
      log.v('Found ' + sf(UnitTests.Pool.GroupCount()) + ' test groups');
   end else
      log.v('Done running tests');
end;

procedure oxedTTests.StartTask(typeOfTask: oxedTTestTaskType);
begin
   if(not CanTask(typeOfTask)) then
      exit;

   TaskType := typeOfTask;

   Task.Start();
end;

function oxedTTests.CanTask(ttype: oxedTTestTaskType): boolean;
begin
   Result := CanTest(ttype) and (not oxTThreadTask.IsRunning(Task));
end;

function oxedTTests.CanTest(ttype: oxedTTestTaskType): boolean;
begin
   if(ttype = OXED_TEST_TASK_SCAN) then
      Result := true
   else
      Result := (oxedTests.Paths.n > 0) or (oxedTests.IncludeOx);
end;

procedure oxedTTests.Scan();
begin
   StartTask(OXED_TEST_TASK_SCAN);
end;

procedure oxedTTests.RunTests();
begin
   StartTask(OXED_TEST_TASK_RUN);
end;

function oxedTTests.GetOXPAth(): StdString;
begin
   Result := GetParentDirectory(build.Tools.Build);
end;

procedure init();
begin
   oxedTests.Task := oxedTTestsTask.Create();
   oxedTests.Task.EmitAllEvents();
end;

procedure deinit();
begin
   oxedTests.Paths.Dispose();
   TestRunner.Destroy();
   FreeObject(oxedTests.Task);
end;

INITIALIZATION
   dvgOXED.Add('tests', dvgTests);
   dvgTests.Add(dvIncludeOx, 'include_ox', dtcBOOL, @oxedTests.IncludeOx);

   oxedTests.Paths.InitializeValues(oxedTests.Paths);
   TProcedures.InitializeValues(oxedTests.OnTaskStart);
   TProcedures.InitializeValues(oxedTests.OnTaskDone);

   oxed.Init.Add('plugin.tests', @init, @deinit);
   oxedPlugins.Add('Tests', 'Testing framework');

END.
