{
   oxeduCameraComponent, oxed camera component
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduCameraComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      oxuCameraComponent, oxeduThingies, oxeduComponent, oxeduComponentGlyph, oxeduComponentGlyphs;

TYPE
   { oxedTCameraEditRenderer }

   oxedTCameraEditRenderer = object(oxedTThingie)
      constructor Create();
      procedure Initialize(); virtual;
   end;

VAR
   oxedCameraEditRenderer: oxedTCameraEditRenderer;

IMPLEMENTATION

{ oxedTCameraEditRenderer }

constructor oxedTCameraEditRenderer.Create();
begin
   inherited;

   Name := 'Camera';
   Link(oxTCameraComponent);
end;

procedure oxedTCameraEditRenderer.Initialize();
begin
  oxedComponentGlyphs.Add(oxTCameraComponent, '', $f03d);
end;

INITIALIZATION
   oxedCameraEditRenderer.Create();

END.
