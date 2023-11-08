{
   oxuInitTask, oX initialization task
   Copyright (c) 2021. Dejan Boras

   After base initialization, runs an initialization task to load the rest
}

{$INCLUDE oxheader.inc}
UNIT oxuProgramInitTask;

INTERFACE

USES
   sysutils, uStd, uLog, uTiming,
   {ox}
   uOX, uiuBase,
   oxuWindow, oxuThreadTask, oxuRenderTask, oxuInitTask, oxuInitTaskHandler;

TYPE
   { oxTProgramInitTask }

   oxTProgramInitTask = class(oxTInitTask)
      constructor Create(); override;
      procedure Run(); override;
   end;

VAR
   oxProgramInitTask: oxTInitTaskHandler;

IMPLEMENTATION

{ oxTInitTask }

constructor oxTProgramInitTask.Create();
begin
   inherited Create();

   Name := 'ProgramInitTask';
end;

procedure oxTProgramInitTask.Run();
var
   elapsedTime: TDateTime;

begin
   elapsedTime := Time();

   log.Enter('oX > Initializing the program...');

   ox.OnInitialize.iCall();

   log.i('Program initialization done. Elapsed time: ' + elapsedTime.ElapsedfToString() + 's');
   log.Leave();

   log.i('Total startup time: ' + GlobalStartTime.ElapsedfToString() + 's');

   oxProgramInitTask.Initialized := true;
end;

INITIALIZATION
   oxProgramInitTask.Instance := oxTProgramInitTask;

END.
