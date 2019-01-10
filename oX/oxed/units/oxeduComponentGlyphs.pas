{
   oxeduEditRenderers, oxed edit window renderers
   Copyright (C) 2016. Dejan Boras

   Started On:    24.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduComponentGlyphs;

INTERFACE

   USES
      uStd, uInit,
      {ox}
      uOX, oxuComponent, oxeduComponentGlyph, oxeduComponent,
      {oxed}
      oxeduIcons;

TYPE
   { oxedTComponentGlyphs }

   oxedTComponentGlyphs = record
      function Add(component: oxTComponentType; name: string = ''; code: loopint = 0): oxedPComponentGlyph;
   end;

VAR
   oxedComponentGlyphs: oxedTComponentGlyphs;

IMPLEMENTATION

{ oxedTComponentGlyphs }

function oxedTComponentGlyphs.Add(component: oxTComponentType; name: string; code: loopint): oxedPComponentGlyph;
var
   oxc: oxedPComponent;

begin
   oxc := oxedComponents.Find(component);
   if(oxc <> nil) then begin
      oxc^.Glyph.Component := component;
      oxc^.Glyph.Name := name;
      oxc^.Glyph.Code := code;

      if(ox.Initialized) then
         oxc^.Glyph.CreateTexture();

      exit(@oxc^.Glyph);
   end;

   Result := nil;
end;

END.
