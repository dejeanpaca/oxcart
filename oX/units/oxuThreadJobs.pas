{
   oxuThreadJobs, manages threaded jobs
   Copyright (c) 2018. Dejan Boras

   Started On:    18.04.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuThreadJobs;

INTERFACE

   USES
      sysutils, oxuThreadTask;

TYPE

   { oxTThreadJob }

   oxTThreadJob = class(oxTThreadTask)
      public
      Queue: oxTThreadTasksList;

      constructor Create; override;

      procedure QueueAdd(task: oxTThreadTask);
      procedure QueueRemove(task: oxTThreadTask);
      function JobIndex(task: oxTThreadTask): loopint;

      procedure Run(); override;

      private
         Locker: TCriticalSection;
   end;

IMPLEMENTATION

{ oxTThreadJob }

constructor oxTThreadJob.Create;
begin
   inherited Create;

   InitCriticalSection(Locker);
end;

procedure oxTThreadJob.QueueAdd(task: oxTThreadTask);
begin
   EnterCriticalsection(Locker);

   LeaveCriticalsection(Locker);
end;

procedure oxTThreadJob.QueueRemove(task: oxTThreadTask);
begin
   EnterCriticalsection(Locker);
   LeaveCriticalsection(Locker);
end;

function oxTThreadJob.JobIndex(task: oxTThreadTask): loopint;
begin
   {TODO: Find job index}
   Result := -1;
end;

procedure oxTThreadJob.Run();
var
   current: oxTThreadTask;

begin
   repeat
      current := nil;

      EnterCriticalsection(Locker);

      if(Queue.n > 0) then begin
         current := Queue.List[0];
         Queue.Remove(0);
      end;

      LeaveCriticalsection(Locker);

      if(current <> nil) then
        current.RunHere();
   until Terminated;
end;

END.
