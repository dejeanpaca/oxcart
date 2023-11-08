{
   uColors, color types, constants & routines
   Copyright (C) 2008. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$MODESWITCH TYPEHELPERS}{$MODESWITCH ADVANCEDRECORDS}
UNIT uColors;

INTERFACE

   USES StringUtils;

TYPE
   {COLOR TYPES}
   {Not all of these are used, but regardless of that they may prove usefull sometime.}
   {unsigned byte}
   PColor1ub = ^TColor1ub;
   TColor1ub = byte;
   PColor2ub = ^TColor2ub;
   TColor2ub = array[0..1] of byte;
   PColor3ub = ^TColor3ub;
   TColor3ub = array[0..2] of byte;
   PColor4ub = ^TColor4ub;
   TColor4ub = array[0..3] of byte;

   {byte}
   PColor1b = ^TColor1b;
   TColor1b = shortint;
   PColor2b = ^TColor2b;
   TColor2b = array[0..1] of shortint;
   PColor3b = ^TColor3b;
   TColor3b = array[0..2] of shortint;
   PColor4b = ^TColor4b;
   TColor4b = array[0..3] of shortint;

   {unsigned short}
   PColor1us = ^TColor1us;
   TColor1us = word;
   PColor2us = ^TColor2us;
   TColor2us = array[0..1] of word;
   PColor3us = ^TColor3us;
   TColor3us = array[0..2] of word;
   PColor4us = ^TColor4us;
   TColor4us = array[0..3] of word;

   {signed short}
   PColor1s  = ^TColor1s;
   TColor1s  = smallint;
   PColor2s  = ^TColor2s;
   TColor2s  = array[0..1] of smallint;
   PColor3s  = ^TColor3s;
   TColor3s  = array[0..2] of smallint;
   PColor4s  = ^TColor4s;
   TColor4s  = array[0..3] of smallint;

   {single precision float}
   PColor1f  = ^TColor1f;
   TColor1f  = single;
   PColor2f  = ^TColor2f;
   TColor2f  = array[0..1] of single;
   PColor3f  = ^TColor3f;
   TColor3f  = array[0..2] of single;
   PColor4f  = ^TColor4f;
   TColor4f  = array[0..3] of single;

   {double precision float}
   PColor1d  = ^TColor1d;
   TColor1d  = double;
   PColor2d  = ^TColor2d;
   TColor2d  = array[0..1] of double;
   PColor3d  = ^TColor3d;
   TColor3d  = array[0..2] of double;
   PColor4d  = ^TColor4d;
   TColor4d  = array[0..3] of double;

   {color tables}
   TColorTable_4_RGB    = array[0..015] of TColor3ub;
   TColorTable_4_RGBA   = array[0..015] of TColor4ub;
   TColorTable_8_RGB    = array[0..255] of TColor3ub;
   TColorTable_8_RGBA   = array[0..255] of TColor4ub;

CONST
   {some frequently used colors}
   cWhite4ub:  TColor4ub = (255, 255, 255, 255);
   cBlack4ub:  TColor4ub = (000, 000, 000, 255);
   cRed4ub:    TColor4ub = (255, 000, 000, 255);
   cGreen4ub:  TColor4ub = (000, 255, 000, 255);
   cBlue4ub:   TColor4ub = (000, 000, 255, 255);

   cWhite4f:   TColor4f  = (1.0, 1.0, 1.0, 1.0);
   cBlack4f:   TColor4f  = (0.0, 0.0, 0.0, 1.0);
   cRed4f:     TColor4f  = (1.0, 0.0, 0.0, 1.0);
   cGreen4f:   TColor4f  = (0.0, 1.0, 0.0, 1.0);
   cBlue4f:    TColor4f  = (0.0, 0.0, 1.0, 1.0);

VAR
   cWhite3ub:  TColor3ub absolute cWhite4ub;
   cBlack3ub:  TColor3ub absolute cBlack4ub;
   cRed3ub:    TColor3ub absolute cRed4ub;
   cGreen3ub:  TColor3ub absolute cGreen4ub;
   cBlue3ub:   TColor3ub absolute cBlue4ub;

   cWhite3f:   TColor3f absolute cWhite4f;
   cBlack3f:   TColor3f absolute cBlack4f;
   cRed3f:     TColor3f absolute cRed4f;
   cGreen3f:   TColor3f absolute cGreen4f;
   cBlue3f:    TColor3f absolute cBlue4f;

