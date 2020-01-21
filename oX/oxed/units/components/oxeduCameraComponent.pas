{
   oxeduCameraComponent, oxed camera component
   Copyright (C) 2017. Dejan Boras

   Started On:    27.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduCameraComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      oxuCameraComponent, oxeduThingies, oxeduComponent, oxeduComponentGlyph, oxeduComponentGlyphs;

TYPE
   { oxedTCameraEditRenderer }

   oxedTCameraEditRenderer = class(oxedTThingie)
      constructor Create();
   end;

VAR
   oxedCameraEditRenderer: oxedTCameraEditRenderer;

IMPLEMENTATION

{ oxedTCameraEditRenderer }

constructor oxedTCameraEditRenderer.Create();
begin
   Name := 'Camera';
   oxedComponentGlyphs.Add(oxTCameraComponent, '', $f03d);
   Associate(oxTCameraComponent);
end;

procedure init();
begin
   oxedCameraEditRenderer := oxedTCameraEditRenderer.Create();
end;

procedure deinit();
begin
   FreeObject(oxedCameraEditRenderer);
end;

INITIALIZATION
   oxedThingies.Init.Add('camera', @init, @deinit);

END.
