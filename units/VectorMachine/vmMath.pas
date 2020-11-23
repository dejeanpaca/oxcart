{
   vmMath, general math operations
   Copyright (C) 2010. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT vmMath;

INTERFACE

   USES
      math, uStd, vmVector;

VAR
   vmcPow2: array[0..63] of int64;

{square root for integers}
function vmSqrt(i: longint): longint;
function vmSqrt(i: int64): int64;

{checks whether a number is a prime number}
function vmIsPrime(i: longint): boolean;
function vmIsPrime(i: int64): boolean;

{ INTERPOLATION }
function vmLinearInterpolation(a, b, z: single): single;
function vmCosineInterpolation(a, b, z: single): single;
function vmCubicInterpolation(v0, v1, v2, v3, z: single): single;

{ STANDARD }
function vmSign(x: longint): longint; inline;
function vmSign(x: int64): int64; inline;
function vmCopySign(x, y: single): single; inline;
function vmMax(x, y: single): single; inline;
function vmMin(x, y: single): single; inline;

{ CLAMPING }
procedure vmClamp(var value: single; min, max: single); inline;

procedure vmClampMax(var value: single; max: single); inline;
function vmClampMaxf(value, max: single): single; inline;
procedure vmClampMax(var value: longint; max: longint); inline;
function vmClampMaxf(value, max: longint): longint; inline;

procedure vmIncClamp(var value: single; increment, max: single);
procedure vmDecClamp(var value: single; decrement, min: single);

procedure vmIncClamp(var value: longint; increment, max: longint);
procedure vmDecClamp(var value: longint; decrement, min: longint);

{checks if the given value is power of 2}
function vmIsPow2(value: int64): boolean;
{find the next power of 2}
function vmNextPow2(value: int64): int64;

operator mod(const a, b: double): double; inline;
operator mod(const a, b: single): single; inline;

IMPLEMENTATION

function vmSqrt(i: longint): longint;
var
   r,
   rnew,
   rold: longint;

begin
   rnew := 1;
   r := 1;

   repeat
      rold  := r;
      r     := rnew;
      rnew  := (r + round(i / r));
      rnew  := rnew shr 1;
   until (rold = rnew);

   Result := rnew;
end;

function vmSqrt(i: int64): int64;
var
   r,
   rnew,
   rold: int64;

begin
   rnew := 1;
   r := 1;

   repeat
      rold  := r;
      r     := rnew;
      rnew  := (r + round(i / r));
      rnew   := rnew shr 1;
   until (rold = rnew);

   Result := rnew;
end;

function vmIsPrime(i: longint): boolean;
var
   si,
   j: longint;

begin
	si := vmSqrt(i);
	
	for j := 2 to si do begin
      if(i mod j = 0) then
         exit(false);
	end;
	
	Result := true;
end;

function vmIsPrime(i: int64): boolean;
var
   si,
   j: int64;

begin
	si := vmSqrt(i);

   j := 2;
   repeat
      if(i mod j = 0) then
         exit(false);
      inc(j);
   until (j > si);
	
	Result := true;	
end;

{ INTERPOLATION }

function vmLinearInterpolation(a, b, z: single): single;
begin
   Result := a * (1 - z) + b * z;
end;

function vmCosineInterpolation(a, b, z: single): single;
var
   ft,
   f: single;

begin
   ft := z * vmcPi;
   f  := (1 - cos(ft)) * 0.5;

   Result := a * (1 - f) + b * f;
end;

function vmCubicInterpolation(v0, v1, v2, v3, z: single): single;
var
   p, q, r, s: single;

begin
   p := (v3 - v2) - (v0 - v1);
   q := (v0 - v1) - p;
   r := v2 - v0;
   s := v1;

   Result := power(p * z, 3) + sqr(q * z) + r * z + s;
end;

{ STANDARD }

function vmSign(x: longint): longint;
begin
   Result := integer(x > 0) - integer(x < 0);
end;

function vmSign(x: int64): int64;
begin
   Result := int64(x > 0) - int64(x < 0);
end;

function vmCopySign(x, y: single): single; inline;
begin
   Result := abs(x) * sign(y);
end;

function vmMax(x, y: single): single; inline;
begin
   if(x < y) then
      Result := y
   else
      Result := x;
end;

function vmMin(x, y: single): single;
begin
   if(y < x) then
      Result := y
   else
      Result := x;
end;

procedure vmClamp(var value: single; min, max: single);
begin
   if(value > max) then
      value := max;

   if(value < min) then
      value := min;
end;

procedure vmClampMax(var value: single; max: single);
begin
   if(value > max) then
      value := max;
end;

function vmClampMaxf(value, max: single): single;
begin
   if(value <= max) then
      Result := value
   else
      Result := max;
end;

procedure vmClampMax(var value: longint; max: longint);
begin
   if(value > max) then
      value := max;
end;

function vmClampMaxf(value, max: longint): longint;
begin
   if(value <= max) then
      Result := value
   else
      Result := max;
end;

procedure vmIncClamp(var value: single; increment, max: single);
begin
   if(value + increment <= max) then
      value := value + increment
   else
      value := max;
end;

procedure vmDecClamp(var value: single; decrement, min: single);
begin
   if(value - decrement >= min) then
      value := value - decrement
   else
      value := min;
end;

procedure vmIncClamp(var value: longint; increment, max: longint);
begin
   if(value + increment <= max) then
      inc(value, increment)
   else
      value := max;
end;

procedure vmDecClamp(var value: longint; decrement, min: longint);
begin
   if(value - decrement >= min) then
      dec(value, decrement)
   else
      value := min;
end;

function vmIsPow2(value: int64): boolean;
begin
   Result := value and (value - 1) = 0;
end;

function vmNextPow2(value: int64): int64;
var
   i: loopint;

begin
   for i := 0 to High(vmcPow2) do begin
      if(vmcPow2[i] >= value) then
         exit(vmcPow2[i])
   end;

   exit(-1);
end;

operator mod(const a, b: double): double;
begin
   Result := a - b * Int(a / b);
end;

operator mod(const a, b: single): single;
begin
   Result := a - b * Int(a / b);
end;

procedure calculatePow2Constants();
var
   i: longint;

begin
   vmcPow2[0] := 0;
   vmcPow2[1] := 1;
   vmcPow2[2] := 2;

   for i := 3 to High(vmcPow2) do begin
      vmcPow2[i] := vmcPow2[i - 1] * 2;
   end;
end;

INITIALIZATION
   calculatePow2Constants();

END.
