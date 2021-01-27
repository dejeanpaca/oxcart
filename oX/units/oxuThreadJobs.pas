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

      procedure QueueAdd(task: oxTThreadTask);
      procedure QueueRemove(task: oxTThreadTask);
      function JobIndex(task: oxTThreadTask): loopint;

      procedure Run(); override;
      {watches jobs, updates queue, and returns true if any is running}
      function Watch(): boolean;

      private
         Locker: TRTLCriticalSection;
   end;

IMPLEMENTATION

{ oxTThreadJob }

constructor oxTThreadJob.Create();
begin
   inherited Create;

   InitCriticalSection(Locker);
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

END.
