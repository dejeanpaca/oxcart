{
   uStd, standard resources unit(something like system unit)
   Copyright (C) Dejan Boras 2011.

   Started on:    30.01.2011.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$MODESWITCH TYPEHELPERS}
UNIT uStd;

INTERFACE

   USES
      sysutils
      {$IFDEF UNIX}, BaseUnix{$ENDIF};

CONST
   EmptyShortString: string[1]      = '';

   {memory allocation alignment in bytes}
   dcMemoryBlockAlignment: longint  = 16;

   {endian byte}
   ENDIAN_BYTE: byte = {$IFDEF ENDIAN_LITTLE}$00{$ELSE}$FF{$ENDIF};
   ENDIAN_WORD: word = {$IFDEF ENDIAN_LITTLE}$0000{$ELSE}$FFFF{$ENDIF};

   {standard data type codes}
   {$INCLUDE stdDataTypeCodes.inc}

   {error constants}
   {$INCLUDE errorcodes.inc}

   {line endings}
   WindowsLineEnding = #13#10;
   UnixLineEnding = #10;

   {line ending names}
   LineEndingNames: array[0..2] of string = ('', 'crlf', 'lf');

TYPE
   {$IFDEF FILEINT_INT32}
      fileint = longint;
   {$ELSE}
      fileint = int64;
   {$ENDIF}

   loopint = SizeInt;

   TBoolFunction = function(): boolean;
   TPointerFunction  = function(): pointer;
   TObjectProcedure = procedure of object;
   TAppendableString = type string;
   TErrorString = TAppendableString;

   { arrays }
   TSingleArray = array of single;
   TDoubleArray = array of double;

   { TPreallocatedArrayList }

   {helps to maintain a list of elements in an array}
   generic TPreallocatedArrayList<T> = record
      {step to increment the list size by}
      Increment: loopint;
      {should memory be initialized when allocation is done}
      InitializeMemory: boolean;

      {elements in the list}
      n,
      {total number of allocated elements}
      a: longint;
      {array(list) of the elements}
      List: array of T;

      private
         function GetElement(i: loopint): T;
         procedure SetElement(i: loopint; element: T);


      public
      Property Items[i : loopint]: T Read GetElement
                                           Write SetElement; Default;

      {allocate specified number of elements (allocates to the multiple of Increment)}
      procedure Allocate(count: loopint);
      {increase allocated number of elements by specified count (allocates to the multiple of Increment)}
      procedure AllocateInc(count: loopint);
      {increase allocated number of elements by specified count (allocates to the multiple of Increment)}
      procedure RequireAllocate(count: loopint);
      {allocates memory to insert count elements at given index, and moves out other elements to free the space}
      procedure InsertRange(index, count: loopint);

      {add a single value to the array}
      function AddTo(var p: T): boolean;
      function Add(p: T): boolean;
      {add two values}
      function AddTo(var p, z: T): boolean;
      function Add(p, z: T): boolean;
      {dispose of the array}
      procedure Dispose();

      {remove an elements from the array, and stack the others down}
      procedure Remove(index: loopint);
      {remove a range of elements}
      procedure RemoveRange(index, count: loopint);

      {find the specified element in the array, or returns -1 if nothing foun d (uses CompareMem)}
      function Find(const what: T): loopint;
      {check if the specified element already exists in the array (uses CompareMem)}
      function Exists(const what: T): boolean;

      {set the size of the array (will set both n and a to the same size)}
      procedure SetSize(size: longint);
      {get a pointer to the last element}
      function GetLast(): pointer;

      {initialize}
      class procedure Initialize(out what: specialize TPreallocatedArrayList<T>; setIncrement: loopint = -1); static;
      {initialize with proper values, without zeroing out the list (if it is contained within something that is zeroed out beforehand)}
      class procedure InitializeValues(out what: specialize TPreallocatedArrayList<T>; setIncrement: loopint = -1); static;
   end;

   TPreallocatedLongintArrayList = specialize TPreallocatedArrayList<longint>;
   TPreallocatedInt64ArrayList = specialize TPreallocatedArrayList<int64>;
   TPreallocatedDWordArrayList = specialize TPreallocatedArrayList<dword>;
   TPreallocatedQWordArrayList = specialize TPreallocatedArrayList<QWord>;

   TPreallocatedStringArrayList = specialize TPreallocatedArrayList<string>;

   { TPreallocatedStringArrayListHelper }

   TPreallocatedStringArrayListHelper = record helper for TPreallocatedStringArrayList
      function FindString(const s: string): loopint;
      function FindLowercase(const s: string): loopint;
   end;

   TPreallocatedPointerArrayList = specialize TPreallocatedArrayList<pointer>;

   TProcedures = specialize TPreallocatedArrayList<TProcedure>;
   TBoolFunctions = specialize TPreallocatedArrayList<TBoolFunction>;

   { TProceduresHelper }

   TProceduresHelper = record helper for TProcedures
      procedure Call();
   end;

   { TBoolFunctionsHelper }

   TBoolFunctionsHelper = record helper for TBoolFunctions
      function Call(stopOnFalse: boolean): loopint;
   end;

   TBitSet16 = type word;
   TBitSet = type longword;
   TBitSet32 = TBitSet;
   TBitSet64 = type uint64;

   { TBitSet16Helper }
   TBitSet16Helper = type helper for TBitSet16
      procedure Prop(p: word);
      procedure Clear(p: word);
      function IsSet(p: word): boolean;

      procedure ClearBit(Index: Byte);
      procedure SetBit(Index: Byte);
      procedure PutBit(Index: Byte; State: Boolean);
      function GetBit(Index: Byte): Boolean;
   end;

   { TBitSetHelper }

   TBitSetHelper = type helper for TBitSet
      procedure Prop(p: longword);
      function Prop(p: longword; enabled: boolean): boolean;
      procedure Clear(p: longword);
      function IsSet(p: longword): boolean;
      function Toggle(p: longword): boolean;

      procedure ClearBit(Index: Byte);
      procedure SetBit(Index: Byte);
      procedure PutBit(Index: Byte; State: Boolean);
      function GetBit(Index: Byte): Boolean;
   end;

   { TBitSet64Helper }

   TBitSet64Helper = type helper for TBitSet64
      procedure Prop(p: uint64);
      function Prop(p: uint64; enabled: boolean): boolean;
      procedure Clear(p: uint64);
      function IsSet(p: uint64): boolean;
      function Toggle(p: uint64): boolean;

      procedure ClearBit(Index: Byte);
      procedure SetBit(Index: Byte);
      procedure PutBit(Index: Byte; State: Boolean);
      function GetBit(Index: Byte): Boolean;
   end;

   { TAppendableStringHelper }

   TAppendableStringHelper = type helper for TAppendableString
      procedure Add(const s: string);
      procedure Add(const s, separator: string);
      procedure AddSpaced(const s: string);
   end;

   { line ending type }
   TLineEndingType = (
      PLATFORM_LINE_ENDINGS,
      UNIX_LINE_ENDINGS,
      WINDOWS_LINE_ENDINGS
   );

