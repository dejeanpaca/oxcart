{
   oxuThreadJobs, manages threaded jobs
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuThreadJobs;

INTERFACE

   USES
      sysutils, uStd,
      {oX}
      oxuThreadTask;

TYPE
   { oxTThreadJob }

   oxTThreadJob = class(oxTThreadTask)
      public
      Queue: oxTThreadTasksList;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure QueueAdd(task: oxTThreadTask);
      procedure QueueRemove(task: oxTThreadTask);
      function JobIndex(task: oxTThreadTask): loopint;

      procedure Run(); override;
      {watches jobs, updates queue, and returns true if any is running}
      function Watch(): boolean;

      private
         Locker: TRTLCriticalSection;
   end;

   { oxTTaskQueue }

   oxTTaskQueue = record
      Queue: oxTThreadTasksList;

      {currently running task (nil if none)}
      Running: oxTThreadTask;


      procedure Initialize();
      class procedure Initialize(out t: oxTTaskQueue); static;

      procedure DeInitialize();

      procedure QueueAdd(task: oxTThreadTask);
      procedure Remove(task: oxTThreadTask);
      function TaskIndex(task: oxTThreadTask): loopint;

      procedure Reset();

      {watches jobs, starts, updates queue, and returns true if any is running}
      function Update(): boolean;
   end;

IMPLEMENTATION

{ oxTThreadJob }

constructor oxTThreadJob.Create();
begin
   inherited Create;

   InitCriticalSection(Locker);
end;

destructor oxTThreadJob.Destroy();
begin
   inherited Destroy();

   Queue.Dispose();
end;

procedure oxTThreadJob.QueueAdd(task: oxTThreadTask);
begin
   EnterCriticalSection(Locker);
   Queue.Add(task);
   LeaveCriticalSection(Locker);
end;

procedure oxTThreadJob.QueueRemove(task: oxTThreadTask);
var
   index: loopint;

begin
   EnterCriticalSection(Locker);

   index := Queue.Find(task);
   if(index > -1) then
     Queue.Remove(index);

   LeaveCriticalSection(Locker);
end;

function oxTThreadJob.JobIndex(task: oxTThreadTask): loopint;
begin
   Result := Queue.Find(task);
end;

procedure oxTThreadJob.Run();
var
   current: oxTThreadTask;
   index: loopint;

begin
   if(Queue.n = 0) then
      exit;

   index := 0;

   repeat
      EnterCriticalSection(Locker);
      current := Queue.List[index];
      LeaveCriticalSection(Locker);

      if(current <> nil) then
        current.RunHere();

      inc(index);
   until Terminated or (index = 0);

   EnterCriticalSection(Locker);
   Queue.RemoveAll();
   LeaveCriticalSection(Locker);
end;

function oxTThreadJob.Watch(): boolean;
begin
   EnterCriticalSection(Locker);
   Result := Queue.n > 0;
   LeaveCriticalSection(Locker);
end;

{ oxTTaskQueue }

procedure oxTTaskQueue.Initialize();
begin
   Queue.InitializeValues(Queue);
end;

class procedure oxTTaskQueue.Initialize(out t: oxTTaskQueue);
begin
   ZeroOut(t, SizeOf(t));
   t.Initialize();
end;

procedure oxTTaskQueue.DeInitialize();
begin
   Queue.Dispose();
end;

procedure oxTTaskQueue.QueueAdd(task: oxTThreadTask);
begin
   Queue.Add(task);
end;

procedure oxTTaskQueue.Remove(task: oxTThreadTask);
var
   index: loopint;

begin
   index := Queue.Find(task);

   if(index > -1) then
      Queue.Remove(index);
end;

function oxTTaskQueue.TaskIndex(task: oxTThreadTask): loopint;
begin
   Result := Queue.Find(task);
end;

procedure oxTTaskQueue.Reset();
begin
   Running := nil;
   Queue.RemoveAll();
end;

function oxTTaskQueue.Update(): boolean;

procedure startFirst();
begin
   Running := Queue.List[0];
   Running.Start();
end;

begin
   if(Queue.n = 0) then
      exit(false);

   Result := true;

   if(Running <> nil) then begin
      if(Running.IsFinished()) then begin
         Running := nil;
         Queue.Remove(0);

         if(Queue.n > 0) then
            startFirst()
         else
            Result := false;
      end;
   end else
      startFirst();
end;

END.
