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
      oxuRunRoutines,
      oxuLightComponent, oxeduThingies, oxeduComponent, oxeduComponentGlyphs;

TYPE
   { oxedTLightEditRenderer }

   oxedTLightEditRenderer = class(oxedTThingie)
      constructor Create();
   end;

VAR
   oxedLightEditRenderer: oxedTLightEditRenderer;

IMPLEMENTATION

{ oxedTLightEditRenderer }

constructor oxedTLightEditRenderer.Create();
begin
   Name := 'Light';

   oxedComponentGlyphs.Add(oxTLightComponent, '', $f0eb);
   Associate(oxTLightComponent);
end;

procedure init();
begin
   oxedLightEditRenderer := oxedTLightEditRenderer.Create();
end;

procedure deinit();
begin
   FreeObject(oxedLightEditRenderer);
end;

INITIALIZATION
   oxedThingies.Init.Add('light', @init, @deinit);

END.