CONST
   DefaultPreallocatedArrayAllocationIncrement: loopint = 32;

VAR
   ioE: longint = eNONE;
   GlobalStartTime: TDateTime;

{essentially does nothing}
procedure Pass();

{convert an address to a string}
function addr2str(address: pointer): string;

{fill a buffer quickly with zero's}
procedure Zero(var buf; size: int64);
procedure ZeroOut(out buf; size: int64);
procedure ZeroPtr(buf: pointer; size: int64); inline;
{pretend we zero out so the compiler doesn't complain for data we don't need to initialize}
procedure FakeZeroOut(out {%H-}buf; {%H-}size: int64);

{ EXTENDED MEMORY MANAGEMENT }
function MemAlignment(size: PtrInt; alignment: loopint = -1): ptrint;
{frees the memory associated to mem, if not nil, and sets the pointer to nil}
procedure XFreeMem(var mem: pointer);
{allocate memory for a pointer}
procedure XGetMem(var mem: pointer; size: longint);
{reallocates memory}
procedure XReAllocMem(var mem: pointer; size: longint);
{allocates memory and copies data on the heap}
function XMake(var buf; size: longint): pointer;

{free an object and clear it's pointer}
procedure FreeObject(var obj);

{gets the data type size}
function dtGetSize(dti: longint): longint;
function dtValid(dti: longint): boolean;

function getRunTimeErrorDescription(errorCode: longint): string;
function getRunTimeErrorString(errorCode: longint; includeCode: boolean = true): string;

{ ERROR HANDLING }
{store and return result of IOResult}
function ioerror(): longint;
{ignore an IO error}
procedure ioErrorIgn();

{adds an error procedure}
procedure eAddErrorProc(var newerrorproc: TErrorProc;
                        var olderrorproc: TErrorProc);

{get the name of an error code}
function eGetCodeName(code: longint): string;

{open file for reading}
function FileReset(const fn: string; out f: file): longint;
{open file for reading}
function FileRewrite(const fn: string; out f: file): longint;

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

{return a string for the current call stack}
function DumpCallStack(skip: longint = 0): string;
function DumpExceptionCallStack(e: Exception): string;

{get line ending string}
function GetLineEnding(ln: TLineEndingType): string; inline;
{get line ending type from the given name}
function GetLineEndingTypeFromName(const name: string): TLineEndingType;
{is the line ending name valid}
function ValidLineEndingName(const name: string): boolean;

IMPLEMENTATION

VAR
   oldExitProc: pointer;

procedure Pass();
begin

end;

function addr2str(address: pointer): string;
var
   addressWord: SizeInt absolute address;

begin
   Result := hexStr(addressWord, SizeOf(pointer) * 2);
end;

procedure Zero(var buf; size: int64);
var
   left: int64;

begin
   if(size > 0) then begin
      left := size mod 4;

      if(size > 3) then
         FillDWord(buf, size div 4, 0);

      if(left > 0) then
         FillByte((@buf + size - left)^, left, 0);
   end;
end;

procedure ZeroOut(out buf; size: int64);
begin
   Zero((@buf)^, size);
end;

procedure ZeroPtr(buf: pointer; size: int64);
var
   left: int64;

begin
   if(size > 0) then begin
      left := size mod 4;

      if(size > 3) then
         FillDWord(buf^, size div 4, 0);

      if(left > 0) then
         FillByte((buf + size - left)^, left, 0);
   end;
end;

procedure FakeZeroOut(out buf; size: int64);
begin

end;

{ EXTENDED MEMORY MANAGEMENT }

function MemAlignment(size: PtrInt; alignment: loopint): ptrint;
var
   msize,
   align: ptrint;

begin
   msize := size;

   if(alignment = -1) then
      alignment := dcMemoryBlockAlignment;

   if(alignment > 0) then begin
      align := size mod alignment;

      if(align > 0) then
         inc(msize, alignment - align);
   end;

   Result := msize;
end;

procedure XFreeMem(var mem: pointer);
begin
   if(mem <> nil) then begin
      FreeMem(mem);
      mem := nil;
   end;
end;

procedure XGetMem(var mem: pointer; size: longint);
begin
   if(size > 0) then begin
      {free the memory if occupied}
      XFreeMem(mem);

      {allocate memory}
      GetMem(mem, memAlignment(size));
   end;
end;

procedure XReAllocMem(var mem: pointer; size: longint);
begin
   if(size > 0) then begin
      if(mem <> nil) then
         ReAllocMem(mem, memAlignment(size))
      else
         XGetMem(mem, size);
   end;
end;

function XMake(var buf; size: longint): pointer;
var
   p: pointer = nil;

begin
   {allocate memory}
   XGetMem(p, size);
   if(p <> nil) then
      move(buf, p^, size);

   XMake := p;
end;

procedure FreeObject(var obj);
var
   ref: TObject;

begin
   if(TObject(obj) <> nil) then begin
      ref := TObject(obj);
      TObject(obj) := nil;
      ref.Free();
   end;
end;

{ TPreallocatedStringArrayListHelper }

function TPreallocatedStringArrayListHelper.FindString(const s: string): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i] = s) then
         exit(i);
   end;

   Result := -1;
