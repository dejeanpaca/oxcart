{
   oxeduTasks, oxed tasks management
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduTasks;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines, oxuThreadTask, oxuThreadJobs,
      {oxed}
      uOX, uOXED;

TYPE
   { oxedTBaseTask }

   oxedTBaseTask = class
   end;

   { oxedTTask }

   oxedTTask = class(oxTRoutineThreadTask)
      {this task runs in the background and does not block other operations}
      Background: boolean;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   oxedTThreadTasksList = specialize TSimpleList<oxedTTask>;

   { oxedTTasks }

   oxedTTasks = record
      List: oxedTThreadTasksList;

      OnTaskDone,
      OnTaskStart: TProcedures;

      PrimaryTasks: oxTTaskQueue;

      procedure Add(task: oxedTTask);
      procedure Remove(task: oxedTTask);
      procedure TaskStarted(task: oxedTTask);
      procedure TaskDone(task: oxedTTask);

      {queue a task to the primary queue}
      procedure Queue(task: oxedTTask);

      {are any tasks of the specified type running}
      function Running(taskType: TClass; exceptType: TClass = nil; foregroundOnly: boolean = true): loopint;
      {how many tasks are running (and whether foreground only are couned)}
      function RunningCount(foregroundOnly: boolean = true): loopint;
   end;

VAR
   oxedTasks: oxedTTasks;

IMPLEMENTATION

{ oxedTTask }

constructor oxedTTask.Create();
begin
   inherited;

   SingleRun := true;
   Background := false;
   TaskType := oxedTBaseTask;

   SleepTime := 5;

   oxedTasks.Add(Self);
end;

destructor oxedTTask.Destroy();
begin
   inherited Destroy;

   oxedTasks.Remove(Self);
end;

procedure oxedTTask.ThreadStart();
begin
   oxedTasks.TaskStarted(Self);
end;

procedure oxedTTask.ThreadDone();
begin
   oxedTasks.TaskDone(Self);
end;

{ oxedTTasks }

procedure oxedTTasks.Add(task: oxedTTask);
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i] = task) then
         exit;
   end;

   List.Add(task);
end;

procedure oxedTTasks.Remove(task: oxedTTask);
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i] = task) then begin
         List.Remove(i);
         exit;
      end;
   end;
end;

procedure oxedTTasks.TaskStarted(task: oxedTTask);
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i] = task) then begin
         OnTaskStart.Call();
      end;
   end;
end;

procedure oxedTTasks.TaskDone(task: oxedTTask);
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i] = task) then begin
         OnTaskDone.Call();
      end;
   end;
end;

procedure oxedTTasks.Queue(task: oxedTTask);
begin
   PrimaryTasks.QueueAdd(task);
end;

function oxedTTasks.Running(taskType: TClass; exceptType: TClass; foregroundOnly: boolean): loopint;
 var
    i: loopint;

begin
   Result := 0;

   for i := 0 to List.n - 1 do begin
      if(foregroundOnly and List.List[i].Background) then
         continue;

      if(oxTThreadTask.IsRunning(List.List[i])) then begin
         {task matches task type}
         if(taskType <> nil) and (taskType = List.List[i].ClassType) then
            inc(Result)
         {task is not the exception}
         else if(taskType = nil) and (List.List[i].ClassType <> exceptType) then
            inc(Result);
      end;
   end;
end;

function oxedTTasks.RunningCount(foregroundOnly: boolean): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to List.n - 1 do begin
      if(foregroundOnly and List.List[i].Background) then
         continue;

      if List.List[i].IsRunning() then
         inc(Result);
   end;
end;

procedure init();
begin
   oxedTasks.PrimaryTasks.Initialize();
end;

procedure deinit();
begin
   oxedTasks.PrimaryTasks.DeInitialize();
   oxedTasks.List.Dispose();
end;

procedure update();
begin
   oxedTasks.PrimaryTasks.Update();
end;

INITIALIZATION
   oxed.Init.Add('oxed.tasks', @init, @deinit);

   oxedTasks.List.InitializeValues(oxedTasks.List);

   TProcedures.InitializeValues(oxedTasks.OnTaskDone);
   TProcedures.InitializeValues(oxedTasks.OnTaskStart);

   ox.OnRun.Add('oxed.tasks', @update);

END.
