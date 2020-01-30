{
   uStd, standard resources unit(something like system unit)
   Copyright (C) Dejan Boras 2011.

   Started on:    30.01.2011.
}

{$INCLUDE oxheader.inc}
UNIT uStd;

INTERFACE

   USES
      sysutils
      {$IFDEF UNIX}, BaseUnix{$ENDIF};

CONST
   EmptyShortString: string[1] = '';

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

   StdString = UTF8String;

   loopint = SizeInt;

   TBoolFunction = function(): boolean;
   TPointerFunction  = function(): pointer;
   TObjectProcedure = procedure of object;
   TAppendableString = type StdString;
   TErrorString = TAppendableString;

   { arrays }
   TSingleArray = array of single;
   TDoubleArray = array of double;

   TOObject = object
   end;

   POObject = ^TOObject;

   { TSimpleList }

   {helps to maintain a list of elements in an array}
   generic TSimpleList<T> = record
      {step to increment the list size by}
      Increment: loopint;

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
      {allocates memory to insert one element at given index}
      procedure Insert(index: loopint);
      {insert element at the given index}
      procedure Insert(index: loopint; var p: T);
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
      class procedure Initialize(out what: specialize TSimpleList<T>; setIncrement: loopint = -1); static;
      {initialize}
      class procedure InitializeEmpty(out what: specialize TSimpleList<T>); static;
      {initialize with proper values, without zeroing out the list (if it is contained within something that is zeroed out beforehand)}
      class procedure InitializeValues(out what: specialize TSimpleList<T>; setIncrement: loopint = -1); static;
   end;

   TSimpleLongintList = specialize TSimpleList<longint>;
   TSimpleInt64List = specialize TSimpleList<int64>;
   TSimpleDWordList = specialize TSimpleList<dword>;
   TSimpleQWordList = specialize TSimpleList<QWord>;

   TSimpleStringList = specialize TSimpleList<StdString>;
   TSimpleAnsiStringList = specialize TSimpleList<ansistring>;

   { TSimpleStringListHelper }

   TSimpleStringListHelper = record helper for TSimpleStringList
      function FindString(const s: StdString): loopint;
      function FindLowercase(const s: StdString): loopint;
   end;

   { TSimpleAnsiStringListHelper }

   TSimpleAnsiStringListHelper = record helper for TSimpleAnsiStringList
      function FindString(const s: string): loopint;
      function FindLowercase(const s: string): loopint;
   end;

   TSimplePointerList = specialize TSimpleList<pointer>;

   TProcedures = specialize TSimpleList<TProcedure>;
   TBoolFunctions = specialize TSimpleList<TBoolFunction>;

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
      procedure Add(const s: StdString);
      procedure Add(const s, separator: StdString);
      procedure AddSpaced(const s: StdString);
   end;

   { line ending type }

   TLineEndingType = (
      PLATFORM_LINE_ENDINGS,
      UNIX_LINE_ENDINGS,
      WINDOWS_LINE_ENDINGS
   );

   { TLineEndingTypeHelper }

   TLineEndingTypeHelper = type helper for TLineEndingType
      {get line ending string}
      function GetChars(): string;
      {get line ending type from the given name}
      function GetFromName(const name: string): TLineEndingType;
      {get line ending type from the given name}
      function GetName(): string;
      {is the line ending name valid}
      function ValidName(const name: string): boolean;
   end;

CONST
   DefaultSimpleListAllocationIncrement: loopint = 32;

VAR
   ioE: longint = eNONE;
   GlobalStartTime: TDateTime;

{essentially does nothing}
procedure Pass();

{convert an address to a string}
function addr2str(address: pointer): StdString;