TYPE

   { TColor3ubHelper }

   TColor3ubHelper = type helper for TColor3ub
      procedure Assign(c: byte);
      function ToString(): string;
      procedure Assign(r, g, b: byte); inline;
      class function Create(r, g, b: byte): TColor3ub; static; inline;
      function Darken(percent: single): TColor3ub;
      function Lighten(mul: single): TColor3ub;
      function ToColor3f(): TColor3f;
      function ToColor4f(): TColor4f;
      function ToColor4ub(): TColor4ub;
      function ToHex(): string;
   end;

   { TColor4ubHelper }

   TColor4ubHelper = type helper for TColor4ub
      procedure Assign(c: byte);
      function ToString(): string;
      procedure Assign(r, g, b, a: byte); inline;
      class function Create(r, g, b, a: byte): TColor4ub; static; inline;
      function Darken(percent: single): TColor4ub;
      function Lighten(mul: single): TColor4ub;
      function ToHex(): string;
      function ToColor3f(): TColor3f;
      function ToColor4f(): TColor4f;
      function ToColor3ub(): TColor3ub;
      {is the color transaprent (alpha < 255)}
      function Transparent(): boolean;
      {ignore the alpha value}
      function ToHex3(): string;
   end;

   { TColor3fHelper }

   TColor3fHelper = type helper for TColor3f
      procedure Assign(c: single);
      function ToString(dec: longint = 2): string;
      procedure Assign(r, g, b: single); inline;
      class function Create(r, g, b: single): TColor3f; static; inline;
      function Darken(percent: single): TColor3f;
      function Lighten(mul: single): TColor3f;
      function ToColor3ub(): TColor3ub;
      function ToColor4ub(): TColor4ub;
      function ToColor4f(): TColor4f;
   end;

   { TColor4fHelper }

   TColor4fHelper = type helper for TColor4f
      procedure Assign(c: single);
      function ToString(dec: longint = 2): string;
      procedure Assign(r, g, b, a: single); inline;
      class function Create(r, g, b, a: single): TColor4f; static; inline;
      procedure Assign(const color: TColor3f); inline;
      function Darken(percent: single): TColor4f;
      function Lighten(mul: single): TColor4f;
      function ToColor3ub(): TColor3ub;
      function ToColor4ub(): TColor4ub;
      function ToColor3f(): TColor4f;
   end;

   { TColorsGlobal }

   TColorsGlobal = record
      fLUT256: array[0..255] of single;

      class function FromHex(var s: string; var c: TColor3ub): boolean; static;
      class procedure ToHex(var c: TColor3ub; var s: string); static;
      class function ToHexf(var c: TColor3ub): string; static;
      class function ToHexf(var c: TColor4ub): string; static;
   end;

VAR
   colors: TColorsGlobal;


IMPLEMENTATION


class function TColorsGlobal.FromHex(var s: string; var c: TColor3ub): boolean;
var
   l,
   code: longint;
   clr: TColor3ub;

begin
   Result   := false;
   l        := Length(s);

   if(l = 7) then begin
      if(s[1] = '#') then begin
         val('$' + copy(s, 2, 2), clr[0], code);
         if(code <> 0) then
            exit;

         val('$' + copy(s, 4, 2), clr[1], code);
         if(code <> 0) then
            exit;

         val('$' + copy(s, 6, 2), clr[2], code);
         if(code = 0) then begin
            c        := clr;
            Result   := true;
         end;
      end;
   end;
end;

class procedure TColorsGlobal.ToHex(var c: TColor3ub; var s: string);
begin
   s := '#' + HexStr(c[0], 2) + HexStr(c[1], 2) + HexStr(c[2], 2);
end;

class function TColorsGlobal.ToHexf(var c: TColor3ub): string;
begin
   Result := '#' + HexStr(c[0], 2) + HexStr(c[1], 2) + HexStr(c[2], 2);
end;

class function TColorsGlobal.ToHexf(var c: TColor4ub): string;
begin
   Result := '#' + HexStr(c[0], 2) + HexStr(c[1], 2) + HexStr(c[2], 2) + HexStr(c[3], 2);
end;

procedure initColorIndices();
var
   i: longint;

begin
   for i := 0 to 255 do
      colors.fLUT256[i] := 1 / 255 * i;
end;


{ TColor3ubHelper }

procedure TColor3ubHelper.Assign(c: byte);
begin
   Self[0] := c;
   Self[1] := c;
   Self[2] := c;
end;

function TColor3ubHelper.ToString(): string;
begin
   Result := sf(Self[0]) + ',' + sf(Self[1]) + ',' + sf(Self[2]);
end;

procedure TColor3ubHelper.Assign(r, g, b: byte);
begin
   Self[0] := r;
   Self[1] := g;
   Self[2] := b;
end;

class function TColor3ubHelper.Create(r, g, b: byte): TColor3ub;
begin
   Result[0] := r;
   Result[1] := g;
   Result[2] := b;
end;

