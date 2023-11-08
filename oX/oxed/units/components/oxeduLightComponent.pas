{
   oxeduLightComponent, oxed light component
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduLightComponent;

INTERFACE

   USES
      uStd, uColors,
      {ox}
      oxuRunRoutines,
      oxuLightComponent, oxeduThingies, oxeduComponent, oxeduComponentGlyphs;

TYPE
   { oxedTLightThingie }

   oxedTLightThingie = class(oxedTThingie)
      constructor Create();
   end;

VAR
   oxedLightThingie: oxedTLightThingie;

IMPLEMENTATION

{ oxedTLightEditRenderer }

constructor oxedTLightThingie.Create();
begin
   Name := 'Light';

   Glyph := oxedComponentGlyphs.Add(oxTLightComponent, '', $f0eb);
   Glyph^.Color.Assign(255, 255, 32, 255);
   Associate(oxTLightComponent);
end;

procedure init();
begin
   oxedLightThingie := oxedTLightThingie.Create();
end;

procedure deinit();
begin
   FreeObject(oxedLightThingie);
end;

INITIALIZATION
   oxedThingies.Init.Add('light', @init, @deinit);

END.