end;

function TPreallocatedStringArrayListHelper.FindLowercase(const s: string): loopint;
var
   i: loopint;
   l: string;

begin
   if(n > 0) then begin
      l := LowerCase(s);

      for i := 0 to n - 1 do begin
         if(LowerCase(List[i]) = l) then
            exit(i);
      end;
   end;

   Result := -1;
end;

{ TBoolFunctionsHelper }

function TBoolFunctionsHelper.Call(stopOnFalse: boolean): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to n - 1 do begin
      if(not List[i]()) then begin
         inc(Result);

         if(stopOnFalse) then
            break;
      end;
   end;
end;


{ TAppendableStringHelper }

procedure TAppendableStringHelper.Add(const s: string);
begin
   if(Self <> '') then
      Self := Self + LineEnding + s
   else
      Self := s;
end;

procedure TAppendableStringHelper.Add(const s, separator: string);
begin
   if(Self <> '') then
      Self := Self + separator + s
   else
      Self := s;
end;

procedure TAppendableStringHelper.AddSpaced(const s: string);
begin
   if(Self <> '') then
      Self := Self + ' ' + s
   else
      Self := s;
end;

{ TProceduresHelper }

procedure TProceduresHelper.Call();
var
   i: longint;

begin
   for i := 0 to (n - 1) do
      List[i]();
