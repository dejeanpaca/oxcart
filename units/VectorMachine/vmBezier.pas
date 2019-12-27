{
   vmBezier, Bezier curves and patches
   Copyright (C) 2009. Dejan Boras

   Started On:    22.07.2009.
}

{$MODE OBJFPC}{$H+}
UNIT vmBezier;

INTERFACE

   USES math, uStd, vmVector;

TYPE
   {3 point bezier curve}
   T3Bezier3ub = array[0..2] of TVector3ub;
   T3Bezier3b  = array[0..2] of TVector3b;
   T3Bezier3us = array[0..2] of TVector3us;
   T3Bezier3s  = array[0..2] of TVector3s;
   T3Bezier3ui = array[0..2] of TVector3ui;
   T3Bezier3i  = array[0..2] of TVector3i;
   T3Bezier3f  = array[0..2] of TVector3f;
   T3Bezier3d  = array[0..2] of TVector3d;
   T3Bezier3e  = array[0..2] of TVector3e;

   {4 point bezier curve}
   T4Bezier3ub = array[0..3] of TVector3ub;
   T4Bezier3b  = array[0..3] of TVector3b;
   T4Bezier3us = array[0..3] of TVector3us;
   T4Bezier3s  = array[0..3] of TVector3s;
   T4Bezier3ui = array[0..3] of TVector3ui;
   T4Bezier3i  = array[0..3] of TVector3i;
   T4Bezier3f  = array[0..3] of TVector3f;
   T4Bezier3d  = array[0..3] of TVector3d;
   T4Bezier3e  = array[0..3] of TVector3e;

   {9 control point patches}
   T3BezierPatch3b  = array[0..2] of T3Bezier3b;
   T3BezierPatch3ub = array[0..2] of T3Bezier3ub;
   T3BezierPatch3s  = array[0..2] of T3Bezier3s;
   T3BezierPatch3us = array[0..2] of T3Bezier3us;
   T3BezierPatch3i  = array[0..2] of T3Bezier3i;
   T3BezierPatch3ui = array[0..2] of T3Bezier3ui;
   T3BezierPatch3f  = array[0..2] of T3Bezier3f;
   T3BezierPatch3d  = array[0..2] of T3Bezier3d;
   T3BezierPatch3e  = array[0..2] of T3Bezier3e;

   {16 control point patches}
   T4BezierPatch3b  = array[0..3] of T4Bezier3b;
   T4BezierPatch3ub = array[0..3] of T4Bezier3ub;
   T4BezierPatch3s  = array[0..3] of T4Bezier3s;
   T4BezierPatch3us = array[0..3] of T4Bezier3us;
   T4BezierPatch3i  = array[0..3] of T4Bezier3i;
   T4BezierPatch3ui = array[0..3] of T4Bezier3ui;
   T4BezierPatch3f  = array[0..3] of T4Bezier3f;
   T4BezierPatch3d  = array[0..3] of T4Bezier3d;
   T4BezierPatch3e  = array[0..3] of T4Bezier3e;

   {9 control point multi patch}
   T3BezierMultiPatch3b = record
      dim: TVector2i;
      p: array of T3BezierPatch3b;
   end;
   T3BezierMultiPatch3ub = record
      dim: TVector2i;
      p: array of T3BezierPatch3ub;
   end;
   T3BezierMultiPatch3s = record
      dim: TVector2i;
      p: array of T3BezierPatch3us;
   end;
   T3BezierMultiPatch3i = record
      dim: TVector2i;
      p: array of T3BezierPatch3i;
   end;
   T3BezierMultiPatch3ui = record
      dim: TVector2i;
      p: array of T3BezierPatch3ui;
   end;
   T3BezierMultiPatch3f = record
      dim: TVector2i;
      p: array of T3BezierPatch3f;
   end;
   T3BezierMultiPatch3d = record
      dim: TVector2i;
      p: array of T3BezierPatch3d;
   end;
   T3BezierMultiPatch3e = record
      dim: TVector2i;
      p: array of T3BezierPatch3e;
   end;

   {16 control point multi patch}
   T4BezierMultiPatch3b = record
      dim: TVector2i;
      p: array of T4BezierPatch3b;
   end;
   T4BezierMultiPatch3ub = record
      dim: TVector2i;
      p: array of T4BezierPatch3ub;
   end;
   T4BezierMultiPatch3s = record
      dim: TVector2i;
      p: array of T4BezierPatch3us;
   end;
   T4BezierMultiPatch3i = record
      dim: TVector2i;
      p: array of T4BezierPatch3i;
   end;
   T4BezierMultiPatch3ui = record
      dim: TVector2i;
      p: array of T4BezierPatch3ui;
   end;
   T4BezierMultiPatch3f = record
      dim: TVector2i;
      p: array of T4BezierPatch3f;
   end;
   T4BezierMultiPatch3d = record
      dim: TVector2i;
      p: array of T4BezierPatch3d;
   end;
   T4BezierMultiPatch3e = record
      dim: TVector2i;
      p: array of T4BezierPatch3e;
   end;


