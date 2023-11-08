{
   oxuglFP, fixed pipeline suppport
   Copyright (C) 2018. Dejan Boras

   Started On:    31.03.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglFP;

INTERFACE

   USES
      uInit,
      {ox}
      uOX, oxuRunRoutines,
      {ox.gl}
      oxuglRenderer;

TYPE

   { oxglTFP }

   oxglTFP = record
      Init: TInitializationProcs;

      class procedure Initialize(); static;
      class procedure DeInitialize(); static;
   end;

VAR
   oxglFP: oxglTFP;

IMPLEMENTATION

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
   oxglRenderer.Init.Add('gl.fpshader', @oxglTFP.Initialize, @oxglTFP.DeInitialize);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxglFP.Init.Init('ox.gl.fp');

   ox.PreInit.iAdd(initRoutines, 'ox.gl.fos', @init);

END.