end;

{ TBitSet16Helper }

procedure TBitSet16Helper.Prop(p: word);
begin
   Self := Self or p;
end;

procedure TBitSet16Helper.Clear(p: word);
begin
   Self := Self and p xor Self;
end;

function TBitSet16Helper.IsSet(p: word): boolean;
begin
   Result := (Self and p > 0);
end;

procedure TBitSet16Helper.ClearBit(Index: Byte);
begin
   Self := Self and ((Word(1) shl Index) xor High(Word));
end;

procedure TBitSet16Helper.SetBit(Index: Byte);
begin
   Self := Self or (Word(1) shl Index);
end;

procedure TBitSet16Helper.PutBit(Index: Byte; State: Boolean);
begin
   Self := (Self and ((Word(1) shl Index) xor High(Word))) or (Word(State) shl Index);
end;

function TBitSet16Helper.GetBit(Index: Byte): Boolean;
begin
   Result := ((Self shr Index) and 1) = 1;
end;

{ TBitSetHelper }

procedure TBitSetHelper.Prop(p: longword);
begin
   Self := Self or p;
end;

function TBitSetHelper.Prop(p: longword; enabled: boolean): boolean;
begin
   if(enabled) then
      Self := Self or p
   else
      Self := Self and p xor Self;

   Result := enabled;
end;

procedure TBitSetHelper.Clear(p: longword);
begin
   Self := Self and p xor Self;
end;

function TBitSetHelper.IsSet(p: longword): boolean;
begin
   Result := (Self and p > 0);
end;

function TBitSetHelper.Toggle(p: longword): boolean;
begin
   Self := Self xor p;
   Result := Self and p > 0;
end;

procedure TBitSetHelper.ClearBit(Index: Byte);
begin
   Self := Self and ((DWord(1) shl Index) xor High(DWord));
end;

procedure TBitSetHelper.SetBit(Index: Byte);
begin
   Self := Self or (DWord(1) shl Index);
end;

procedure TBitSetHelper.PutBit(Index: Byte; State: Boolean);
begin
   Self := (Self and ((DWord(1) shl Index) xor High(DWord))) or (DWord(State) shl Index);
end;

