{
   oxuThreadTask, manages threaded tasks
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuThreadTask;

INTERFACE

   USES
      sysutils, classes,
      uStd, uError, uTiming, uLog,
      appuEvents
      {$IFNDEF NO_THREADS}
      , oxuTimer
      {$IFDEF OX_DEBUG}
      , uThreadUtils
      {$ENDIF}
      {$ENDIF};

CONST
   OX_THREAD_TASK_DONE = 2;

TYPE
   { oxTThreadTaskRunner }

   oxTThreadTaskRunner = class(TThread)
      Task: TObject;

      constructor Create(CreateSuspended: Boolean; setTask: TObject);

      procedure Execute(); override;
      procedure Run(); virtual;
      procedure Finish(); virtual;
   end;

   oxTThreadTaskRunnerClass = class of oxTThreadTaskRunner;

   oxTThreadMethod = procedure(thread: TObject);
   oxTThreadMethods = specialize TSimpleList<oxTThreadMethod>;

   { oxTThreadMethodsHelper }

   oxTThreadMethodsHelper = record helper for oxTThreadMethods
      procedure Call(task: TObject);
   end;

   oxTThreadEmit = (
      OX_THREAD_TASK_EMIT_START,
      OX_THREAD_TASK_EMIT_DONE
   );

   oxTThreadEmitSet = set of oxTThreadEmit;

   { oxTThreadTask }

   oxTThreadTask = class
      {task name}
      Name: string;

      {task thread}
      Thread: oxTThreadTaskRunner;
      {is the tread pending termination (task finish)}
      Terminated,
      {has the task started}
      Started,
      {is the task finished}
      Finished,
      {call Run() only once, instead of running in a loop}
      SingleRun,
      {should thread switching be performed between cycles}
      DoThreadSwitching: Boolean;

      {time when the task was started}
      StartTime,
      {time to sleep between runs}
      SleepTime: longint;

      RunnerInstanceType: oxTThreadTaskRunnerClass;

      {task type, for grouping tasks into classes of tasks}
      TaskType: TClass;

      {list of events called on the main thread when the message queue is processed}
      Events: record
         {should we emit any events}
         Emit,
         {if any events were emitted}
         Emitted: oxTThreadEmitSet;
         {called when the thread is done}
         ThreadStart,
         ThreadDone: oxTThreadMethods;
      end;

      constructor Create(); virtual;
      destructor Destroy(); override;

      {start the task}
      procedure Start();
      {Tell task to stop. This does not immediately end the task. To find out when the task stopped, use IsFinished()}
      procedure Stop();
      {prepare for start (should only be called before thread started and is called by Start() and RunHere() automatically)}
      procedure StartPrepare();
      {Runs in the current thread}
      procedure RunHere();

      {call to end the thread and wait for end}
      procedure StopWait();

      {check if the task has finished}
      function IsFinished(): boolean;
      {check if the task has finished}
      function IsRunning(): boolean;

      { task threaded methods }

      {run the task}
      procedure Run(); virtual;
      {called at start of task}
      procedure TaskStart(); virtual;
      {called when the task stops}
      procedure TaskStop(); virtual;
      {called at end of task, after TaskStop}
      procedure TaskEnd(); virtual;

      {check if a task is valid and running}
      class function IsRunning(task: oxTThreadTask): boolean;

      {set all events to emit}
      procedure EmitAllEvents();

      {set task as continuous}
      procedure SetAsContinuous();
      {set task as continuous}
      procedure SetAsSingleRun();

      {called when thread is started in the main process thread}
      procedure ThreadStart(); virtual;
      {called when thread is stopped in the main process thread}
      procedure ThreadDone(); virtual;

      {called when thread task starts from the runner}
      procedure Startup();
      {called when thread task ends from the runner}
      procedure Finish();

      {set the thread name}
      procedure SetName(const newName: string);
   end;

   oxTThreadTasksList = specialize TSimpleList<oxTThreadTask>;

   { oxTThreadEvents }

   oxTThreadEvents = record
      LogExceptions,
      FinishTasksOnException: Boolean;
      Handler: appTEventHandler;

      procedure Queue(Task: oxTThreadTask; evID: longword);
      procedure Destroy(var Task: oxTThreadTask);
   end;


   { oxTRoutineThreadTask }

   oxTRoutineThreadTask = class(oxTThreadTask)
      {simple task intended to run a callback procedure}

      Callback: record
         Routine: TProcedure;
         ObjectRoutine: TObjectProcedure;
      end;

      procedure Run(); override;
      procedure SetRoutine(routine: TProcedure);
      procedure SetRoutine(routine: TObjectProcedure);
   end;

VAR
   oxThreadEvents: oxTThreadEvents;

IMPLEMENTATION

{ oxTRoutineThreadTask }

procedure oxTRoutineThreadTask.Run();
begin
   if(Callback.Routine <> nil) then
      Callback.Routine();

   if(Callback.ObjectRoutine <> nil) then
      Callback.ObjectRoutine();
end;

procedure oxTRoutineThreadTask.SetRoutine(routine: TProcedure);
begin
   Callback.Routine := routine;
end;

procedure oxTRoutineThreadTask.SetRoutine(routine: TObjectProcedure);
begin
   Callback.ObjectRoutine := routine;
end;

{ oxTThreadEvents }

procedure oxTThreadEvents.Queue(Task: oxTThreadTask; evID: longword);
var
   ev: appTEvent;

begin
   appEvents.Init(ev, evID, @Handler);
   ev.ExternalData := Task;
   appEvents.Queue(ev);
end;

procedure oxTThreadEvents.Destroy(var Task: oxTThreadTask);
begin
   {remove any remaining events}
   if(OX_THREAD_TASK_EMIT_DONE in Task.Events.Emitted) then
      appEvents.DisableWithExternalData(Task);

   FreeObject(Task);
end;

{ oxTThreadMethodsHelper }

procedure oxTThreadMethodsHelper.Call(task: TObject);
var
   i: loopint;
begin
   for i := 0 to n - 1 do begin
      List[i](task);
   end;
end;

{ oxTThreadTaskRunner }

constructor oxTThreadTaskRunner.Create(CreateSuspended: Boolean; setTask: TObject);
begin
   Task := setTask;

   inherited Create(CreateSuspended);
end;

procedure oxTThreadTaskRunner.Execute();
var
   t: oxTThreadTask;

begin
   t := oxTThreadTask(Task);

   try
      Run();
   except
      on e: Exception do begin
         t.Stop();

         if(oxThreadEvents.LogExceptions) then begin
            log.e('Exception in thread task ' + oxTThreadTask(Task).Name);
            log.e(DumpExceptionCallStack(e));
         end;

         if(oxThreadEvents.FinishTasksOnException) then
            Finish();
      end;
   end;
end;

procedure oxTThreadTaskRunner.Run();
var
  t: oxTThreadTask;

begin
   t := oxTThreadTask(Task);

   t.Startup();

   if(not t.SingleRun) then begin
      while (not t.Terminated) and (not Terminated) do begin
         t.Run();

         if(t.DoThreadSwitching) then
            ThreadSwitch();

         if(t.SleepTime > 0) then
            Sleep(t.SleepTime);

      end;
   end else
      t.Run();

   Finish();
end;

procedure oxTThreadTaskRunner.Finish();
begin
   oxTThreadTask(Task).Finish();
end;

{ oxTThreadTask }

constructor oxTThreadTask.Create();
begin
   Name := ClassName;

   RunnerInstanceType := oxTThreadTaskRunner;
   DoThreadSwitching := true;
   Finished := true;

   Events.ThreadStart.Initialize(Events.ThreadStart, 8);
   Events.ThreadDone.Initialize(Events.ThreadDone, 8);
end;

destructor oxTThreadTask.Destroy();
begin
   inherited Destroy;

   FreeObject(Thread);
end;

procedure oxTThreadTask.Start();
begin
   StartTime := timer.Cur();

   if(Started) then
      exit;

   Events.Emitted := [];

   FreeObject(Thread);
   {$IFNDEF NO_THREADS}
   Thread := RunnerInstanceType.Create(true, Self);

   {$IFDEF DEBUG}
   if(Thread <> nil) then
      TThreadUtils.SetThreadName(Thread, Name);
   {$ENDIF}
   {$ENDIF}

   StartPrepare();

   {call start event}
   if(OX_THREAD_TASK_EMIT_START in Events.Emit) then begin
      Include(Events.Emitted, OX_THREAD_TASK_EMIT_START);
      ThreadStart();
      Events.ThreadStart.Call(Self);
   end;

   {$IFNDEF NO_THREADS}
   Thread.Start();
   {$ELSE}
   RunHere();
   {$ENDIF}
end;

procedure oxTThreadTask.Stop();
begin
   {$IFNDEF NO_THREADS}
   if(Thread <> nil) then begin
      Terminated := true;
      Thread.Terminate();
   end;
   {$ELSE}
   Terminated := true;
   {$ENDIF}
end;

procedure oxTThreadTask.StartPrepare();
begin
   Terminated := false;
   Finished := false;
   Started := true;
end;

procedure oxTThreadTask.RunHere();
begin
   Startup();
   Run();
   Finish();
end;

procedure oxTThreadTask.StopWait();
begin
   {$IFNDEF NO_THREADS}
   if(Thread <> nil) then begin
      Stop();

      while(not Thread.Finished) do begin
         oxTimer.Sleep();
      end;
   end;
   {$ELSE}
   Stop();
   {$ENDIF}
end;

function oxTThreadTask.IsFinished(): boolean;
begin
   Result := Finished;
end;

function oxTThreadTask.IsRunning(): boolean;
begin
   Result := Started and (not IsFinished());
end;

procedure oxTThreadTask.Run();
begin
end;

procedure oxTThreadTask.TaskStart();
begin

end;

procedure oxTThreadTask.TaskStop();
begin

end;

procedure oxTThreadTask.TaskEnd();
begin

end;

class function oxTThreadTask.IsRunning(task: oxTThreadTask): boolean;
begin
   Result := (task <> nil) and (task.IsRunning());
end;

procedure oxTThreadTask.EmitAllEvents();
begin
   Events.Emit := [OX_THREAD_TASK_EMIT_START, OX_THREAD_TASK_EMIT_DONE];
end;

procedure oxTThreadTask.SetAsContinuous();
begin
   SingleRun := false;
end;

procedure oxTThreadTask.SetAsSingleRun();
begin
   SingleRun := true;
end;

procedure oxTThreadTask.ThreadStart();
begin

end;

procedure oxTThreadTask.ThreadDone();
begin

end;

procedure oxTThreadTask.Startup();
begin
   Finished := false;

   TaskStart();
end;

procedure oxTThreadTask.Finish();
begin
   TaskStop();

   Finished := true;
   Started := false;

   Stop();

   TaskEnd();

   if(OX_THREAD_TASK_EMIT_DONE in Events.Emit) then begin
      Include(Events.Emitted, OX_THREAD_TASK_EMIT_DONE);
      oxThreadEvents.Queue(Self, OX_THREAD_TASK_DONE);
   end;
end;

procedure oxTThreadTask.SetName(const newName: string);
begin
   Name := newName;

   {$IF NOT DEFINED(NO_THREADS) AND DEFINED(DEBUG)}
   if(Thread <> nil) then
      TThreadUtils.SetThreadName(Thread, newName);
   {$ENDIF}
end;

procedure processEvents(var event: appTEvent);
begin
   if(event.evID = OX_THREAD_TASK_DONE) then begin
      oxTThreadTask(event.ExternalData).ThreadDone();
      oxTThreadTask(event.ExternalData).Events.ThreadDone.Call(oxTThreadTask(event.ExternalData));
   end;
end;

INITIALIZATION
   appEvents.AddHandler(oxThreadEvents.Handler, 'ox.thread_events', @processEvents);

   oxThreadEvents.LogExceptions := true;
   oxThreadEvents.FinishTasksOnException := true;

END.
