{
   uTVideoColors
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uTVideoColors;

INTERFACE

   USES
      uStd, uLog, Video, uTVideo, uColors, ConsoleUtils;

function tvGetColor3ub(front, back: TVideoColor): TColor3ub;
function tvGetColor4ub(front, back: TVideoColor): TColor4ub;
function tvGetColor3ub(front, back: TVideoColor; attributes: TVideoAttribute): TColor3ub;
function tvGetColor4ub(front, back: TVideoColor; attributes: TVideoAttribute): TColor4ub;

IMPLEMENTATION

function tvGetColor3ub(front, back: TVideoColor): TColor3ub;
begin
   Result[0] := front;
   Result[1] := back;
   Result[2] := 0;
end;

function tvGetColor4ub(front, back: TVideoColor): TColor4ub;
begin
   Result[0] := front;
   Result[1] := back;
   Result[2] := 0;
   Result[3] := 255;
end;

function tvGetColor3ub(front, back: TVideoColor; attributes: TVideoAttribute): TColor3ub;
begin
   Result[0] := front;
   Result[1] := back;
   Result[2] := attributes;
end;

function tvGetColor4ub(front, back: TVideoColor; attributes: TVideoAttribute): TColor4ub;
begin
   Result[0] := front;
   Result[1] := back;
   Result[2] := attributes;
   Result[3] := 255;
end;

END.