function TBitSetHelper.GetBit(Index: Byte): Boolean;
begin
   Result := ((Self shr Index) and 1) = 1;
end;

{ TBitSet64Helper }

procedure TBitSet64Helper.Prop(p: uint64);
begin
   Self := Self or p;
end;

function TBitSet64Helper.Prop(p: uint64; enabled: boolean): boolean;
begin
   if(enabled) then
      Self := Self or p
   else
      Self := Self and p xor Self;

   Result := enabled;
end;

procedure TBitSet64Helper.Clear(p: uint64);
begin
   Self := Self and p xor Self;
end;

function TBitSet64Helper.IsSet(p: uint64): boolean;
begin
   Result := (Self and p > 0);
end;

function TBitSet64Helper.Toggle(p: uint64): boolean;
begin
   Self := Self xor p;
   Result := Self and p > 0;
end;

procedure TBitSet64Helper.ClearBit(Index: Byte);
begin
   Self := Self and ((QWord(1) shl Index) xor High(QWord));
end;

procedure TBitSet64Helper.SetBit(Index: Byte);
begin
   Self := Self or (QWord(1) shl Index);
end;

procedure TBitSet64Helper.PutBit(Index: Byte; State: Boolean);
begin
   Self := (Self and ((QWord(1) shl Index) xor High(QWord))) or (QWord(State) shl Index);
end;

function TBitSet64Helper.GetBit(Index: Byte): Boolean;
begin
   Result := ((Self shr Index) and 1) = 1;
end;

{ TPreallocatedArrayList }

procedure TPreallocatedArrayList.Allocate(count: loopint);
var
   pa: loopint;

begin
   assert(Increment <> 0, 'Increment is zero for preallocated list');
   assert(count <> 0, 'Tried to allocate 0 elements');

   pa := a;
   a := count;

   if(n > a) then
      n := a;

   SetLength(List, a);

   {initialize memory}
   if(InitializeMemory) then begin
      if(pa = 0) then
         ZeroPtr(@List[0], SizeOf(T) * (count))
      else if(pa < a) then
         ZeroPtr(@List[pa], SizeOf(T) * (a - pa))
   end;
end;

procedure TPreallocatedArrayList.AllocateInc(count: loopint);
var
   pa,
   remainder: loopint;

begin
   assert(Increment <> 0, 'Increment is zero for preallocated list');
   assert(count <> 0, 'Tried to allocate 0 elements');

   pa := a;
   inc(a, count);

   if(Increment > 0) then begin
      remainder := a mod Increment;

      if(remainder <> 0) then
         a := a + Increment - remainder;
   end;

   SetLength(List, a);

   assert((a = Length(List)) and (a <> 0), 'Preallocated list has invalid length');

   {initialize memory}
   if(InitializeMemory) then
      ZeroPtr(@List[pa], SizeOf(T) * (a - pa));
end;

procedure TPreallocatedArrayList.RequireAllocate(count: loopint);
begin
   if(count > a) then
      Allocate(count);
end;

procedure TPreallocatedArrayList.InsertRange(index, count: loopint);
var
   i: loopint;

begin
   {allocate more memory if needed}
   if(a < n + count) then
      AllocateInc(n + count - a);

   inc(n, count);

   {move existing items out of way if required}
   if(index < n) then begin
      for i := (n - 1) downto index do begin
         List[i + count] := List[i];
      end;
   end;
end;

function TPreallocatedArrayList.AddTo(var p: T): boolean;
begin
   assert(Increment <> 0, 'Increment is zero for preallocated list');

   inc(n);

   if(a < n) then
      AllocateInc(1);

   List[n - 1] := p;
   Result := true;
end;

function TPreallocatedArrayList.Add(p: T): boolean;
begin
   inc(n);

   if(a < n) then
      AllocateInc(Increment);

   List[n - 1] := p;
   Result := true;
end;

function TPreallocatedArrayList.AddTo(var p, z: T): boolean;
begin
   Result := AddTo(p);

   if(Result) then
      Result := AddTo(z);
end;

