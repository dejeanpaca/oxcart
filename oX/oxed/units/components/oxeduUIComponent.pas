{
   oxeduUIComponent, oxed UI component
   Copyright (C) 2019. Dejan Boras
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

   oxedTUIEditRenderer = object(oxedTThingie)
      constructor Create();
      procedure Initialize(); virtual;
   end;

VAR
   oxedUIEditRenderer: oxedTUIEditRenderer;

IMPLEMENTATION

{ oxedTUIEditRenderer }

constructor oxedTUIEditRenderer.Create();
begin
   inherited;
   Name := 'UI';
   Link(oxTUIComponent);
end;

procedure oxedTUIEditRenderer.Initialize();
begin
  oxedComponentGlyphs.Add(oxTUIComponent, '', $f03d);
end;

INITIALIZATION
   oxedUIEditRenderer.Create();

END.
