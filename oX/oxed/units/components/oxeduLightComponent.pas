{
   oxeduLightComponent, oxed light component
   Copyright (C) 2018. Dejan Boras

   Started On:    26.11.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduLightComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuLightComponent, oxeduEditRenderers;

TYPE
   { oxedTLightEditRenderer }

   oxedTLightEditRenderer = class(oxedTEditRenderer)
      constructor Create();
   end;

VAR
   oxedLightEditRenderer: oxedTLightEditRenderer;

IMPLEMENTATION

{ oxedTLightEditRenderer }

constructor oxedTLightEditRenderer.Create();
begin
   Name := 'Light';
   GlyphCode := $f0eb;
   ComponentType := oxTLightComponent;
end;

procedure init();
begin
   oxedLightEditRenderer := oxedTLightEditRenderer.Create();

   oxedEditRenderers.Renderers.Add(oxedLightEditRenderer);
   oxedEditRenderers.Selection.Add(oxedLightEditRenderer);
end;

procedure deinit();
begin
   FreeObject(oxedLightEditRenderer);
end;

INITIALIZATION
   oxedEditRenderers.Init.Add('light', @init, @deinit);

END.