function TPreallocatedArrayList.Add(p, z: T): boolean;
begin
   Result := Add(p);

   if(Result) then
      Result := Add(z);
end;

procedure TPreallocatedArrayList.Dispose();
begin
   SetLength(List, 0);
   a := 0;
   n := 0;
end;

procedure TPreallocatedArrayList.Remove(index: loopint);
var
   i: loopint;

begin
   if(index < n) then begin
      {move all items above below}
      if(index < n - 1) then begin
         for i := index to (n - 2) do
            Move(List[i + 1], List[i], SizeOf(T));
      end;

      dec(n);
   end;
end;

procedure TPreallocatedArrayList.RemoveRange(index, count: loopint);
var
   i: loopint;

begin
   {move any items after the removed ones back over the removed items}
   if(count > 0) and (index < n) then begin
      if(index + count >= n) then
         count := n - index;

      for i := (index + count) to (n - 1) do begin
         List[i - count] := List[i];
      end;

      n := n - count;
   end;
end;

function TPreallocatedArrayList.Find(const what: T): loopint;
var
   i: loopint;

begin
   for i := 0 to (n - 1) do begin
      if (CompareMem(@List[i], @what, SizeOf(T))) then
         exit(i);
   end;

   Result := -1;
end;

function TPreallocatedArrayList.Exists(const what: T): boolean;
begin
   Result := Find(what) > -1;
end;

procedure TPreallocatedArrayList.SetSize(size: longint);
begin
   assert(size >= 0, 'Allocation cannot be set to negative value');

   n := size;
   a := size;

   SetLength(List, n);
end;

function TPreallocatedArrayList.GetLast(): pointer;
begin
   if(n > 0) then
      Result := @List[n - 1]
   else
      Result := nil;
end;

class procedure TPreallocatedArrayList.Initialize(out what: specialize TPreallocatedArrayList<T>; setIncrement: loopint);
begin
   if(setIncrement = -1) then
      setIncrement := DefaultPreallocatedArrayAllocationIncrement;

   assert(setIncrement <> 0, 'Invalid value provided for preallocated list increment');

   ZeroPtr(@what, SizeOf(what));

   what.Increment := setIncrement;
   what.InitializeMemory := true;
end;

class procedure TPreallocatedArrayList.InitializeValues(out what: specialize TPreallocatedArrayList<T>; setIncrement: loopint);
begin
   if(setIncrement = -1) then
      setIncrement := DefaultPreallocatedArrayAllocationIncrement;

   assert(setIncrement <> 0, 'Invalid value provided for preallocated list increment');

   what.Increment := setIncrement;
   what.InitializeMemory := True;
end;

function TPreallocatedArrayList.GetElement(i: loopint): T;
begin
   Result := List[i];
end;

procedure TPreallocatedArrayList.SetElement(i: loopint; element: T);
begin
   List[i] := element;
end;

function dtGetSize(dti: longint): longint;
begin
   if(dti > 0) and (dti <= dtcMAX_DTIV) then
      Result := dtcSizes[dti]
   else
      Result := -1;
end;

function dtValid(dti: longint): boolean;
begin
   if(dti > 0) and (dti <= dtcMAX_DTIV) then
      Result := true
   else
      Result := false;
end;

function getRunTimeErrorDescription(errorCode: longint): string;
var
   s: string;

