{
   oxuglFP, fixed pipeline suppport
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglFP;

INTERFACE

   USES
      {ox}
      uOX, oxuRunRoutines,
      {ox.gl}
      oxuglRenderer;

TYPE

   { oxglTFP }

   oxglTFP = record
      Init: oxTRunRoutines;

      class procedure Initialize(); static;
      class procedure DeInitialize(); static;
   end;

VAR
   oxglFP: oxglTFP;

IMPLEMENTATION

VAR
   glInitRoutines: oxTRunRoutine;

{ oxglTFP }

class procedure oxglTFP.Initialize();
begin
   oxglFP.Init.iCall();
end;

class procedure oxglTFP.DeInitialize();
begin
   oxglFP.Init.dCall();
end;

procedure init();
begin
   oxglRenderer.Init.Add(glInitRoutines, 'gl.fpshader', @oxglTFP.Initialize, @oxglTFP.DeInitialize);
end;

INITIALIZATION
   ox.PreInit.Add('gl.fixed_pipeline', @init);

END.
