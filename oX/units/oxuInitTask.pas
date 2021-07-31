{
   oxuInitTask, oX initialization task
   Copyright (c) 2021. Dejan Boras

   After base initialization, runs an initialization task to load the rest
}

{$INCLUDE oxheader.inc}
UNIT oxuInitTask;

INTERFACE

USES
   oxuThreadTask, oxuRenderTask;

TYPE

   { oxTInitTask }

   oxTInitTask = class(oxTRenderTask)
      procedure Render(); override;
   end;

IMPLEMENTATION

{ oxTInitTask }

procedure oxTInitTask.Render();
begin
    {render nothing for the initialization task}
end;

END.