begin
   s := 'unknown';

   case errorCode of
      1:    s := 'Invalid function number';
      2:    s := 'File not found';
      3:    s := 'Path not found';
      4:    s := 'Too many open files';
      5:    s := 'Access denied';
      6:    s := 'Invalid file handle';
      12:   s := 'Invalid file access code';
      15:   s := 'Invalid drive number';
      16:   s := 'Cannot remove current directory';
      17:   s := 'Cannot rename across drives';
      100:  s := 'Disk read error';
      101:  s := 'Disk write error';
      102:  s := 'File not assigned';
      103:  s := 'File not open';
      104:  s := 'File not open for input';
      105:  s := 'File not open for output';
      106:  s := 'Invalid numeric format';
      150:  s := 'Disk is write-protected.';
      151:  s := 'Bad drive request struct length';
      152:  s := 'Drive not ready';
      154:  s := 'CRC error in data';
      156:  s := 'Disk seek error';
      157:  s := 'Unknown media type';
      158:  s := 'Sector not found';
      159:  s := 'Printer out of paper';
      160:  s := 'Device write fault';
      161:  s := 'Device read fault';
      162:  s := 'Hardware failure';
      200:  s := 'Division by zero';
      201:  s := 'Range check error';
      202:  s := 'Stack overflow';
      203:  s := 'Heap overflow';
      204:  s := 'Invalid pointer operation';
      205:  s := 'Floating point overflow';
      206:  s := 'Floating point underflow';
      207:  s := 'Invalid floating point operation';
      210:  s := 'Object not initialized';
      211:  s := 'Call to abstract method';
      212:  s := 'Stream registration error';
      213:  s := 'Collection index out of range';
      214:  s := 'Collection overflow';
      216:  s := 'General protection fault';
      217:  s := 'Unhandled exception occurred';
      227:  s := 'Assertion failed';
      else
            s := 'Unknown';
   end;

   Result := s;
end;

function getRunTimeErrorString(errorCode: longint; includeCode: boolean): string;
var
   codeString: ShortString;

begin
   if(includeCode) then begin
      Str(errorCode, codeString);

      Result := '(' + codeString + ') ' + getRunTimeErrorDescription(errorCode);
   end else
      Result := getRunTimeErrorDescription(errorCode);
end;

procedure RunTimeErrorDisplay(addr: pointer);
var
   s: string;

begin
   {display the error message}
   if(addr <> nil) and (isConsole) then begin
      s := getRunTimeErrorDescription(ErrorCode);
      writeln('Error(', ErrorCode, '): ', s, ' @ ', addr2str(addr));
   end;
end;

procedure RunTimeError();
begin
   {restore the previous error handler}
   ExitProc := oldExitProc;
   RunTimeErrorDisplay(ErrorAddr);
end;

{ GENERAL }

function ioerror(): longint;
var
   err: longint;

begin
   err := IOResult();
   if(err <> 0) then begin
      ioE := err;
      {$IFDEF UNIX}
      fpseterrno(0);
      {$ENDIF}
   end;

   Result := err;
end;

procedure ioErrorIgn();
begin
   if(IOResult() <> 0) then begin
      {$IFDEF UNIX}
      fpseterrno(0);
      {$ENDIF}
   end;
end;

procedure eAddErrorProc(var newerrorproc: TErrorProc;
                        var olderrorproc: TErrorProc);
begin
   {check the validity of arguments passed}
   if(newerrorproc <> nil) and (olderrorproc = nil) then begin
      {add a new error procedure}
      olderrorproc := ErrorProc;
      Errorproc := newerrorproc;
   end else
      ioE := eNIL;
end;

function eGetCodeName(code: longint): string;
var
   number: string;

