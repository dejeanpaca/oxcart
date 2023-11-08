{
   oxuGlyph, glyph management
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuGlyph;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTexture;

TYPE
   oxPGlyph = ^oxTGlyph;

   { oxTGlyph }

   oxTGlyph = record
     Width,
     Height,
     BearingX,
     BearingY,
     Advance: loopint;
     Texture: oxTTexture;

     class procedure Init(out glyph: oxTGlyph); static;
   end;

IMPLEMENTATION

{ oxTGlyph }

class procedure oxTGlyph.Init(out glyph: oxTGlyph);
begin
   ZeroPtr(@glyph, SizeOf(glyph));
end;

END.
