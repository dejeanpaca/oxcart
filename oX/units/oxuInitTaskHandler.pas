{
   oxuInitTaskHandler, oX initialization task handler
   Copyright (c) 2021. Dejan Boras

   Handles an initialization task (oxTInitTask)
}

{$INCLUDE oxheader.inc}
UNIT oxuInitTaskHandler;

INTERFACE

USES
   {ox}
   oxuInitTask, oxuWindow;

TYPE

   { oxTInitTaskHandler }

   oxTInitTaskHandler = record
      Task: oxTInitTask;
      Instance: oxTInitTaskClass;
      Initialized: boolean;

      procedure Go();
      function IsFinished(): boolean;
      procedure StopWait();
   end;

IMPLEMENTATION

{ oxTInitTaskHandler }

procedure oxTInitTaskHandler.Go();
begin
   Task := Instance.Create();
   Task.RunThreaded(oxWindow.Current);
end;

function oxTInitTaskHandler.IsFinished(): boolean;
begin
   Result := false;

   if(Initialized) then
      Result := true;

   if(Task <> nil) then
      Result := Task.IsFinished();
end;

procedure oxTInitTaskHandler.StopWait();
begin
   if(not IsFinished()) and (Task  <> nil) then
      Task.StopWait();
end;

END.