begin
   case code of
      eNONE:                  Result := esNONE;
      eERR:                   Result := esERR;
      eNO_MEMORY:             Result := esNO_MEMORY;
      eUNABLE:                Result := esUNABLE;
      eEXTERNAL:              Result := esEXTERNAL;
      eUNEXPECTED:            Result := esUNEXPECTED;
      eFAIL:                  Result := esFAIL;
      eIO:                    Result := esIO;
      eWRITE:                 Result := esWRITE;
      eREAD:                  Result := esREAD;
      eHARDWARE_FAILURE:      Result := esHARDWARE_FAILURE;
      eMEMORY:                Result := esMEMORY;
      eCANT_FREE:             Result := esCANT_FREE;
      eNIL:                   Result := esNIL;
      eNOT_NIL:               Result := esNOT_NIL;
      eINVALID_ARG:           Result := esINVALID_ARG;
      eINVALID_ENV:           Result := esINVALID_ENV;
      eINVALID:               Result := esINVALID;
      eCORRUPTED:             Result := esCORRUPTED;
      eUNSUPPORTED:           Result := esUNSUPPORTED;
      eNOT_INITIALIZED:       Result := esNOT_INITIALIZED;
      eINITIALIZED:           Result := esINITIALIZED;
      eINITIALIZATION_FAIL:   Result := esINITIALIZATION_FAIL;
      eDEINITIALIZATION_FAIL: Result := esDEINITIALIZATION_FAIL;
      eEMPTY:                 Result := esEMPTY;
      eFULL:                  Result := esFULL;
      eNOT_OPEN:              Result := esNOT_OPEN;
      eOPEN_FAIL:             Result := esOPEN_FAIL;
      eNOT_CLOSED:            Result := esNOT_CLOSED;
      eCLOSE_FAIL:            Result := esCLOSE_FAIL;
      eNOT_FOUND:             Result := esNOT_FOUND;
      else
         Result := '';
   end;

   str(code, number);
   if(Result <> '') then
      Result := '[' + number + '] ' + Result
   else
      Result := '[' + number + ']';
end;

function FileReset(const fn: string; out f: file): longint;
begin
   Assign(f, fn);
   Reset(f, 1);

   Result := ioerror();
end;

function FileRewrite(const fn: string; out f: file): longint;
begin
   Assign(f, fn);
   Rewrite(f, 1);

   Result := ioerror();
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

function DumpCallStack(skip: longint): string;
var
  i: Longint;
  prevbp: Pointer;
  CallerFrame,
  CallerAddress,
  bp: Pointer;
  Report: string;

const
  MaxDepth = 20;

begin
   Report := '';
   bp := get_caller_frame(get_frame);

   try
      prevbp := bp - 1;

      i := 0;

      while bp > prevbp do begin
         CallerAddress := get_caller_addr(bp);
         CallerFrame := get_caller_frame(bp);

         if (CallerAddress = nil) then
            Break;

         if(skip = 0) or (i >= skip) then
            Report := Report + BackTraceStrFunc(CallerAddress) + LineEnding;

         Inc(i);

         if (i >= MaxDepth) or (CallerFrame = nil) then
            Break;

         prevbp := bp;
         bp := CallerFrame;
     end;
   except
     { prevent endless dump if an exception occured }
   end;

   Result := Report;
end;

function DumpExceptionCallStack(e: Exception): string;
var
   i: loopint;
   Frames: PPointer;
   Report: string;

begin
   report := '';
   if (e <> nil) then begin
      Report := Report + 'Exception ' + E.ClassName + ' ' + E.Message + LineEnding;
   end;

   Report := Report + BackTraceStrFunc(ExceptAddr);
   Frames := ExceptFrames;

   for i := 0 to ExceptFrameCount - 1 do
      Report := Report + LineEnding + BackTraceStrFunc(Frames[I]);

   Result := report;
end;

function GetLineEnding(ln: TLineEndingType): string;
begin
   if(ln = PLATFORM_LINE_ENDINGS) then
      Result := LineEnding
   else if(ln = UNIX_LINE_ENDINGS) then
      Result := UnixLineEnding
   else
      Result := WindowsLineEnding;
end;

function GetLineEndingTypeFromName(const name: string): TLineEndingType;
begin
   if(name = 'crlf') then
      Result := WINDOWS_LINE_ENDINGS
   else if(name = 'lf') then
      Result := UNIX_LINE_ENDINGS
   else
      Result := PLATFORM_LINE_ENDINGS;
end;

function ValidLineEndingName(const name: string): boolean;
var
   i: loopint;

begin
   for i := 0 to high(LineEndingNames) do begin
      if(name = LineEndingNames[i]) then
         exit(true);
   end;

   Result := false;
end;

INITIALIZATION
   GlobalStartTime := Time;

   {store the old exit proc and set the new one}
   oldExitProc := ExitProc;
   ExitProc := @RunTimeError;

END.
