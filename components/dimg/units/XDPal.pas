{
   XDPal, XDPalette palette file loading and saving
   Copyright (C) 2009. Dejan Boras

   Started On:    27.01.2009.
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT XDPal;

INTERFACE

{load a palette}
procedure xdpalLoad(const fn: string; var pal: imgTPalette);
{save a palette}
procedure xdpalSave(const fn: string; var pal: imgTPalette);

IMPLEMENTATION

procedure xdpalLoad(const fn: string; var pal: imgTPalette);
begin
end;

procedure xdpalSave(const fn: string; var pal: imgTPalette);
begin
end;

END.