{fill a buffer quickly with zero's}
procedure Zero(var buf; size: loopint);
procedure ZeroOut(out buf; size: loopint);
procedure ZeroPtr(buf: pointer; size: loopint); inline;
{pretend we zero out so the compiler doesn't complain for data we don't need to initialize}
procedure FakeZeroOut(out {%H-}buf);

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

function getRunTimeErrorDescription(errorCode: longint): StdString;
function getRunTimeErrorString(errorCode: longint; includeCode: boolean = true): StdString;

{ ERROR HANDLING }
{store and return result of IOResult}
function ioerror(): longint;
{ignore an IO error}
procedure ioErrorIgn();

{adds an error procedure}
procedure eAddErrorProc(var newerrorproc: TErrorProc;
                        var olderrorproc: TErrorProc);

{get the name of an error code}
function GetErrorCodeString(code: longint): StdString;
{get the name of an error code}
function GetErrorCodeName(code: longint): StdString;

{open file for reading}
function FileReset(out f: text; const fn: StdString): longint;
{open file for reading}
function FileReset(out f: file; const fn: StdString): longint;
{open file for reading}
function FileRewrite(out f: text; const fn: StdString): longint;
{open file for reading}
function FileRewrite(out f: file; const fn: StdString): longint;

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
function DumpCallStack(skip: longint = 0): StdString;
function DumpExceptionHeader(e: Exception): StdString;
function DumpExceptionCallStack(e: Exception): StdString;
function DumpExceptionCallStack(exceptAddr: Pointer; frameCount: longint; frames: PPointer): StdString;

function GetUTF8EnvironmentVariable(const v: UTF8String): UTF8String;

procedure UTF8Assign(var f: text; const fn: UTF8String);
procedure UTF8Assign(var f: file; const fn: UTF8String);
function UTF8Lower(const s: UTF8String): UTF8String;

IMPLEMENTATION

VAR
   oldExitProc: pointer;

procedure Pass();
begin

end;

function addr2str(address: pointer): StdString;
var
   addressWord: SizeInt absolute address;

begin
   Result := hexStr(addressWord, SizeOf(pointer) * 2);
end;

procedure Zero(var buf; size: loopint);
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

procedure ZeroOut(out buf; size: loopint);
begin
   Zero((@buf)^, size);
end;

procedure ZeroPtr(buf: pointer; size: loopint);
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

procedure FakeZeroOut(out buf);
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

{ TSimpleStringListHelper }

function TSimpleStringListHelper.FindString(const s: StdString): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i] = s) then
         exit(i);
   end;

   Result := -1;
end;

function TSimpleStringListHelper.FindLowercase(const s: StdString): loopint;
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

{ TSimpleAnsiStringListHelper }

function TSimpleAnsiStringListHelper.FindString(const s: string): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i] = s) then
         exit(i);
   end;

   Result := -1;
end;

function TSimpleAnsiStringListHelper.FindLowercase(const s: string): loopint;
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

procedure TAppendableStringHelper.Add(const s: StdString);
begin
   if(Self <> '') then
      Self := Self + LineEnding + s
   else
      Self := s;
end;

procedure TAppendableStringHelper.Add(const s, separator: StdString);
begin
   if(Self <> '') then
      Self := Self + separator + s
   else
      Self := s;
end;

procedure TAppendableStringHelper.AddSpaced(const s: StdString);
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

{ TSimpleList }

procedure TSimpleList.Allocate(count: loopint);
begin
   assert(Increment <> 0, 'Increment is zero for simple list');
   assert(count <> 0, 'Tried to allocate 0 elements');

   a := count;

   if(n > a) then
      n := a;

   SetLength(List, a);
end;

procedure TSimpleList.AllocateInc(count: loopint);
var
   remainder: loopint;

begin
   assert(Increment <> 0, 'Increment is zero for simple list');
   assert(count <> 0, 'Tried to allocate 0 elements');

   inc(a, count);

   if(Increment > 0) then begin
      remainder := a mod Increment;

      if(remainder <> 0) then
         a := a + Increment - remainder;
   end;

   SetLength(List, a);

   assert((a = Length(List)) and (a <> 0), 'simple list has invalid length');
end;

procedure TSimpleList.RequireAllocate(count: loopint);
begin
   if(count > a) then
      Allocate(count);
end;

procedure TSimpleList.Insert(index: loopint);
var
   i: loopint;

begin
   {allocate more memory if needed}
   if(a < n + 1) then
      AllocateInc(n + 1 - a);

   {move existing items out of way if required}
   if(index < n) then begin
      for i := n downto index do begin
         List[i + 1] := List[i];
      end;
   end;

   inc(n, 1);
end;

procedure TSimpleList.Insert(index: loopint; var p: T);
begin
   Insert(index);

   List[index] := p;
end;

procedure TSimpleList.InsertRange(index, count: loopint);
var
   i: loopint;

