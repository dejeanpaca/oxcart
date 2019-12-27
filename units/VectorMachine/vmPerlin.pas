{
   vmPerlin, perlin noise operations
   Copyright (C) 2010. Dejan Boras

   Started On:    03.10.2010.

   PERFORMANCE NOTE: The performance of vmPerlin functions is not very
   impressive if FPU exceptions are enabled. Disable FPU exceptions via:
   SetExceptionMask([exInvalidOp, exOverflow, exUnderflow, exPrecision]);
   This will drastically improve performance.
}

{$MODE OBJFPC}{$H+}
UNIT vmPerlin;

INTERFACE

   USES math, vmMath;

CONST
   vmPERLIN_SIMPLE         = 0000;
   vmPERLIN_SMOOTHED       = 0001;
   vmPERLIN_INTERPOLATED   = 0002;


TYPE
   vmPPerlin2D = ^vmTPerlin2D;

   vmTPerlinNoise2DFunc       = function(x, y: single): single;
   vmTPerlinInterpolate2DFunc = function(x, y: single; p2d: vmPPerlin2D): single;
   vmTPerlinSmooth2DFunc      = function(x, y: single; p2d: vmPPerlin2D): single;

   vmTPerlin2D = record
      Interpolate: vmTPerlinInterpolate2DFunc;
      Smooth: vmTPerlinSmooth2DFunc;
      Noise: vmTPerlinNoise2DFunc;
      Persistence: single;
      Octaves: longint;
      Properties: dword;
   end;

VAR
   vmPerlin2DDefault: vmTPerlin2D;

{2D PERLIN NOISE}
function vmPerlinNoise2DF1(x, y: single): single;
function vmPerlinSmooth2DF1(x, y: single; const p2d: vmTPerlin2D): single;
function vmPerlinInterpolate2DF1(x, y: single; const p2d: vmTPerlin2D): single;

function vmPerlinNoise2D(x, y: single; const p2d: vmTPerlin2D): single;
function vmPerlinSmoothedNoise2D(x, y: single; const p2d: vmTPerlin2D): single;
function vmPerlinInterpolatedNoise2D(x, y: single; const p2d: vmTPerlin2D): single;

IMPLEMENTATION

function vmPerlinNoise2DF1(x, y: single): single;
var
   n: longint;

begin
   n := round(x + y * 57);
   try
      {this will most definitely generate an exception}
      n := round(power(n shl 13, n));
   except
   end;
   {$PUSH}{$Q-}
   {this will most likely cause an overflow check failure}
   result := 1.0 - ( (n * (n * n * 15731 + 789221) + 1376312589) and $7fffffff) / 1073741824.0;
   {$POP}
end;

function vmPerlinSmooth2DF1(x, y: single; const p2d: vmTPerlin2D): single;
var
   corners, sides, center: single;

begin
   corners  := (p2d.Noise(x - 1, y - 1) + p2d.Noise(x + 1, y - 1) + p2d.Noise(x - 1, y + 1) + p2d.Noise(x + 1, y + 1)) / 16;
   sides    := (p2d.Noise(x - 1, y) + p2d.Noise(x + 1, y) + p2d.Noise(x, y - 1) + p2d.Noise(x, y + 1)) /  8;
   center   :=  p2d.Noise(x, y) / 4;
   result   := corners + sides + center;
end;

function vmPerlinInterpolate2DF1(x, y: single; const p2d: vmTPerlin2D): single;
var
   iX, iY: longint;
   fX, fY: single;
   v1, v2, v3, v4: single;
   i1, i2: single;

begin
   iX := round(x);
   iY := round(y);
   fX := x - iX;
   fY := y - iY;

   v1 := p2d.Smooth(iX    , iY   , @p2d);
   v2 := p2d.Smooth(iX + 1, iY   , @p2d);
   v3 := p2d.Smooth(iX    , iY +1, @p2d);
   v4 := p2d.Smooth(iX + 1, iY +1, @p2d);

   i1 := vmLinearInterpolation(v1, v2, fX);
   i2 := vmLinearInterpolation(v3, v4, fY);

   result := vmLinearInterpolation(i1, i2, fY);
end;

function vmPerlinNoise2D(x, y: single; const p2d: vmTPerlin2D): single;
var
   i: longint;
   total: single = 0.0;
   frequency, amplitude: single;

begin
   if(p2d.Octaves > 0) then
      for i := 0 to (p2d.Octaves-1) do begin
         frequency := power(2, i);
         amplitude := power(p2d.persistence, i);

         total := total + p2d.Noise(x * frequency, y * frequency) * amplitude;
      end;

   result := total;
end;

function vmPerlinSmoothedNoise2D(x, y: single; const p2d: vmTPerlin2D): single;
var
   i: longint;
   total: single = 0.0;
   frequency, amplitude: single;

begin
   if(p2d.Octaves > 0) then
      for i := 0 to (p2d.Octaves-1) do begin
         frequency := power(2, i);
         amplitude := power(p2d.persistence, i);

         total := total + p2d.Smooth(x * frequency, y * frequency, @p2d) * amplitude;
      end;

   result := total;
end;

function vmPerlinInterpolatedNoise2D(x, y: single; const p2d: vmTPerlin2D): single;
var
   i: longint;
   total: single = 0.0;
   frequency, amplitude: single;

begin
   if(p2d.Octaves > 0) then
      for i := 0 to (p2d.Octaves-1) do begin
         frequency := power(2, i);
         amplitude := power(p2d.persistence, i);

         total := total + p2d.Interpolate(x * frequency, y * frequency, @p2d) * amplitude;
      end;

   result := total;
end;

INITIALIZATION
   vmPerlin2DDefault.Interpolate    := vmTPerlinInterpolate2DFunc(@vmPerlinInterpolate2DF1);
   vmPerlin2DDefault.Smooth         := vmTPerlinSmooth2DFunc(@vmPerlinSmooth2DF1);
   vmPerlin2DDefault.Noise          := @vmPerlinNoise2DF1;
   vmPerlin2DDefault.Persistence    := 1.0;
   vmPerlin2DDefault.Octaves        := 4;

END.
