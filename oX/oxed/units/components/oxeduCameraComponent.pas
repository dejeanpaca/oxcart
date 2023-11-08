{
   oxeduCameraComponent, oxed camera component
   Copyright (C) 2016. Dejan Boras

   Started On:    27.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduCameraComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuCameraComponent, oxeduEditRenderers;

TYPE
   { oxedTCameraEditRenderer }

   oxedTCameraEditRenderer = class(oxedTEditRenderer)
      constructor Create();

      procedure Initialize(); override;
   end;

VAR
   oxedCameraEditRenderer: oxedTCameraEditRenderer;

IMPLEMENTATION

{ oxedTCameraEditRenderer }

constructor oxedTCameraEditRenderer.Create();
begin
   Name := 'Camera';
   Glyph := 'video-camera';
   ComponentType := oxTCameraComponent;
end;

procedure oxedTCameraEditRenderer.Initialize();
begin
   GlyphFromFont($f03d);
end;

procedure init();
begin
   oxedCameraEditRenderer := oxedTCameraEditRenderer.Create();

   oxedEditRenderers.Renderers.Add(oxedCameraEditRenderer);
   oxedEditRenderers.Selection.Add(oxedCameraEditRenderer);
end;

procedure deinit();
begin
   FreeObject(oxedCameraEditRenderer);
end;

INITIALIZATION
   oxedEditRenderers.Init.Add('camera', @init, @deinit);

END.
