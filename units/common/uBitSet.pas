{
   uBitSet, bitset manipulation
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uBitSet;

INTERFACE

   USES uStd;

TYPE
   PBitsSet = ^TBitsSet;
   TBitsSet = record
      Size: longint;
      Bits: array of longword;
   end;

{GENERAL MANAGEMENT}

{init}
procedure bsInit(out bs: TBitsSet); inline;
{make}
function bsMake(): PBitsSet;
{make elements}
function bsMake(elements: longword): TBitsSet;
{resizes the bitset}
function bsResize(var bs: TBitsSet; elements: longword): boolean;
{dispose}
procedure bsDispose(var bs: TBitsSet);
procedure bsDispose(var bs: PBitsSet);

{BIT MANIPULATION}

{sets a bit to 1 in the bitset}
procedure bsSet(var bs: TBitsSet; x: longword); inline;
{sets a bit to 0 in the bitset}
procedure bsClear(var bs: TBitsSet; x: longword); inline;
{returns the value of the specified bit}
function bsOn(var bs: TBitsSet; x: longword): longword; inline;
{sets the value of all bits to 0}
procedure bsClearAll(var bs: TBitsSet);

procedure ClearBit(var Value: QWord; Index: Byte);
procedure SetBit(var Value: QWord; Index: Byte);
procedure PutBit(var Value: QWord; Index: Byte; State: Boolean);
function GetBit(Value: QWord; Index: Byte): Boolean;

procedure ClearBit(var Value: DWord; Index: Byte);
procedure SetBit(var Value: DWord; Index: Byte);
procedure PutBit(var Value: DWord; Index: Byte; State: Boolean);
function GetBit(Value: DWord; Index: Byte): Boolean;

procedure ClearBit(var Value: word; Index: Byte);
procedure SetBit(var Value: word; Index: Byte);
procedure PutBit(var Value: word; Index: Byte; State: Boolean);
function GetBit(Value: word; Index: Byte): Boolean;


IMPLEMENTATION

{GENERAL MANAGEMENT}

procedure bsInit(out bs: TBitsSet); inline;
begin
   ZeroOut(bs, SizeOf(TBitsSet));
end;

function bsMake(): PBitsSet;
var
   bs: PBitsSet = nil;

begin
   new(bs);
   if(bs <> nil) then 
      bsInit(bs^);

   bsMake := bs;
end;

function bsMake(elements: longword): TBitsSet;
var
   bs: TBitsSet = (
      Size: 0;
      Bits: nil
   );

begin
   bsResize(bs, elements);

   result := bs;
end;

function bsResize(var bs: TBitsSet; elements: longword): boolean;
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
procedure bsDispose(var bs: TBitsSet);
begin
   if(Length(bs.Bits) <> 0) then begin
      SetLength(bs.Bits, 0); 
      bs.Bits := nil;
   end;

   bs.Size := 0;
end;

procedure bsDispose(var bs: PBitsSet);
begin
   if(bs <> nil) then begin
      bsDispose(bs^); 
      dispose(bs); 
      bs := nil;
   end;
end;

{BIT MANIPULATION}
{sets a bit to 1 in the bitset}
procedure bsSet(var bs: TBitsSet; x: longword);
var
   y: longword;

begin
   y := x shr 5;
   bs.Bits[y] := bs.Bits[y] or longword((1 shl (x and 31)));
end;

{sets a bit to 0 in the bitset}
procedure bsClear(var bs: TBitsSet; x: longword);
var
   y: longword;

begin
   y := x shr 5;
   bs.Bits[y] := bs.Bits[y] and longword((not(1 shl (x and 31))));
end;

{returns the value of the specified bit}
function bsOn(var bs: TBitsSet; x: longword): longword;
var
   y: longword;

begin
   y := x shr 5;
   bsOn := bs.Bits[y] and longword((1 shl (x and 31)));
end;

{sets the value of all bits to 0}
procedure bsClearAll(var bs: TBitsSet);
begin
   if(bs.Bits <> nil) then 
      Zero(bs.Bits[0], bs.Size*SizeOf(longword));
end;

{ QWORD BIT OPERATIONS }

procedure ClearBit(var Value: QWord; Index: Byte);
begin
   Value := Value and ((QWord(1) shl Index) xor High(QWord));
end;

procedure SetBit(var Value: QWord; Index: Byte);
begin
   Value:=  Value or (QWord(1) shl Index);
end;

procedure PutBit(var Value: QWord; Index: Byte; State: Boolean);
begin
   Value := (Value and ((QWord(1) shl Index) xor High(QWord))) or (QWord(State) shl Index);
end;

function GetBit(Value: QWord; Index: Byte): Boolean;
begin
   Result := ((Value shr Index) and 1) = 1;
end;

{ DWORD BIT OPERATIONS }

procedure ClearBit(var Value: DWord; Index: Byte);
begin
   Value := Value and ((DWord(1) shl Index) xor High(DWord));
end;

procedure SetBit(var Value: DWord; Index: Byte);
begin
   Value:=  Value or (DWord(1) shl Index);
end;

procedure PutBit(var Value: DWord; Index: Byte; State: Boolean);
begin
   Value := (Value and ((DWord(1) shl Index) xor High(DWord))) or (DWord(State) shl Index);
end;

function GetBit(Value: DWord; Index: Byte): Boolean;
begin
   Result := ((Value shr Index) and 1) = 1;
end;

{ WORD BIT OPERATIONS }

procedure ClearBit(var Value: word; Index: Byte);
begin
   Value := Value and ((Word(1) shl Index) xor High(Word));
end;

procedure SetBit(var Value: word; Index: Byte);
begin
   Value:=  Value or (Word(1) shl Index);
end;

procedure PutBit(var Value: word; Index: Byte; State: Boolean);
begin
   Value := (Value and ((Word(1) shl Index) xor High(Word))) or (Word(State) shl Index);
end;

function GetBit(Value: word; Index: Byte): Boolean;
begin
   Result := ((Value shr Index) and 1) = 1;
end;

END.