begin
   {allocate more memory if needed}
   if(a < n + count) then
      AllocateInc(n + count - a);

   {move existing items out of way if required}
   if(index < n) then begin
      for i := n - 1 downto index do begin
         List[i + count] := List[i];
      end;
   end;

   inc(n, count);
end;

function TSimpleList.AddTo(var p: T): boolean;
begin
   assert(Increment <> 0, 'Increment is zero for simple list');

   inc(n);

   if(a < n) then
      AllocateInc(1);

   List[n - 1] := p;
   Result := true;
end;

function TSimpleList.Add(p: T): boolean;
begin
   inc(n);

   if(a < n) then
      AllocateInc(Increment);

   List[n - 1] := p;
   Result := true;
end;

function TSimpleList.AddTo(var p, z: T): boolean;
begin
   Result := AddTo(p);

   if(Result) then
      Result := AddTo(z);
end;

function TSimpleList.Add(p, z: T): boolean;
begin
   Result := Add(p);

   if(Result) then
      Result := Add(z);
end;

procedure TSimpleList.Dispose();
begin
   SetLength(List, 0);
   a := 0;
   n := 0;
end;

procedure TSimpleList.Remove(index: loopint);
var
   i: loopint;

begin
   if(index < n) then begin
      {move all items above below}
      if(index < n - 1) then begin
         for i := index to (n - 2) do
            List[i] := List[i + 1];
      end;

      dec(n);
   end;
end;

procedure TSimpleList.RemoveRange(index, count: loopint);
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

function TSimpleList.Find(const what: T): loopint;
var
   i: loopint;

begin
   for i := 0 to (n - 1) do begin
      if (CompareMem(@List[i], @what, SizeOf(T))) then
         exit(i);
   end;

   Result := -1;
end;

function TSimpleList.Exists(const what: T): boolean;
begin
   Result := Find(what) > -1;
end;

procedure TSimpleList.SetSize(size: longint);
begin
   assert(size >= 0, 'Allocation cannot be set to negative value');

   n := size;
   a := size;

   SetLength(List, n);
end;

function TSimpleList.GetLast(): pointer;
begin
   if(n > 0) then
      Result := @List[n - 1]
   else
      Result := nil;
end;

class procedure TSimpleList.Initialize(out what: specialize TSimpleList<T>; setIncrement: loopint);
begin
   if(setIncrement = -1) then
      setIncrement := DefaultSimpleListAllocationIncrement;

   assert(setIncrement > 0, 'Invalid value provided for simple list increment');

   ZeroPtr(@what, SizeOf(what));

   what.Increment := setIncrement;
end;

class procedure TSimpleList.InitializeEmpty(out what: specialize TSimpleList<T>);
begin
   ZeroPtr(@what, SizeOf(what));

   what.Increment :=  DefaultSimpleListAllocationIncrement;
end;

class procedure TSimpleList.InitializeValues(out what: specialize TSimpleList<T>; setIncrement: loopint);
begin
   if(setIncrement = -1) then
      setIncrement := DefaultSimpleListAllocationIncrement;

   assert(setIncrement > 0, 'Invalid value provided for simple list increment');

   what.Increment := setIncrement;
end;

function TSimpleList.GetElement(i: loopint): T;
begin
   Result := List[i];
end;

procedure TSimpleList.SetElement(i: loopint; element: T);
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

function getRunTimeErrorDescription(errorCode: longint): StdString;
var
   s: StdString;

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

function getRunTimeErrorString(errorCode: longint; includeCode: boolean): StdString;
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
   s: StdString;

begin
   {display the error message}
   if(addr <> nil) and (isConsole) then begin
      writeln(stdout, '┻━┻ ︵ ╯(°□° ╯)');

      s := getRunTimeErrorDescription(ErrorCode);

      writeln(stdout, 'Error (', ErrorCode, '): ', s, ' @ $', addr2str(addr));
   end;
end;

procedure RunTimeError();
begin
   {restore the previous error handler}
   ExitProc := oldExitProc;

   RunTimeErrorDisplay(ErrorAddr);
end;