function TColor3ubHelper.Darken(percent: single): TColor3ub;
var
   mul: single;

begin
   mul := 1 - percent;

   if(mul < 0) then
      mul := 0;

   Result[0] := round(mul * self[0]);
   Result[1] := round(mul * self[1]);
   Result[2] := round(mul * self[2]);
end;

function TColor3ubHelper.Lighten(mul: single): TColor3ub;
begin
   if(self[0] * mul <= 255) then
      Result[0] := round(self[0] * mul)
   else
      Result[0] := 255;

   if(self[1] * mul <= 255) then
      Result[1] := round(self[1] * mul)
   else
      Result[1] := 255;

   if(self[2] * mul <= 255) then
      Result[2] := round(self[2] * mul)
   else
      Result[2] := 255;
end;

function TColor3ubHelper.ToColor3f(): TColor3f;
var
   p: single;

begin
   p := 1 / 255;

   Result[0] := p * Self[0];
   Result[1] := p * Self[1];
   Result[2] := p * Self[2];
end;

function TColor3ubHelper.ToColor4f(): TColor4f;
var
   p: single;

begin
   p := 1 / 255;

   Result[0] := p * Self[0];
   Result[1] := p * Self[1];
   Result[2] := p * Self[2];
   Result[3] := 1.0;
end;

function TColor3ubHelper.ToColor4ub(): TColor4ub;
begin
   Result[0] := Self[0];
   Result[1] := Self[1];
   Result[2] := Self[2];
   Result[3] := 255;
end;

function TColor3ubHelper.ToHex(): string;
begin
   Result := '#' + HexStr(Self[0], 2) + HexStr(Self[1], 2) + HexStr(Self[2], 2);
end;


{ TColor4ubHelper }

procedure TColor4ubHelper.Assign(c: byte);
begin
   Self[0] := c;
   Self[1] := c;
   Self[2] := c;
   Self[3] := c;
end;

function TColor4ubHelper.ToString(): string;
begin
   Result := sf(Self[0]) + ',' + sf(Self[1]) + ',' + sf(Self[2]) + ',' + sf(Self[3]);
end;

procedure TColor4ubHelper.Assign(r, g, b, a: byte);
begin
   Self[0] := r;
   Self[1] := g;
   Self[2] := b;
   Self[3] := a;
end;

class function TColor4ubHelper.Create(r, g, b, a: byte): TColor4ub;
begin
   Result[0] := r;
   Result[1] := g;
   Result[2] := b;
   Result[3] := a;
end;

function TColor4ubHelper.Darken(percent: single): TColor4ub;
var
   mul: single;

begin
   mul := 1 - percent;

   if(mul < 0) then
      mul := 0;

   Result[0] := round(mul * self[0]);
   Result[1] := round(mul * self[1]);
   Result[2] := round(mul * self[2]);
   Result[3] := self[3];
end;

function TColor4ubHelper.Lighten(mul: single): TColor4ub;
begin
   if(self[0] * mul <= 255) then
      Result[0] := round(self[0] * mul)
   else
      Result[0] := 255;

   if(self[1] * mul <= 255) then
      Result[1] := round(self[1] * mul)
   else
      Result[1] := 255;

   if(self[2] * mul <= 255) then
      Result[2] := round(self[2] * mul)
   else
      Result[2] := 255;

   if(self[3] * mul <= 255) then
      Result[3] := round(self[3] * mul)
   else
      Result[3] := 255;
end;

function TColor4ubHelper.ToHex(): string;
begin
   Result := '#' + HexStr(Self[0], 2) + HexStr(Self[1], 2) + HexStr(Self[2], 2) + HexStr(Self[3], 2);
end;

function TColor4ubHelper.ToColor3f(): TColor3f;
var
   p: single;

begin
   p := 1 / 255;

   Result[0] := p * Self[0];
   Result[1] := p * Self[1];
   Result[2] := p * Self[2];
end;

function TColor4ubHelper.ToColor4f(): TColor4f;
var
   p: single;

begin
   p := 1 / 255;

   Result[0] := p * Self[0];
   Result[1] := p * Self[1];
   Result[2] := p * Self[2];
   Result[3] := p * Self[3];
end;

function TColor4ubHelper.ToColor3ub(): TColor3ub;
begin
   Result[0] := Self[0];
   Result[1] := Self[1];
   Result[2] := Self[2];
end;

function TColor4ubHelper.Transparent(): boolean;
begin
   Result := Self[3] < 255;
end;

function TColor4ubHelper.ToHex3(): string;
begin
   Result := '#' + HexStr(Self[0], 2) + HexStr(Self[1], 2) + HexStr(Self[2], 2);
end;


{ TColor3fHelper }

