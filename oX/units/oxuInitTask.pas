{
   oxuInitTask, oX initialization task
   Copyright (c) 2021. Dejan Boras

   Generic initialization task
}

{$INCLUDE oxheader.inc}
UNIT oxuInitTask;

INTERFACE

USES
   {ox}
   oxuThreadTask, oxuRenderTask;

TYPE

   { oxTInitTask }

   oxTInitTask = class(oxTRenderTask)
      constructor Create(); override;
      procedure Render(); override;
      procedure Run(); override;
   end;

   oxTInitTaskClass = class of oxTInitTask;

IMPLEMENTATION

{ oxTInitTask }

constructor oxTInitTask.Create();
begin
   inherited Create();

   Name := 'InitTask';
   SetAsSingleRun();
end;

procedure oxTInitTask.Render();
begin
   {render nothing for the initialization task}
end;

procedure oxTInitTask.Run();
begin
   {don't do the usual render task flow}
end;

END.