procedure UnhandledException(obj: TObject; addr: Pointer; {%H-}frameCount: Longint; {%H-}frames: PPointer);
begin
   writeln(stdout, '(╯°□°)╯︵ ┻━┻');
   writeln(stdout, 'Unhandled exception @ $',  addr2str(addr), ' :');

   if(obj is Exception) then begin
      writeln(stdout, DumpExceptionCallStack(Exception(obj)));
   end else begin
      writeln(stdout, 'Exception object ', obj.ClassName, ' is not of class Exception.');
      writeln(stdout, DumpExceptionCallStack(addr, frameCount, frames));
   end;

   writeln(stdout,'');
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

function GetErrorCodeString(code: longint): StdString;
var
   number: StdString;

begin
   Result := GetErrorCodeName(code);
   str(code, number);

   if(Result <> '') then
      Result := '[' + number + '] ' + Result
   else
      Result := '[' + number + ']';
end;

function GetErrorCodeName(code: longint): StdString;
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
end;

function FileReset(out f: text; const fn: StdString): longint;
begin
   Assign(f, fn);
   Reset(f);

   Result := ioerror();
end;

function FileReset(out f: file; const fn: StdString): longint;
begin
   Assign(f, fn);
   Reset(f, 1);

   Result := ioerror();
end;

function FileRewrite(out f: text; const fn: StdString): longint;
begin
   Assign(f, fn);
   Rewrite(f);

   Result := ioerror();
end;

function FileRewrite(out f: file; const fn: StdString): longint;
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

function DumpCallStack(skip: longint): StdString;
var
   i: Longint;
   prevbp: Pointer;
   CallerFrame,
   CallerAddress,
   bp: Pointer;
   Report: StdString;

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

function DumpExceptionHeader(e: Exception): StdString;
begin
   if(e <> nil) then
      Result := 'Exception ' + E.ClassName + ' ' + E.Message + ' (unit: ' + e.UnitName + ')' + LineEnding
   else
      Result := '';
end;

function DumpExceptionCallStack(e: Exception): StdString;
begin
   Result := DumpExceptionHeader(e);

   Result := Result + DumpExceptionCallStack(ExceptAddr, ExceptFrameCount, ExceptFrames);
end;

function DumpExceptionCallStack(exceptAddr: Pointer; frameCount: longint; frames: PPointer): StdString;
var
   i: loopint;

begin
   Result := BackTraceStrFunc(exceptAddr);

   for i := 0 to frameCount - 1 do
      Result := Result + LineEnding + BackTraceStrFunc(frames[I]);
end;

function GetUTF8EnvironmentVariable(const v: UTF8String): UTF8String;
begin
   {$IFDEF WINDOWS}
   Result := UTF8Encode(GetEnvironmentVariable(UnicodeString(v)));
   {$ELSE}
   Result := GetEnvironmentVariable(v);
   {$ENDIF}
end;

procedure UTF8Assign(var f: text; const fn: UTF8String);
begin
   Assign(f, UTF8Decode(fn));
end;

procedure UTF8Assign(var f: file; const fn: UTF8String);
begin
   Assign(f, UTF8Decode(fn));
end;

function UTF8Lower(const s: UTF8String): UTF8String;
begin
   Result := UTF8Encode(UnicodeLowerCase(UTF8Decode(s)));
end;

function TLineEndingTypeHelper.GetChars(): string;
begin
   if(Self = PLATFORM_LINE_ENDINGS) then
      Result := LineEnding
   else if(Self = UNIX_LINE_ENDINGS) then
      Result := UnixLineEnding
   else
      Result := WindowsLineEnding;
end;

function TLineEndingTypeHelper.GetFromName(const name: string): TLineEndingType;
begin
   if(name = 'crlf') or (name = 'windows') then
      Result := WINDOWS_LINE_ENDINGS
   else if(name = 'lf') or (name = 'unix') then
      Result := UNIX_LINE_ENDINGS
   else
      Result := PLATFORM_LINE_ENDINGS;
end;

function TLineEndingTypeHelper.GetName(): string;
begin
   if(Self = WINDOWS_LINE_ENDINGS) then
      Result := 'crlf'
   else if(Self = UNIX_LINE_ENDINGS) then
      Result := 'lf'
   else
      Result := '';
end;

function TLineEndingTypeHelper.ValidName(const name: string): boolean;
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

   ExceptProc := @UnhandledException;

END.
