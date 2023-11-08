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

   oxedTLightThingie = object(oxedTThingie)
      constructor Create();
      procedure Initialize(); virtual;
   end;

VAR
   oxedLightThingie: oxedTLightThingie;

IMPLEMENTATION

{ oxedTLightEditRenderer }

constructor oxedTLightThingie.Create();
begin
   inherited;
   Name := 'Light';

   Link(oxTLightComponent);
end;

procedure oxedTLightThingie.Initialize();
begin
   Glyph := oxedComponentGlyphs.Add(oxTLightComponent, '', $f0eb);
   Glyph^.Color.Assign(255, 255, 32, 255);
end;

INITIALIZATION
   oxedLightThingie.Create();

END.
