{
   oxuInitTask, oX initialization task
   Copyright (c) 2021. Dejan Boras

   After base initialization, runs an initialization task to load the rest
}

{$INCLUDE oxheader.inc}
UNIT oxuMainInitTask;

INTERFACE

USES
   sysutils, uStd, uLog, uTiming,
   {ox}
   uOX, uiuBase, oxuWindow,
   oxuThreadTask, oxuRenderTask, oxuInitTask, oxuInitTaskHandler;

TYPE

   { oxTMainInitTask }

   oxTMainInitTask = class(oxTInitTask)
      constructor Create(); override;
      procedure Run(); override;
   end;

VAR
   oxMainInitTask: oxTInitTaskHandler;

IMPLEMENTATION

{ oxTInitTask }

constructor oxTMainInitTask.Create();
begin
   inherited Create();

   Name := 'MainInitTask';
end;

procedure oxTMainInitTask.Run();
var
   elapsedTime: TDateTime;

begin
   elapsedTime := Now();

   if(RC = -1) then begin
      ox.RaiseError('No RC for main init task', oxeRENDERER);
      exit();
   end;

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
end;

INITIALIZATION
   oxMainInitTask.Instance := oxTMainInitTask;

END.
