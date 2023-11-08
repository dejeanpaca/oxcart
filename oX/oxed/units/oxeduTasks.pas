{
   oxeduTasks, oxed tasks management
   Copyright (C) 2017. Dejan Boras

   Started On:    08.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduTasks;

INTERFACE

   USES
      uStd,
      {ox}
      oxuThreadTask,
      {oxed}
      uOXED;

TYPE
   {base task type, blocking}
   oxedTBaseTask = class
   end;

   { oxedTTask }

   oxedTTask = class(oxTThreadTask)
      constructor Create; override;
      destructor Destroy; override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   { oxedTTasks }

   oxedTTasks = record
      List: oxTThreadTasksList;

      OnTaskDone,
      OnTaskStart: TProcedures;

      procedure Add(task: oxTThreadTask);
      procedure Remove(task: oxTThreadTask);
      procedure TaskStarted(task: oxTThreadTask);
      procedure TaskDone(task: oxTThreadTask);

      {are any tasks of the specified type running}
      function Running(taskType: TClass; exceptType: TClass = nil): loopint;
      {how many tasks are running}
      function RunningCount(): loopint;
   end;

VAR
   oxedTasks: oxedTTasks;

IMPLEMENTATION

{ oxedTTask }

constructor oxedTTask.Create;
begin
   inherited Create;

   SingleRun := true;
   TaskType := oxedTBaseTask;

   oxedTasks.Add(Self);
end;

destructor oxedTTask.Destroy;
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

procedure oxedTTasks.Add(task: oxTThreadTask);
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i] = task) then
         exit;
   end;

   List.Add(task);
end;

procedure oxedTTasks.Remove(task: oxTThreadTask);
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

procedure oxedTTasks.TaskStarted(task: oxTThreadTask);
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i] = task) then begin
         OnTaskStart.Call();
      end;
   end;
end;

procedure oxedTTasks.TaskDone(task: oxTThreadTask);
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i] = task) then begin
         OnTaskDone.Call();
      end;
   end;
end;

function oxedTTasks.Running(taskType: TClass; exceptType: TClass): loopint;
 var
    i: loopint;

begin
   Result := 0;

   for i := 0 to List.n - 1 do begin
      if((List.List[i].TaskType = taskType) or (taskType = nil)) and
         (exceptType <> List.List[i].TaskType) and (oxTThreadTask.IsRunning(List.List[i])) then begin
            inc(Result);
         end;
   end;
end;

function oxedTTasks.RunningCount(): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to List.n - 1 do begin
      if(List.List[i].IsRunning()) then
         inc(Result);
   end;
end;

procedure deinit();
begin
   oxedTasks.List.Dispose();
end;

INITIALIZATION
   oxed.Init.dAdd('oxed.tasks', @deinit);

   oxedTasks.List.Initialize(oxedTasks.List);

   TProcedures.Initialize(oxedTasks.OnTaskDone);
   TProcedures.Initialize(oxedTasks.OnTaskStart);

END.
