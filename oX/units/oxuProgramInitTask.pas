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
   oxuThreadTask, oxuRenderTask, oxuInitTask, oxuWindow;

TYPE

   { oxTInitTask }

   { oxTProgramInitTask }

   oxTProgramInitTask = class(oxTInitTask)
      constructor Create(); override;
      procedure Run(); override;
   end;

   { oxTProgramInitTaskGlobal }

   oxTProgramInitTaskGlobal = record
      Task: oxTProgramInitTask;
      Initialized: boolean;

      procedure Go();
      function IsFinished(): boolean;
   end;

VAR
   oxProgramInitTask: oxTProgramInitTaskGlobal;

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

{ oxTInitTaskGlobal }

procedure oxTProgramInitTaskGlobal.Go();
begin
   Task := oxTProgramInitTask.Create();
   Task.RunThreaded(oxWindow.Current);
end;

function oxTProgramInitTaskGlobal.IsFinished(): boolean;
begin
   Result := false;

   if(Initialized) then
      Result := true;

   if(Task <> nil) then
      Result := Task.IsFinished();
end;
END.
