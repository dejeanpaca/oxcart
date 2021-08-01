{
   oxuInitTask, oX initialization task
   Copyright (c) 2021. Dejan Boras

   After base initialization, runs an initialization task to load the rest
}

{$INCLUDE oxheader.inc}
UNIT oxuInitTask;

INTERFACE

USES
   sysutils, uStd, uLog, uTiming,
   {ox}
   uOX, uiuBase, oxuWindow,
   oxuThreadTask, oxuRenderTask;

TYPE

   { oxTInitTask }

   oxTInitTask = class(oxTRenderTask)
      procedure Render(); override;
      procedure Run(); override;
   end;

   { oxTInitTaskGlobal }

   oxTInitTaskGlobal = record
      Task: oxTInitTask;

      procedure Go();
   end;

VAR
   oxInitTask: oxTInitTaskGlobal;

IMPLEMENTATION

{ oxTInitTask }

procedure oxTInitTask.Render();
begin
    {render nothing for the initialization task}
end;

procedure oxTInitTask.Run();
var
   elapsedTime: TDateTime;

begin
   elapsedTime := Now();
   {call initialization routines}
   ox.Init.iCall();
   if(ox.Error <> 0) then begin
      if(ox.ErrorDescription = '') then
         ox.RaiseError('Initialization failed', ox.Error);

      exit;
   end;

   log.i('Called all initialization routines (elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   {call UI initialization routines}
   ui.Initialize();

   {success}
   log.i('Initialization done. Elapsed: ' + GlobalStartTime.ElapsedfToString() + 's');
   log.Leave();

   ox.Initialized := true;
   self.Stop();
end;

{ oxTInitTaskGlobal }

procedure oxTInitTaskGlobal.Go();
begin
   Task := oxTInitTask.Create();
   Task.RunThreaded(oxWindow.Current);
end;

END.
