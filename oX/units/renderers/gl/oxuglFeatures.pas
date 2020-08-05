{
   oglFeatures, check opengl features
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglFeatures;

INTERFACE

   USES
      uLog,
      {ox}
      uOX, oxuRunRoutines,
      {gl}
      oxuglRenderer, oxuOGL, oxuglExtensions;

IMPLEMENTATION

VAR
   initRoutine: oxTRunRoutine;

procedure getFeatures();
var
   glr: oxglTRenderer;

begin
   glr := oxglRenderer;

   {$IFNDEF GLES}
   glr.Properties.Textures.Npot := oglExtensions.Supported(cGL_ARB_texture_non_power_of_two);
   {$ELSE}
   glr.Properties.Textures.Npot := false;
   glr.Properties.Textures.WarnedNpot := true;
   {$ENDIF}
end;

procedure init();
begin
   oxglRenderer.AfterInit.Add(initRoutine, 'gl.features', @getFeatures);
end;

INITIALIZATION
   ox.PreInit.Add('ox.gl.features', @init);

END.
