{
   oxeduUIComponent, oxed UI component
   Copyright (C) 2019. Dejan Boras

   Started On:    14.11.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduUIComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      oxuUIComponent, oxeduThingies, oxeduComponent, oxeduComponentGlyph, oxeduComponentGlyphs;

TYPE
   { oxedTUIEditRenderer }

   oxedTUIEditRenderer = class(oxedTThingie)
      constructor Create();
   end;

VAR
   oxedUIEditRenderer: oxedTUIEditRenderer;

IMPLEMENTATION

{ oxedTUIEditRenderer }

constructor oxedTUIEditRenderer.Create();
begin
   Name := 'UI';
   oxedComponentGlyphs.Add(oxTUIComponent, '', $f03d);
   Associate(oxTUIComponent);
end;

procedure init();
begin
   oxedUIEditRenderer := oxedTUIEditRenderer.Create();
end;

procedure deinit();
begin
   FreeObject(oxedUIEditRenderer);
end;

INITIALIZATION
   oxedThingies.Init.Add('ui', @init, @deinit);

END.