procedure TColor3fHelper.Assign(c: single);
begin
   Self[0] := c;
   Self[1] := c;
   Self[2] := c;
end;

function TColor3fHelper.ToString(dec: longint = 2): string;
begin
   Result := sf(Self[0], dec) + ',' + sf(Self[1], dec) + ',' + sf(Self[2], dec);
end;

procedure TColor3fHelper.Assign(r, g, b: single);
begin
   Self[0] := r;
   Self[1] := g;
   Self[2] := b;
end;

class function TColor3fHelper.Create(r, g, b: single): TColor3f;
begin
   Result[0] := r;
   Result[1] := g;
   Result[2] := b;
end;

function TColor3fHelper.Darken(percent: single): TColor3f;
var
   mul: single;

begin
   mul := 1 - percent;

   if(mul < 0) then
      mul := 0;

   Result[0] := round(mul * self[0]);
   Result[1] := round(mul * self[1]);
   Result[2] := round(mul * self[2]);
end;

function TColor3fHelper.Lighten(mul: single): TColor3f;
begin
   if(self[0] * mul <= 1.0) then
      Result[0] := self[0] * mul
   else
      Result[0] := 1;

   if(self[1] * mul <= 1.0) then
      Result[1] := self[1] * mul
   else
      Result[1] := 1;

   if(self[2] * mul <= 1.0) then
      Result[2] := self[2] * mul
   else
      Result[2] := 1;
end;

function TColor3fHelper.ToColor3ub(): TColor3ub;
begin
   Result[0] := round(Self[0] * 255);
   Result[1] := round(Self[1] * 255);
   Result[2] := round(Self[2] * 255);
end;

function TColor3fHelper.ToColor4ub(): TColor4ub;
begin
   Result[0] := round(Self[0] * 255);
   Result[1] := round(Self[1] * 255);
   Result[2] := round(Self[2] * 255);
   Result[3] := 255;
end;

function TColor3fHelper.ToColor4f(): TColor4f;
begin
   Result[3] := 1.0;
   Move(Self, Result, SizeOf(single) * 3);
end;

{ TColor4fHelper }

procedure TColor4fHelper.Assign(c: single);
begin
   Self[0] := c;
   Self[1] := c;
   Self[2] := c;
   Self[3] := c;
end;

function TColor4fHelper.ToString(dec: longint = 2): string;
begin
   Result := sf(Self[0], dec) + ',' + sf(Self[1], dec) + ',' +
      sf(Self[2], dec) + ',' + sf(Self[3], dec);
end;

procedure TColor4fHelper.Assign(r, g, b, a: single);
begin
   Self[0] := r;
   Self[1] := g;
   Self[2] := b;
   Self[3] := a;
end;

class function TColor4fHelper.Create(r, g, b, a: single): TColor4f;
begin
   Result[0] := r;
   Result[1] := g;
   Result[2] := b;
   Result[3] := a;
end;

procedure TColor4fHelper.Assign(const color: TColor3f);
begin
   Self[0] := color[0];
   Self[1] := color[1];
   Self[2] := color[2];
end;

function TColor4fHelper.Darken(percent: single): TColor4f;
var
   mul: single;

begin
   mul := 1 - percent;

   if(mul < 0) then
      mul := 0;

   Result[0] := round(mul * self[0]);
   Result[1] := round(mul * self[1]);
   Result[2] := round(mul * self[2]);
   Result[3] := self[3];
end;

function TColor4fHelper.Lighten(mul: single): TColor4f;
begin
   if(self[0] * mul <= 1.0) then
      Result[0] := self[0] * mul
   else
      Result[0] := 1;

   if(self[1] * mul <= 1.0) then
      Result[1] := self[1] * mul
   else
      Result[1] := 1;

   if(self[2] * mul <= 1.0) then
      Result[2] := self[2] * mul
   else
      Result[2] := 1;

   if(self[3] * mul <= 1.0) then
      Result[3] := self[3] * mul
   else
      Result[3] := 1;
end;

function TColor4fHelper.ToColor3ub(): TColor3ub;
begin
   Result[0] := round(Self[0] * 255);
   Result[1] := round(Self[1] * 255);
   Result[2] := round(Self[2] * 255);
end;

function TColor4fHelper.ToColor4ub(): TColor4ub;
begin
   Result[0] := round(Self[0] * 255);
   Result[1] := round(Self[1] * 255);
   Result[2] := round(Self[2] * 255);
   Result[3] := round(Self[3] * 255);
end;

function TColor4fHelper.ToColor3f(): TColor4f;
begin
   Result[0] := Self[0];
   Result[1] := Self[1];
   Result[2] := Self[2];
end;

INITIALIZATION
   initColorIndices();

END.