{calculates a 3rd degree polynomial based on an array of 3 points}
function vmbzInterpolate(u: single; const p: T3Bezier3f): TVector3f;
function vmbzInterpolate(const u: double; const p: T3Bezier3d): TVector3d;

{calculates a 3rd degree polynomial based on an array of 4 points}
function vmbzInterpolate(u: single; const p: T4Bezier3f): TVector3f;
function vmbzInterpolate(const u: double; const p: T4Bezier3d): TVector3d;

{ MULTI PATCHES }

{initialize the multipatch record}
procedure vmbzInitMultiPatchRecord(var mp: T3BezierMultiPatch3f);
procedure vmbzInitMultiPatchRecord(var mp: T4BezierMultiPatch3f);

{set the size of a multi patch}
function vmbzMultiPatchSize(var mp: T3BezierMultiPatch3f; x, y: longint): boolean;
function vmbzMultiPatchSize(var mp: T4BezierMultiPatch3f; x, y: longint): boolean;

{dispose of a multi patch}
procedure vmbzMultiPatchDispose(var mp: T4BezierMultiPatch3f);

{converts a patch array to multi-patch}
procedure vmbzPatchArrayToMultiPatch(var a: array of TVector3f; idx: longint; var mp: T3BezierMultiPatch3f);

{ POINT ARRAYS }

{builds an array of points}
procedure vmbzBuildPointArray(const bz: T3Bezier3f; n: longint; var points: array of TVector3f);
procedure vmbzBuildPointArray(const bz: T3Bezier3d; n: longint; var points: array of TVector3d);

procedure vmbzBuildPointArray(const bz: T4Bezier3f; n: longint; var points: array of TVector3f);
procedure vmbzBuildPointArray(const bz: T4Bezier3d; n: longint; var points: array of TVector3d);

IMPLEMENTATION

{TODO: The following two routines may not be correct}

function vmbzInterpolate(u: single; const p: T3Bezier3f): TVector3f;
var
   a,
   b,
   sqra,
   sqrb,
   ab2: single;
   r: TVector3f;

begin
   a := u;
   b := 1 - a;

   sqra  := sqr(a);
   sqrb  := sqr(b);
   ab2   := 2 * a * b;

   r[0] := p[0][0] * sqra + p[1][0] * ab2 + p[2][0] * sqrb;
   r[1] := p[0][1] * sqra + p[1][1] * ab2 + p[2][1] * sqrb;
   r[2] := p[0][2] * sqra + p[1][2] * ab2 + p[2][2] * sqrb;

   result := r;
end;

function vmbzInterpolate(const u: double; const p: T3Bezier3d): TVector3d;
var
   a,
   b,
   sqra,
   sqrb,
   ab2: double;
   r: TVector3d;

begin
   a := u;
   b := 1 - a;

   sqra := sqr(a);
   sqrb := sqr(b);
   ab2 := 2 * a * b;

   r[0] := p[0][0] * sqra + p[1][0] * ab2 + p[2][0] * sqrb;
   r[1] := p[0][1] * sqra + p[1][1] * ab2 + p[2][1] * sqrb;
   r[2] := p[0][2] * sqra + p[1][2] * ab2 + p[2][2] * sqrb;

   result := r;
end;

function vmbzInterpolate(u: single; const p: T4Bezier3f): TVector3f;
var
   a,
   b,
   c,
   d: TVector3f;

begin
   a := p[0] * power(u, 3);
   b := p[1] * (3 * power(u, 2) * (1 - u));
   c := p[2] * (3 * u * power((1 - u), 2));
   d := p[3] * power((1 - u), 3);

   result := (a + b) + (c + d);
end;

function vmbzInterpolate(const u: double; const p: T4Bezier3d): TVector3d;
var
   a,
   b,
   c,
   d: TVector3d;

begin
   a := p[0] * power(u, 3);
   b := p[1] * (3 * power(u, 2) * (1 - u));
   c := p[2] * (3 * u * power((1 - u), 2));
   d := p[3] * power((1 - u), 3);

   result := (a + b) + (c + d);
end;

{ MULTI PATCHES }

procedure vmbzInitMultiPatchRecord(var mp: T3BezierMultiPatch3f);
begin
   Zero(mp, SizeOf(T3BezierMultiPatch3f));
end;

