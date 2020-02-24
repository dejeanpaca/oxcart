{
   uBitSet, bitset manipulation
   Copyright (C) 2007. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT uBitSet;

INTERFACE

   USES uStd;

TYPE
   PBitSet = ^TBitSet;
   TBitSet = record
      Size: longint;
      Bits: array of longword;
   end;

{GENERAL MANAGEMENT}

{init}
procedure bsInit(out bs: TBitSet); inline;
{make}
function bsMake(): PBitSet;
{make elements}
function bsMake(elements: longword): TBitSet;
{resizes the bitset}
function bsResize(var bs: TBitSet; elements: longword): boolean;
{dispose}
procedure bsDispose(var bs: TBitSet);
procedure bsDispose(var bs: PBitSet);

{BIT MANIPULATION}

{sets a bit to 1 in the bitset}
procedure bsSet(var bs: TBitSet; x: longword); inline;
{sets a bit to 0 in the bitset}
procedure bsClear(var bs: TBitSet; x: longword); inline;
{returns the value of the specified bit}
function bsOn(var bs: TBitSet; x: longword): longword; inline;
{sets the value of all bits to 0}
procedure bsClearAll(var bs: TBitSet);


IMPLEMENTATION

{GENERAL MANAGEMENT}

procedure bsInit(out bs: TBitSet); inline;
begin
   ZeroOut(bs, SizeOf(TBitSet));
end;

function bsMake(): PBitSet;
var
   bs: PBitSet = nil;

begin
   new(bs);
   if(bs <> nil) then 
      bsInit(bs^);

   bsMake := bs;
end;

function bsMake(elements: longword): TBitSet;
var
   bs: TBitSet = (
      Size: 0;
      Bits: nil
   );

begin
   bsResize(bs, elements);

   result := bs;
end;

function bsResize(var bs: TBitSet; elements: longword): boolean;
var
   size: longint;

begin
   size := elements div 32;
   if(elements mod 32 <> 0) then 
      inc(size);

   SetLength(bs.bits, size);
   if(Length(bs.Bits) < size) then 
      exit(false);

   bs.Size  := size;
   result   := true;
end;

{dispose}
procedure bsDispose(var bs: TBitSet);
begin
   if(Length(bs.Bits) <> 0) then begin
      SetLength(bs.Bits, 0); 
      bs.Bits := nil;
   end;

   bs.Size := 0;
end;

procedure bsDispose(var bs: PBitSet);
begin
   if(bs <> nil) then begin
      bsDispose(bs^); 
      dispose(bs); 
      bs := nil;
   end;
end;

{BIT MANIPULATION}
{sets a bit to 1 in the bitset}
procedure bsSet(var bs: TBitSet; x: longword);
var
   y: longword;

begin
   y := x shr 5;
   bs.Bits[y] := bs.Bits[y] or longword((1 shl (x and 31)));
end;

{sets a bit to 0 in the bitset}
procedure bsClear(var bs: TBitSet; x: longword);
var
   y: longword;

begin
   y := x shr 5;
   bs.Bits[y] := bs.Bits[y] and longword((not(1 shl (x and 31))));
end;

{returns the value of the specified bit}
function bsOn(var bs: TBitSet; x: longword): longword;
var
   y: longword;

begin
   y := x shr 5;
   bsOn := bs.Bits[y] and longword((1 shl (x and 31)));
end;

{sets the value of all bits to 0}
procedure bsClearAll(var bs: TBitSet);
begin
   if(bs.Bits <> nil) then 
      Zero(bs.Bits[0], bs.Size*SizeOf(longword));
end;

END.
