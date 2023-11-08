{
   uStd, standard resources unit (something like system unit)
   Copyright (C) Dejan Boras 2011.
}

{$INCLUDE oxheader.inc}
UNIT uStd;

{$INCLUDE oxutf8.inc}

INTERFACE

   USES
      sysutils
      {$IFDEF UNIX}, BaseUnix{$ENDIF};

TYPE
   TNilEnum = (
      NIL_ENUM
   );

   TNilSet = set of TNilEnum;

CONST
   EmptyShortString: string[1] = '';
   DirSep = DirectorySeparator;

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

   {string pair}
   TStringPair = array[0..1] of StdString;

   { TStringPairHelper }

   TStringPairHelper = type helper for TStringPair
      procedure Assign(const k, v: StdString);
   end;

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

      {remoove all elements}
      procedure RemoveAll();
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

   PSimpleStringList = ^TSimpleStringList;
   TSimpleStringList = specialize TSimpleList<StdString>;
   TSimpleAnsiStringList = specialize TSimpleList<ansistring>;

   TSimplePointerList = specialize TSimpleList<pointer>;

   TProcedures = specialize TSimpleList<TProcedure>;
   TBoolFunctions = specialize TSimpleList<TBoolFunction>;

   PStringPairs = ^TStringPairs;
   TStringPairs = specialize TSimpleList<TStringPair>;

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

{ ERROR HANDLING }
{store and return result of IOResult}
function ioerror(): longint;
{ignore an IO error}
procedure ioErrorIgn();

{open file for reading}
function FileReset(out f: text; const fn: StdString): longint;
{open file for reading}
function FileReset(out f: file; const fn: StdString): longint;
{open file for reading}
function FileRewrite(out f: text; const fn: StdString): longint;
{open file for reading}
function FileRewrite(out f: file; const fn: StdString): longint;

{$IFDEF OX_UTF8_SUPPORT}
function GetUTF8EnvironmentVariable(const v: UTF8String): UTF8String;

procedure UTF8Assign(var f: text; const fn: UTF8String);
procedure UTF8Assign(var f: file; const fn: UTF8String);
function UTF8Lower(const s: UTF8String): UTF8String;
{$ENDIF}

IMPLEMENTATION

{ TStringPairHelper }

procedure TStringPairHelper.Assign(const k, v: StdString);
begin
   Self[0] := k;
   Self[1] := v;
end;

{ TLineEndingTypeHelper }

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
   Result := Self and (1 shl Index) > 0;
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
   Result := Self and (1 shl Index) > 0;
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
   Result := Self and (1 shl Index) > 0;
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

procedure TSimpleList.RemoveAll();
begin
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

{$IFDEF OX_UTF8_SUPPORT}

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

{$ENDIF}

INITIALIZATION
   GlobalStartTime := Time;

END.