procedure vmbzInitMultiPatchRecord(var mp: T4BezierMultiPatch3f);
begin
   Zero(mp, SizeOf(T4BezierMultiPatch3f));
end;

function vmbzMultiPatchSize(var mp: T3BezierMultiPatch3f; x, y: longint): boolean;
var
   size, i: longint;

begin
   if(x < 1) then
      x := 1;
   if(y < 1) then
      y := 1;

   if(mp.dim[0] <> x) or (mp.dim[1] <> y) then begin
      mp.dim[0] := x;
      mp.dim[1] := y;

      size := y * x;
      SetLength(mp.p, size);
      if(Length(mp.p) = size) then begin
         for i := 0 to (size-1) do
            Zero(mp.p[i], SizeOf(T3BezierPatch3f));
         result := false;
      end else
         result := false;
   end else
      result := true;
end;

function vmbzMultiPatchSize(var mp: T4BezierMultiPatch3f; x, y: longint): boolean;
var
   size, i: longint;

begin
   if(x < 1) then
      x := 1;
   if(y < 1) then
      y := 1;

   if(mp.dim[0] <> x) or (mp.dim[1] <> y) then begin
      mp.dim[0] := x;
      mp.dim[1] := y;

      size := y*x;
      SetLength(mp.p, size);
      if(Length(mp.p) = size) then begin
         for i := 0 to (size-1) do
            Zero(mp.p[i], SizeOf(T4BezierPatch3f));
         result := true;
      end else
         result := false;
   end else
      result := true;
end;

procedure vmbzMultiPatchDispose(var mp: T4BezierMultiPatch3f);
begin
   if(mp.p <> nil) then begin
      SetLength(mp.p, 0);
      mp.p := nil;
   end;

   mp.dim[0] := 0;
   mp.dim[1] := 0;
end;


procedure vmbzPatchArrayToMultiPatch(var a: array of TVector3f; idx: longint; var mp: T3BezierMultiPatch3f);
var
   i,
   j,
   {x, y,}
   px,
   py,
   patch,
   sizex,
   pos: longint;
   {i, j - patch}
   {x, y - patch point}

begin
   if(mp.dim[0] > 0) and (mp.dim[1] > 0) then begin

      {calculate how many points there are in an entire row}
      sizex := (3) + ((mp.dim[0] - 1) * 2);

      for j := 0 to (mp.dim[1]-1) do begin
         for i := 0 to (mp.dim[0]-1) do begin
            px := i*2; py := j*2;
            patch := (j * mp.dim[0]) + i;

            {move the points into a patch}
            pos := ((py + 0) * sizex) + (px + 0);
            mp.p[patch][0][0] := a[idx + pos];
            pos := ((py + 0) * sizex) + (px + 1);
            mp.p[patch][0][1] := a[idx + pos];
            pos := ((py + 0) * sizex) + (px + 2);
            mp.p[patch][0][2] := a[idx + pos];

            pos := ((py + 1) * sizex) + (px + 0);
            mp.p[patch][1][0] := a[idx + pos];
            pos := ((py + 1) * sizex) + (px + 1);
            mp.p[patch][1][1] := a[idx + pos];
            pos := ((py + 1) * sizex) + (px + 2);
            mp.p[patch][1][2] := a[idx + pos];

            pos := ((py + 2) * sizex) + (px + 0);
            mp.p[patch][2][0] := a[idx + pos];
            pos := ((py + 2) * sizex) + (px + 1);
            mp.p[patch][2][1] := a[idx + pos];
            pos := ((py + 2) * sizex) + (px + 2);
            mp.p[patch][2][2] := a[idx + pos];

            (* //wrapped version

		    for y := 0 to 2 do begin
               for x := 0 to 2 do begin
                  pos := ((py + y) * sizex) + (px + x);
                  mp.p[patch][y][x] := a[idx + pos]; {BUG?}
               end;
            end;{y}*)
            {done with the current patch, go to next}
         end;{i}
      end;{j}
   end;
end;

{ POINT ARRAYS }

{builds an array of points}
procedure vmbzBuildPointArray(const bz: T3Bezier3f; n: longint; var points: array of TVector3f);
{$INCLUDE operators/bzbuildpointarraysingle.inc}

procedure vmbzBuildPointArray(const bz: T3Bezier3d; n: longint; var points: array of TVector3d);
{$INCLUDE operators/bzbuildpointarraydouble.inc}

procedure vmbzBuildPointArray(const bz: T4Bezier3f; n: longint; var points: array of TVector3f);
{$INCLUDE operators/bzbuildpointarraysingle.inc}

procedure vmbzBuildPointArray(const bz: T4Bezier3d; n: longint; var points: array of TVector3d);
{$INCLUDE operators/bzbuildpointarraydouble.inc}

END.
