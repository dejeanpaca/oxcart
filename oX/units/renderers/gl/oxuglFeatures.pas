{
   oglFeatures, check opengl features
   Copyright (C) 2019. Dejan Boras

   Started On:    21.10.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglFeatures;

INTERFACE

   USES
      uLog, StringUtils,
      {ox}
      uOX, oxuRunRoutines,
      {gl}
      oxuglRenderer, oxuOGL, oxuglExtensions;

IMPLEMENTATION

VAR
   glInitRoutines: oxTRunRoutine;

procedure getFeatures();
var
   glr: oxglTRenderer;

begin
   glr := oxglRenderer;

   {$IFNDEF GLES}
   glr.Properties.Textures.NonPowerOf2 := oglExtensions.Supported(-cGL_ARB_texture_non_power_of_two);
   {$ELSE}
   glr.Properties.Textures.NonPowerOf2 := false;
   glr.Properties.Textures.WarnedPot := true;
   {$ENDIF}

   log.v('Supports non power of two textures: ' + sf(glr.Properties.Textures.NonPowerOf2));
end;

procedure initGl();
begin
   getFeatures();
end;

procedure init();
begin
   oxglRenderer.AfterInit.Add(glInitRoutines, 'gl.fpshader', @initGl);
end;

INITIALIZATION
   ox.PreInit.Add('ox.gl.features', @init);

END.
