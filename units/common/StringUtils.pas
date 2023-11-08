{
   StringUtils, string manipulation utilities
   Copyright (C) 2010. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT StringUtils;

{$INCLUDE oxtypesdefines.inc}

INTERFACE

   USES
      uStd, sysutils;

CONST
   strWhitespace = [' ', #9];
   STRING_SIMPLE_BUFFER_SIZE = 64 * 1024;

TYPE
   TShortStringArray = array of shortstring;
   TpShortStringArray = array of pshortstring;
   TpCharDynArray = array of pchar;
   TAnsiStringArray = array of ansistring;
   TStringArray = array of StdString;

   { TStringArrayHelper }

   TStringArrayHelper = type helper for TStringArray
      function GetSingleString(separator: StdString): StdString;
      function GetSingleString(): StdString;
      function GetAnsiStrings(): TAnsiStringArray;
   end;

   { TSimpleStringListHelper }

   TSimpleStringListHelper = record helper for TSimpleStringList
      function FindString(const s: StdString): loopint;
      function FindLowercase(const s: StdString): loopint;
      function GetSingleString(separator: StdString): StdString;
      function GetSingleString(): StdString;
      function GetAnsiStrings(): TAnsiStringArray;
   end;

   { TSimpleAnsiStringListHelper }

   TSimpleAnsiStringListHelper = record helper for TSimpleAnsiStringList
      function FindString(const s: string): loopint;
      function FindLowercase(const s: string): loopint;
   end;


   { TPackedStrings }

   TPackedStrings = record
      {number of strings in the structure}
      n,
      {size of the index table}
      IndexTableSize: loopint;
      {pointer to the string content}
      Content,
      {memory structure holding the index table and shortstrings}
      p: Pointer;

      {initialize this structure}
      class procedure Init(out ps: TPackedStrings); static;

      {allocate for given number of strings and content size(excluding shortstring length byte)}
      procedure Allocate(count: loopint; stringContentSize: loopint);

      {get a pointer to the specified string from the structure}
      function GetStringLength(index: loopint): loopint;
      {get a pointer to the specified string from the structure}
      function GetString(index: loopint): PShortString;
      {store the string}
      procedure Store(var s: shortstring; index: loopint);
   end;

   { TSimpleAnsiStringBuffer }

   TSimpleAnsiStringBuffer = record
      size: longint;
      buffer: array[0..STRING_SIMPLE_BUFFER_SIZE - 1] of char;

      procedure Reset();

      procedure Write(const s: AnsiString);
      function Get(): AnsiString;

      class procedure Init(out buf: TSimpleAnsiStringBuffer); static;
   end;

   { TExtendedStringHelper }

   TExtendedStringHelper = type helper(TStringHelper) for string
      {check if the string has line ending characters in it}
      function IsMultiLine(): boolean;
   end;

   { TStdStringStringHelper }

   TStdStringStringHelper = type helper for StdString
      {check if the string has line ending characters in it}
      function IsMultiLine(): boolean;
   end;

{NUMERICAL VALUE TO STRING}
{make a string out of a value}

function sf(value: byte): string; inline;
function sf(value: word): string; inline;
function sf(value: longword): string; inline;
function sf(value: uint64): string; inline;
function sf(value: shortint): string; inline;
function sf(value: smallint): string; inline;
function sf(value: longint): string; inline;
function sf(value: int64): string; inline;
function sf(value: single; dec: longint): string; inline;
function sf(value: single): string; inline;
function sf(value: double; dec: longint): string; inline;
function sf(value: double): string; inline;
{$IFNDEF EXCLUDE_EXTENDED}
function sf(value: extended; dec: longint): string; inline;
function sf(value: extended): string; inline;
function sf(value: comp; dec: longint): string; inline;
function sf(value: comp): string; inline;
{$ENDIF}

{$IFNDEF EXCLUDE_CURRENCY}
function sf(value: currency; dec: longint): string; inline;
function sf(value: currency): string; inline;
{$ENDIF}

function sf(value: boolean): string; inline;
function sf(value: pointer): string; inline;

{WHITESPACE STRIPPING}
procedure StripLeadingWhitespace(var st: string);
procedure StripTrailingWhitespace(var st: string);
procedure StripWhitespace(var st: string);
function IsWhitespace(const st: string): boolean;
procedure StripEndLine(var st: string);

{completely remove white space from the string}
procedure EliminateWhiteSpace(var st: string);
{remove a character from the string}
procedure RemoveChar(var st: string; c: char);

{find a substring in a string starting from a position}
function StringPos(const st, sub: string; fromPos: Integer = 1): loopint;
{count occurences of substring in a string}
function StringCount(const st, sub: string): loopint;
{find count of specified character in a string}
function CharacterCount(const s: string; const c: char): loopint;
{find a substring in a string starting from a position}
function StringPosInsensitive(const st, sub: string; const fromPos: Integer = 1): loopint;
{count occurences of substring in a string}
function StringCountInsensitive(const st, sub: string): loopint;

{FILE NAME ROUTINES}
{extract the file name from a string}
function ExtractFileName(const st: string): string;
{extracts the file name without the extension}
function ExtractFileNameNoExt(const st: string): string;
{extracts everything without the extension}
function ExtractAllNoExt(const st: string): string;
{extract the file directory from a string}
function ExtractFileDir(const st: string): string;
{extract the file extension from a string}
function ExtractFileExt(const st: string): string;
{extract file extension without a dot}
function ExtractFileExtNoDot(const st: string): string;
{extract multiple extensions from a string (e.g. )}
function ExtractFileExts(const st: string; level: longint): string;
{extract the file path from a string}
function ExtractFilePath(const st: string): string;
{extract the file drive from a string, good only for Win32}
function ExtractFileDrive(const st: string): string;
{replace directory separators with the one used on the current platform}
procedure ReplaceDirSeparators(var st: string);
{get parent directory in a given path}
function GetParentDirectory(const st: string): string;
{include a trailing path delimiter only if specified path is non empty}
function IncludeTrailingPathDelimiterNonEmpty(const st: string): string;

{ SUB STRINGS }

{returns a sub-string from the string st starting at index position idx to the end}
function StringFrom(const st: string; idx: longint): string;
{returns a sub-string from the string st starting at index 1 to the position idx}
function StringTo(const st: string; idx: longint): string;

{copy until white space and delete from string}
function CopyTo(const s: string): string;
{copy until the specified character is found and delete from string}
function CopyTo(const s: string; c: char): string;

{copy until given chars and delete from string}
function CopyToDel(var s: string; const chars: array of char): string;
{copy until white space and delete from string}
function CopyToDel(var s: string): string;
{copy until the specified character is found and delete from string}
function CopyToDel(var s: string; c: char): string;

{copy everything after the first whitespace}
function CopyAfter(const s: string): string;
{copy everything after the first occurence of the specified character}
function CopyAfter(const s: string; c: char): string;

{copy everything after the first whitespace, and delete it from string (including whitespace)}
function CopyAfterDel(var s: string): string;
{copy everything after the first occurence of the specified character, and delete it from string (including the character)}
function CopyAfterDel(var s: string; c: char): string;

{add the specified leading character to make the string have length n}
procedure AddLeadingPadding(var s: shortstring; c: char; n: longint);
procedure AddLeadingPadding(var s: string; c: char; n: longint);
{add the specified trailing character to make the string have length n}
procedure AddTrailingPadding(var s: shortstring; c: char; n: longint);
procedure AddTrailingPadding(var s: string; c: char; n: longint);

{ SHORTSTRINGS }
{creates a pshortstring from a regular shortstring or a pchar}
function MakepShortString(const s: string): pShortString;
function MakepShortString(pcs: pChar): pShortString;

{'converts' a pchar to a shortstring}
function PCharToShortString(pcs: pChar): ShortString;

{ EXPLODING }
function strExplode(const s: ansistring; delimiter: char): TAnsiStringArray;
procedure strExplode(const s: ansistring; delimiter: char; var a: array of ShortString; maxStrings: loopint = 0);

{creates a string from bytes}
procedure StringFromBytes(out s: ansistring; size: loopint; const bytes);

{get key value from a string}
function GetKeyValue(const s: string; out key, value: string; const separator: char = '='): boolean;

{$IFDEF OX_UTF8_SUPPORT}
procedure StripLeadingWhitespace(var st: StdString);
procedure StripTrailingWhitespace(var st: StdString);
procedure StripWhitespace(var st: StdString);
function IsWhitespace(const st: StdString): boolean;
procedure StripEndLine(var st: StdString);
{completely remove white space from the string}
procedure EliminateWhiteSpace(var st: StdString);

{copy until given chars and delete from string}
function CopyToDel(var s: StdString; const chars: array of char): StdString;
{copy until white space and delete from string}
function CopyToDel(var s: StdString): StdString;
{copy until the specified character is found and delete from string}
function CopyToDel(var s: StdString; c: char): StdString;

{copy everything after the first whitespace, and delete it from string (including whitespace)}
function CopyAfterDel(var s: StdString): StdString;
{copy everything after the first occurence of the specified character, and delete it from string (including the character)}
function CopyAfterDel(var s: StdString; c: char): StdString;

{extract the file name from a string}
function ExtractFileName(const st: StdString): StdString;
{extracts the file name without the extension}
function ExtractFileNameNoExt(const st: StdString): StdString;
{extracts everything without the extension}
function ExtractAllNoExt(const st: StdString): StdString;
{extract the file directory from a string}
function ExtractFileDir(const st: StdString): StdString;
{extract the file extension from a string}
function ExtractFileExt(const st: StdString): StdString;
{extract file extension without a dot}
function ExtractFileExtNoDot(const st: StdString): StdString;
{extract multiple extensions from a string (e.g. )}
function ExtractFileExts(const st: StdString; level: longint): StdString;
{extract the file path from a string}
function ExtractFilePath(const st: StdString): StdString;
{extract the file drive from a string, good only for Win32}
function ExtractFileDrive(const st: StdString): StdString;
{replace directory separators with the one used on the current platform}
procedure ReplaceDirSeparators(var st: StdString);
{replace directory separators with the one used on the current platform}
function ReplaceDirSeparatorsf(const st: StdString): StdString;
{get parent directory in a given path}
function GetParentDirectory(const st: StdString): StdString;
{include a trailing path delimiter only if specified path is non empty}
function IncludeTrailingPathDelimiterNonEmpty(const st: StdString): StdString;

function strExplode(const s: StdString; delimiter: char): TStringArray;
procedure strExplode(const s: StdString; delimiter: char; var a: array of ShortString; maxStrings: loopint = 0);
{creates a string from bytes}
procedure StringFromBytes(out s: StdString; size: loopint; const bytes);
{get key value from a string}
function GetKeyValue(const s: StdString; out key, value: StdString; const separator: char = '='): boolean;
{$ENDIF}

IMPLEMENTATION

CONST
   DirectorySeparators = ['/', '\'];

{NUMERICAL VALUE TO STRING}

function sf(value: byte): string; inline;
begin
   str(value, Result);
end;

function sf(value: word): string; inline;
begin
   str(value, Result);
end;

function sf(value: longword): string; inline;
begin
   str(value, Result);
end;

function sf(value: uint64): string; inline;
begin
   str(value, Result);
end;

function sf(value: shortint): string; inline;
begin
   str(value, Result);
end;

function sf(value: smallint): string; inline;
begin
   str(value, Result);
end;

function sf(value: longint): string; inline;
begin
   str(value, Result);
end;

function sf(value: int64): string; inline;
begin
   str(value, Result);
end;

function sf(value: single; dec: longint): string; inline;
begin
   str(value : 0 : dec, Result);
end;

function sf(value: single): string;
begin
   str(value, Result);
end;

function sf(value: double; dec: longint): string; inline;
begin
   str(value : 0 : dec, Result);
end;

function sf(value: double): string;
begin
   str(value, Result);
end;

{$IFNDEF EXCLUDE_EXTENDED}

function sf(value: extended; dec: longint): string;
begin
   str(value : 0 : dec, Result);
end;

function sf(value: extended): string;
begin
   str(value, Result);
end;

function sf(value: comp; dec: longint): string;
begin
   str(value : 0 : dec, Result);
end;

function sf(value: comp): string;
begin
   str(value, Result);
end;

{$ENDIF}

{$IFNDEF EXCLUDE_CURRENCY}

function sf(value: currency; dec: longint): string;
begin
   str(value : 0 : dec, Result);
end;

function sf(value: currency): string;
begin
   str(value, Result);
end;

{$ENDIF}

function sf(value: boolean): string; inline;
begin
   if(value) then
      Result := 'true'
   else
      Result := 'false';
end;

function sf(value: pointer): string;
begin
   Result := addr2str(value);
end;

{WHITESPACE STRIPPING}
procedure StripLeadingWhitespace(var st: string);
var
   i,
   l,
   strippos: longint;

begin
   l := Length(st);
   if(l > 0) then begin
      {strip leading white space}
      {find white space}
      strippos := 0;
      for i := 1 to l do begin
         if(st[i] in strWhitespace) then
            inc(strippos)
         else
            break;
      end;

      {delete white space from the string}
      if(strippos <> 0) then
         delete(st, 1, strippos);
   end;
end;

procedure StripTrailingWhitespace(var st: string);
var
   i,
   l,
   strippos: longint;

begin
   l := length(st);
   if(l > 0) then begin
      {strip trailing white space}
      {find white space}
      strippos := 0;
      for i := l downto 1 do begin
         if(st[i] in strWhitespace) then
            inc(strippos)
         else
            break;
      end;

      {delete white space from the string}
      if(strippos > 0) then
         delete(st, l-(strippos-1), strippos);
   end;
end;

procedure StripWhitespace(var st: string);
begin
   StripLeadingWhitespace(st);
   StripTrailingWhitespace(st);
end;

function IsWhitespace(const st: string): boolean;
var
   len, i: longint;

begin
   len := Length(st);
   if(len > 0) then
      for i := 1 to len do begin
         if not (st[i] in strWhitespace) then
            exit(false);
      end;

   Result := true;
end;

procedure StripEndLine(var st: string);
var
   len: loopint;

begin
   len := Length(st);

   {check if we need to strip any characters off the end}
   if(st[len] = #13) then
      len := len - 1
   else if(st[len] = #10) then begin
      if(len > 1) then begin
         if(st[len - 1] = #13) then
            len := len - 2
         else
            len := len - 1;
      end else
         len := len - 1;
   end;

   {correct to new length}
   if(len <> Length(st)) then
      SetLength(st, len);
end;

procedure EliminateWhiteSpace(var st: string);
var
   i,
   l,
   newlen,
   count: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      newlen := l;
      count := 0;

      for i := 1 to l do begin
         if(st[i] in strWhiteSpace) then
            dec(newlen)
         else begin
            inc(count);
            st[count] := st[i]
         end;
      end;

      SetLength(st, newlen);
   end;
end;

procedure RemoveChar(var st: string; c: char);
var
   i,
   l,
   newlen,
   count: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      newlen := l;
      count := 0;

      for i := 1 to l do begin
         if(st[i] = c) then
            dec(newlen)
         else begin
            inc(count);
            st[count] := st[i]
         end;
      end;

      SetLength(st, newlen);
   end;
end;

{ _FindStringBoyer:
  Boyer-Moore search algorith using regular String instead of AnsiSTring, and no ASM.
  Credited to Dorin Duminica.

  http://stackoverflow.com/questions/3310865/is-there-a-boyer-moore-string-search-and-fast-search-and-replace-function-and-fas
}
function StringPos(const st, sub: string; fromPos: Integer = 1): loopint;

   function __SameChar(StringIndex, PatternIndex: Integer): Boolean; inline;
   begin
      Result := (st[StringIndex] = sub[PatternIndex])
   end;

VAR
   SkipTable: array [Char] of Integer;
   LengthPattern: Integer;
   LengthString: Integer;
   Index: Integer;
   kIndex: Integer;
   LastMarker: Integer;
   Large: Integer;
   chPattern: Char;

begin
   if (fromPos < 1) then
      fromPos := 1;

   LengthPattern := Length(sub);
   LengthString := Length(st);

   for chPattern := Low(Char) to High(Char) do
      SkipTable[chPattern] := LengthPattern;

   for Index := 1 to LengthPattern - 1 do
      SkipTable[sub[Index]] := LengthPattern - Index;

   Large := LengthPattern + LengthString + 1;
   LastMarker := SkipTable[sub[LengthPattern]];
   SkipTable[sub[LengthPattern]] := Large;
   Index := fromPos + LengthPattern - 1;
   Result := 0;

   while Index <= LengthString do begin
      repeat
         Index := Index + SkipTable[st[Index]];
      until Index > LengthString;

      if Index <= Large then
         Break
      else
         Index := Index - Large;

      kIndex := 1;
      while (kIndex < LengthPattern) and __SameChar(Index - kIndex, LengthPattern - kIndex) do
         Inc(kIndex);

      if kIndex = LengthPattern then begin
         {found}
         exit(Index - kIndex + 1);
      end else begin
         if __SameChar(Index, LengthPattern) then
            Index := Index + LastMarker
         else
            Index := Index + SkipTable[st[Index]];
      end;
   end;
end;

{ Written by Warren, using the above code as a starter, we calculate the SkipTable once, and then count the number of
   instances of a substring inside the main string, at a much faster rate than we could have done otherwise. Another
   thing that would be great is to have a function that returns an array of find-locations, which would be way faster
   to do than repeatedly calling Pos.

   http://stackoverflow.com/questions/3310865/is-there-a-boyer-moore-string-search-and-fast-search-and-replace-function-and-fas
}
function StringCount(const st, sub: string): loopint;
var
   foundPos: Integer;
   fromPos: Integer;
   Limit: Integer;
   SkipTable: array [Char] of Integer;
   LengthPattern: Integer;
   LengthString: Integer;
   Index: Integer;
   kIndex: Integer;
   LastMarker: Integer;
   Large: Integer;
   chPattern: Char;

   function __SameChar(StringIndex, PatternIndex: Integer): Boolean; inline;
   begin
      Result := (st[StringIndex] = sub[PatternIndex])
   end;

begin
   Result := 0;
   foundPos := 1;
   fromPos := 1;
   Limit := Length(st);
   Index := 0;
   LengthPattern := Length(sub);
   LengthString := Length(st);

   for chPattern := Low(Char) to High(Char) do
      SkipTable[chPattern] := LengthPattern;

   for Index := 1 to LengthPattern -1 do
      SkipTable[sub[Index]] := LengthPattern - Index;

   Large := LengthPattern + LengthString + 1;
   LastMarker := SkipTable[sub[LengthPattern]];
   SkipTable[sub[LengthPattern]] := Large;

   while (foundPos >= 1) and (fromPos < Limit) and (Index<Limit) do begin
      Index := fromPos + LengthPattern -1;

      if Index > Limit then
         break;

      kIndex := 0;

      while Index <= LengthString do begin
         repeat
            Index := Index + SkipTable[st[Index]];
         until Index > LengthString;

         if Index <= Large then
            Break
         else
            Index := Index - Large;

         kIndex := 1;

         while (kIndex < LengthPattern) and __SameChar(Index - kIndex, LengthPattern - kIndex) do
            Inc(kIndex);

         if kIndex = LengthPattern then begin
            {found}
            //Result := Index - kIndex + 1;
            Index := Index + LengthPattern;
            fromPos := Index;
            Inc(Result);
            break;
         end else begin
            if __SameChar(Index, LengthPattern) then
               Index := Index + LastMarker
            else
               Index := Index + SkipTable[st[Index]];
         end;
      end;
  end;
end;

function CharacterCount(const s: string; const c: char): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 1 to Length(s) do
      if s[i] = c then
         inc(Result);
end;

function StringPosInsensitive(const st, sub: string; const fromPos: Integer = 1): loopint;

   function __SameChar(StringIndex, PatternIndex: Integer): Boolean; inline;
   begin
      Result := (CompareText(st[StringIndex], sub[PatternIndex]) = 0);
   end;

VAR
   SkipTable: array [Char] of Integer;
   LengthPattern: Integer;
   LengthString: Integer;
   Index: Integer;
   kIndex: Integer;
   LastMarker: Integer;
   Large: Integer;
   chPattern: Char;

begin
   if fromPos < 1 then
      Result := -1;

   LengthPattern := Length(sub);
   LengthString := Length(st);

   for chPattern := Low(Char) to High(Char) do
      SkipTable[chPattern] := LengthPattern;

   for Index := 1 to LengthPattern -1 do
      SkipTable[sub[Index]] := LengthPattern - Index;

   Large := LengthPattern + LengthString + 1;
   LastMarker := SkipTable[sub[LengthPattern]];
   SkipTable[sub[LengthPattern]] := Large;
   Index := fromPos + LengthPattern -1;
   Result := 0;

   while Index <= LengthString do begin
      repeat
         Index := Index + SkipTable[st[Index]];
      until Index > LengthString;

      if Index <= Large then
         Break
      else
         Index := Index - Large;

      kIndex := 1;
      while (kIndex < LengthPattern) and __SameChar(Index - kIndex, LengthPattern - kIndex) do
         Inc(kIndex);

      if kIndex = LengthPattern then begin
         {found}
         exit(Index - kIndex + 1);
      end else begin
         if __SameChar(Index, LengthPattern) then
            Index := Index + LastMarker
         else
            Index := Index + SkipTable[st[Index]];
      end;
   end;
end;

{ Written by Warren, using the above code as a starter, we calculate the SkipTable once, and then count the number of
   instances of a substring inside the main string, at a much faster rate than we could have done otherwise. Another
   thing that would be great is to have a function that returns an array of find-locations, which would be way faster
   to do than repeatedly calling Pos.

   http://stackoverflow.com/questions/3310865/is-there-a-boyer-moore-string-search-and-fast-search-and-replace-function-and-fas
}
function StringCountInsensitive(const st, sub: string): loopint;
var
   foundPos: Integer;
   fromPos: Integer;
   Limit: Integer;
   SkipTable: array [Char] of Integer;
   LengthPattern: Integer;
   LengthString: Integer;
   Index: Integer;
   kIndex: Integer;
   LastMarker: Integer;
   Large: Integer;
   chPattern: Char;

   function __SameChar(StringIndex, PatternIndex: Integer): Boolean; inline;
   begin
      Result := (CompareText(st[StringIndex], sub[PatternIndex]) = 0);
   end;

begin
   Result := 0;
   foundPos := 1;
   fromPos := 1;
   Limit := Length(st);
   Index := 0;
   LengthPattern := Length(sub);
   LengthString := Length(st);

   for chPattern := Low(Char) to High(Char) do
      SkipTable[chPattern] := LengthPattern;

   for Index := 1 to LengthPattern -1 do
      SkipTable[sub[Index]] := LengthPattern - Index;

   Large := LengthPattern + LengthString + 1;
   LastMarker := SkipTable[sub[LengthPattern]];
   SkipTable[sub[LengthPattern]] := Large;

   while (foundPos >= 1) and (fromPos < Limit) and (Index<Limit) do begin
      Index := fromPos + LengthPattern -1;

      if Index > Limit then
         break;

      kIndex := 0;

      while Index <= LengthString do begin
         repeat
            Index := Index + SkipTable[st[Index]];
         until Index > LengthString;

         if Index <= Large then
            Break
         else
            Index := Index - Large;

         kIndex := 1;

         while (kIndex < LengthPattern) and __SameChar(Index - kIndex, LengthPattern - kIndex) do
            Inc(kIndex);

         if kIndex = LengthPattern then begin
            {found}
            //Result := Index - kIndex + 1;
            Index := Index + LengthPattern;
            fromPos := Index;
            Inc(Result);
            break;
         end else begin
            if __SameChar(Index, LengthPattern) then
               Index := Index + LastMarker
            else
               Index := Index + SkipTable[st[Index]];
         end;
      end;
  end;
end;

{FILE NAME ROUTINES}
function ExtractFileName(const st: string): string;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;

      while (i > 0) and (not(st[i] in DirectorySeparators)) do
         dec(i);

      if(i + 1 < l) then
         Result := copy(st, i + 1 , 255)
      else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileNameNoExt(const st: string): string;
var
   i,
   l,
   e,
   dotpos: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;

      while(i > 0) and (not (st[i] in DirectorySeparators)) do
         dec(i);

      if(i <= l) then begin
         {now that we've found where the beginning of the filename is,
         we need to find where the end is(without the extension)}
         dotpos := StringPos(st, ExtensionSeparator, i);

         if(dotpos > 0) then
            e := dotpos
         else
            e := l;

         {now just copy the filename}
         Result := copy(st, i + 1, e - i - 1);
      end else
         Result := st;
   end else
      Result := st;
end;

function ExtractAllNoExt(const st: string): string;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l <> 0) then begin
      i := l;

      {go backwards through string until an extension separator is encountered}
      while(i > 1) and (st[i] <> ExtensionSeparator) do begin
         {quit with original if directory separator encountered before extension separator}
         if(st[i] in DirectorySeparators) then
            exit(st);

         dec(i);
      end;

      if(i > 1) then
         Result := copy(st, 1, i - 1)
      else
        Result := st;
   end else
      Result := '';
end;

function ExtractFileDir(const st: string): string;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;

      while (i >= 1) and (not (st[i] in DirectorySeparators)) do
         dec(i);

      if(i >= 2) then
         Result := copy(st, 1, i - 1)
      else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileExt(const st: string): string;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;
      while (i >= 1) and (st[i] <> ExtensionSeparator) do
         dec(i);

      if(i > 0) then begin
         {extract the extension and return it}
         Result := copy(st, i, 255);
      end else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileExtNoDot(const st: string): string;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;
      while (i >= 1) and (st[i] <> ExtensionSeparator) do
         dec(i);

      if(i > 0) then begin
         {extract the extension and return it}
         Result := copy(st, i + 1, 255);
      end else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileExts(const st: string; level: longint): string;
var
   i,
   l,
   currentLevel: longint;

begin
   l := Length(st);

   if(l > 0) and (level > 0) then begin
      i := l;
      currentLevel := 0;

      while (i > 1) and (level <> currentLevel) do begin
         dec(i);

         if(st[i] = ExtensionSeparator) then
            inc(currentLevel)
         else if(st[i] in DirectorySeparators) then
            break;
      end;

      if(currentLevel = level) then begin
         {extract the extension and return it}
         Result := copy(st, i, 255);
      end else
         Result := '';
   end else
      Result := '';
end;

function ExtractFilePath(const st: string): string;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
     i := l;

     while (i >= 1) and (not (st[i] in DirectorySeparators)) do
        dec(i);

      if(i >= 2) then
         Result := copy(st, 1, i)
      else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileDrive(const st: string): string;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 1) then begin
      if(st[2] = DriveSeparator) then
         Result := copy(st, 1, 2)
      else if(st[1] in DirectorySeparators) and (st[2] in DirectorySeparators) then begin
         {skip the share}
         i := 2;

         while (i < l) and not (st[i + 1] in DirectorySeparators) do
            inc(i);
         inc(i);

         while(i < l) and not (st[i + 1] in DirectorySeparators) do inc
            (i);

         Result := copy(st, 1, i);
      end else
         Result := '';
   end else
      Result := '';
end;

procedure ReplaceDirSeparators(var st: string);
var
   rds: char; {the directory separator which must be replaced}
   i: longint;

begin
   {decide which separator to replace}
   {$IFDEF WINDOWS}rds := '/';{$ENDIF}
   {$IFDEF LINUX}rds := '\';{$ENDIF}
   {$IFDEF DARWIN}rds := '\';{$ENDIF}

   for i := 1 to Length(st) do begin
      if(st[i] = rds) then
         st[i] := DirectorySeparator;
   end;
end;

procedure ReplaceDirSeparators(var st: StdString);
var
   rds: char; {the directory separator which must be replaced}
   i: longint;

begin
   {decide which separator to replace}
   {$IFDEF WINDOWS}rds := '/';{$ENDIF}
   {$IFDEF LINUX}rds := '\';{$ENDIF}
   {$IFDEF DARWIN}rds := '\';{$ENDIF}

   for i := 1 to Length(st) do begin
      if(st[i] = rds) then
         st[i] := DirectorySeparator;
   end;
end;

{replace directory separators with the one used on the current platform}
function ReplaceDirSeparatorsf(const st: StdString): StdString;
var
   rds: char; {the directory separator which must be replaced}
   i: longint;

begin
   Result := st;

   {decide which separator to replace}
   {$IFDEF WINDOWS}rds := '/';{$ENDIF}
   {$IFDEF LINUX}rds := '\';{$ENDIF}
   {$IFDEF DARWIN}rds := '\';{$ENDIF}

   for i := 1 to Length(Result) do begin
      if(Result[i] = rds) then
         Result[i] := DirectorySeparator;
   end;
end;

function GetParentDirectory(const st: string): string;
begin
   Result := ExpandFileName(IncludeTrailingPathDelimiter(st) + '..')
end;

function IncludeTrailingPathDelimiterNonEmpty(const st: string): string;
begin
   if(st <> '') then
      Result := IncludeTrailingPathDelimiter(st)
   else
      Result := '';
end;

{ SUB-STRINGS }

function StringFrom(const st: string; idx: longint): string;
var
   l: longint;

begin
   {check values}
   l := Length(st);

   if(l > 0) then begin
      if(idx <= l) then begin
         Result := copy(st, idx, (l - idx) + 1);
      end else
         Result := '';
   end else
      Result := '';
end;

function StringTo(const st: string; idx: longint): string;
var
   l: longint;

begin
   {check values}
   l := Length(st);
   if(l > 0) then begin
      if(l < idx) then
         idx := l;

      {return required string}
      Result := copy(st, 1, idx);
   end else
      Result := '';
end;

function CopyTo(const s: string): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (not (s[i] in strWhiteSpace)) do
         inc(i);

      Result := copy(s, 1, i - 1);
   end else
      Result := '';
end;

function CopyTo(const s: string; c: char): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (s[i] <> c) do
         inc(i);

      Result := copy(s, 1, i - 1);
   end else
      Result := '';
end;

function CopyToDel(var s: string; const chars: array of char): string;
var
   i,
   c,
   slen: longint;

begin
   if(High(chars) = 0) then
      exit(s);

   slen := length(s);
   Result := '';

   if(slen > 0) then begin
      i := 1;

      while (i <= slen) do begin
         for c := 0 to high(chars) do begin
            if(s[i] = chars[c]) then begin
               Result := copy(s, 1, i - 1);
               delete(s, 1, i);
               exit;
            end;
         end;

         inc(i);
      end;
   end;
end;

function CopyToDel(var s: string): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (not (s[i] in strWhiteSpace)) do
         inc(i);

      Result := copy(s, 1, i - 1);
      delete(s, 1, i);
   end else
      Result := '';
end;

function CopyToDel(var s: string; c: char): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (s[i] <> c) do
         inc(i);

      Result := copy(s, 1, i - 1);
      delete(s, 1, i);
   end else
      Result := '';
end;

function CopyAfter(const s: string): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (not (s[i] in strWhitespace)) do
         inc(i);

      Result := copy(s, i + 1, Length(s));
   end else
      Result := '';
end;

function CopyAfter(const s: string; c: char): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (s[i] <> c) do
         inc(i);

      Result := copy(s, i + 1, Length(s));
   end else
      Result := '';
end;

function CopyAfterDel(var s: string): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (not (s[i] in strWhitespace)) do
         inc(i);

      Result := copy(s, i + 1, Length(s));
      delete(s, i, Length(s));
   end else
      Result := '';
end;

function CopyAfterDel(var s: string; c: char): string;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (s[i] <> c) do
         inc(i);

      Result := copy(s, i + 1, Length(s));
      delete(s, i, Length(s));
   end else
      Result := '';
end;

procedure AddLeadingPadding(var s: shortstring; c: char; n: longint);
var
   i,
   l,
   m: longint;

begin
   l := Length(s);

   if(n > l) then begin
      m := n - l;
      {set the new length}
      SetLength(s, n);
      {move characters}
      Move(s[1], s[1 + m], l);

      {add leading padding}
      for i := 1 to m do
         s[i] := c;
   end;
end;

procedure AddLeadingPadding(var s: string; c: char; n: longint);
var
   i,
   l,
   m: longint;

begin
   l := Length(s);

   if(n > l) then begin
      m := n - l;
      {set the new length}
      SetLength(s, n);
      {move characters}
      Move(s[1], s[1 + m], l);

      {add leading padding}
      for i := 1 to m do
         s[i] := c;
   end;
end;

procedure AddTrailingPadding(var s: shortstring; c: char; n: longint);
var
   i,
   l,
   m: longint;

begin
   l := Length(s);
   if(n > l) then begin
      m := n - (n - l);
      {set the new length}
      SetLength(s, n);
      {add trailing padding}
      for i := m + 1 to n do
         s[i] := c;
   end;
end;

procedure AddTrailingPadding(var s: string; c: char; n: longint);
var
   i,
   l,
   m: longint;

begin
   l := Length(s);
   if(n > l) then begin
      m := n - (n - l);
      {set the new length}
      SetLength(s, n);
      {add trailing padding}
      for i := m + 1 to n do
         s[i] := c;
   end;
end;

{ SHORTSTRING }
function MakepShortString(const s: string): pShortString;
var
   ps: pShortString = nil;

begin
   GetMem(ps, Length(s) + 1);
   if(ps <> nil) then
      ps^ := s;

   Result := ps;
end;

function MakepShortString(pcs: pChar): pShortString;
var
   ss: pShortString  = nil;
   len: longint      = 0;
   pc: pChar;

begin
   if(pcs <> nil) then begin
      {figure out the string length}
      pc := pcs;

      repeat
         if(pc^ <> #0) then begin
            inc(pc);
            inc(len);
         end;
      until (pc^ = #0) or (len = 255);

      {get enough memory for the pShortString}
      GetMem(ss, len + 1);

      if(ss <> nil) then begin
         {copy the string}
         if(len > 0) then
            move(pcs^, ss^[1], len);

         ss^[0] := char(len); {set string length}
      end;
   end;

   Result := ss;{return Result}
end;

function PCharToShortString(pcs: pChar): ShortString;
var
   ss: ShortString   = '';
   len: longint      = 0;
   pc: pChar         = nil;

begin
   {figure out the string length}
   pc := pcs;

   repeat
      if(pc^ <> #0) then begin
         inc(len);
         ss[len] := pc^;
         inc(pc);
      end;
   until (pc^ = #0) or (len = 255);

   {copy the string}
   ss[0] := char(len); {set string length}

   Result := ss;
end;


{ EXPLODING }

function strExplode(const s: ansistring; delimiter: char): TAnsiStringArray;
var
   i,
   len,
   p,
   prevp,
   n,
   charcount: longint; {i, string length, position, previous position, string count}
   str: ansistring;
   stringarray: TAnsiStringArray = nil;

begin
   if(s <> '') then begin
      len := Length(s);

      p := -1;
      n := 0;
                                                                 ;
      {figure out how many strings will be required}
      for i := 1 to len do begin
         if(s[i] = delimiter) then begin
            inc(n);
            p := i;
         end;
      end;

      {if there are characters behind the last delimiter we have one more string}
      if(p <= len) then
         inc(n);

      {if there are no delimiters we have only one string to explode}
      if(p = -1) then
         n := 1;

      {allocate memory for string array}
      SetLength(stringarray, n);

      {prepare for exploding string}
      prevp := 0;
      n     := 0;

      {extract individual strings}
      for i := 1 to len do begin
         if(s[i] = delimiter) then begin
            charcount := i - prevp;
            str := copy(s, prevp + 1, charcount - 1);
            inc(n);
            stringarray[n-1] := str;

            prevp := i;
         end;
      end;

      if(prevp < len) then begin
         stringarray[n] := copy(s, prevp + 1, len-prevp);
      end else
         stringarray[n] := '';

      Result := stringarray;
   end else
      Result := nil;
end;

procedure strExplode(const s: ansistring; delimiter: char; var a: array of ShortString; maxStrings: loopint);
var
   i,
   len,
   prevp,
   n,
   charcount: longint; {i, string length, position, previous position, string count}
   str: ansistring;

begin
   if(s <> '') then begin
      len := Length(s);

      n := 0;

      {prepare for exploding string}
      prevp := 0;
      n     := 0;

      {extract individual strings}
      for i := 1 to len do begin
         if(s[i] = delimiter) then begin
            charcount := i - prevp;
            str := copy(s, prevp + 1, charcount - 1);
            inc(n);
            a[n - 1] := str;

            prevp := i;
            if(maxStrings > 0) and (n >= maxStrings) then
               break;
         end;
      end;

      {leftover string}
      if(maxStrings > 0) and (n >= maxStrings) then
         exit;

      if(prevp < len) then
         a[n] := copy(s, prevp + 1, len - prevp)
      else
         a[n] := '';
   end;
end;

procedure StringFromBytes(out s: ansistring; size: loopint; const bytes);
begin
   if(Size > 0) then begin
      s := '';
      SetLength(s, size);
      Move(bytes, s[1], size);
   end else
      s := '';
end;

function GetKeyValue(const s: string; out key, value: string; const separator: char): boolean;
var
   p: loopint;

begin
   if(s <> '') then begin
      p := pos(separator, s);

      if(p > 0) then begin
         key := Copy(s, 0, p - 1);
         StringUtils.StripWhitespace(key);

         value := Copy(s, p + 1, Length(s) - p);
         StringUtils.StripWhitespace(value);

         exit(key <> '');
      end;
   end;

   key := '';
   value := '';
   Result := false;
end;

{ TStringArrayHelper }

function TStringArrayHelper.GetSingleString(separator: StdString): StdString;
var
   i: loopint;

begin
   Result := '';

   for i := 0 to High(Self) do begin
      if(i < High(Self)) then
         Result := Result + Self[i] + separator
      else
         Result := Result + Self[i];
   end;
end;

function TStringArrayHelper.GetSingleString(): StdString;
var
   i: loopint;

begin
   Result := '';

   for i := 0 to High(Self) do begin
      Result := Result + Self[i];
   end;
end;

function TStringArrayHelper.GetAnsiStrings(): TAnsiStringArray;
var
   i: loopint;

begin
   Result := nil;
   SetLength(Result, Length(Self));

   for i := 0 to Length(Self) - 1 do
      Result[i] := Self[i];
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

function TSimpleStringListHelper.GetSingleString(separator: StdString): StdString;
var
   i: loopint;

begin
   Result := '';

   for i := 0 to n - 1 do begin
      if(i < n - 1) then
         Result := Result + List[i] + separator
      else
         Result := Result + List[i];
   end;
end;

function TSimpleStringListHelper.GetSingleString(): StdString;
var
   i: loopint;

begin
   Result := '';

   for i := 0 to n - 1 do begin
      Result := Result + List[i];
   end;
end;

function TSimpleStringListHelper.GetAnsiStrings(): TAnsiStringArray;
var
   i: loopint;

begin
   Result := nil;
   SetLength(Result, Self.n);

   for i := 0 to n - 1 do begin
      Result[i] := Self.List[i];
   end;
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

{ TStdStringStringHelper }

function TStdStringStringHelper.IsMultiLine(): boolean;
begin
   Result := Pos(LineEnding, Self) > 0;
end;

{ TExtendedStringHelper }

function TExtendedStringHelper.IsMultiLine(): boolean;
begin
   Result := Pos(LineEnding, Self) > 0;
end;

{ TPackedStrings }

class procedure TPackedStrings.Init(out ps: TPackedStrings);
begin
   ZeroPtr(@ps, SizeOf(ps));
end;

procedure TPackedStrings.Allocate(count: loopint; stringContentSize: loopint);
begin
   n := count;
   IndexTableSize := count * SizeOf(PtrInt);

   {calculate size to store strings, plus storage of }
   stringContentSize := stringContentSize {string content} +
      (count * 1) {string length} +
      IndexTableSize;

   GetMem(p, stringContentSize);

   Content := (p + IndexTableSize);
end;

function TPackedStrings.GetStringLength(index: loopint): loopint;
var
   ps: PShortString;

begin
   ps := GetString(index);

   if(ps <> nil) then
      Result := Length(ps^)
   else
      Result := 0;
end;

function TPackedStrings.GetString(index: loopint): PShortString;
begin
   if(index < n) then
      Result := PShortString(Content + PPtrInt(p)[index])
   else
      Result := nil;
end;

procedure TPackedStrings.Store(var s: shortstring; index: loopint);
begin
   Move(s[0], GetString(index)^, Length(s) + 1);
end;

{ TAnsiStringBuffer }

procedure TSimpleAnsiStringBuffer.Reset;
begin
   size := 0;
end;

procedure TSimpleAnsiStringBuffer.Write(const s: AnsiString);
var
   count: longint;

begin
   count := length(s);

   if(size + count >= STRING_SIMPLE_BUFFER_SIZE) then
      count := STRING_SIMPLE_BUFFER_SIZE - size;

   if(count > 0) then begin
      Move(s[1], buffer[size], count);
      inc(size, count);
   end;
end;

function TSimpleAnsiStringBuffer.Get(): AnsiString;
var
   s: AnsiString = '';

begin
   if(size > 0) then begin
      SetLength(s, size);
      move(buffer[0], s[1], size);

      Result := s;
   end else
      Result := s;
end;

class procedure TSimpleAnsiStringBuffer.Init(out buf: TSimpleAnsiStringBuffer);
begin
   ZeroOut(buf, SizeOf(buf))
end;

{$IFDEF OX_UTF8_SUPPORT}
procedure StripLeadingWhitespace(var st: StdString);
var
   i,
   l,
   strippos: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      {strip leading white space}
      {find white space}
      strippos := 0;

      for i := 1 to l do begin
         if(st[i] in strWhitespace) then
            inc(strippos)
         else
            break;
      end;

      {delete white space from the string}
      if(strippos <> 0) then
         delete(st, 1, strippos);
   end;
end;

procedure StripTrailingWhitespace(var st: StdString);
var
   i,
   l,
   strippos: longint;

begin
   l := length(st);

   if(l > 0) then begin
      {strip trailing white space}
      {find white space}
      strippos := 0;

      for i := l downto 1 do begin
         if(st[i] in strWhitespace) then
            inc(strippos)
         else
            break;
      end;

      {delete white space from the string}
      if(strippos > 0) then
         delete(st, l-(strippos-1), strippos);
   end;
end;

procedure StripWhitespace(var st: StdString);
begin
   StripLeadingWhitespace(st);
   StripTrailingWhitespace(st);
end;

function IsWhitespace(const st: StdString): boolean;
var
   len, i: longint;

begin
   len := Length(st);
   if(len > 0) then
      for i := 1 to len do begin
         if not (st[i] in strWhitespace) then
            exit(false);
      end;

   Result := true;
end;

procedure StripEndLine(var st: StdString);
var
   len: loopint;

begin
   len := Length(st);

   {check if we need to strip any characters off the end}
   if(st[len] = #13) then
      len := len - 1
   else if(st[len] = #10) then begin
      if(len > 1) then begin
         if(st[len - 1] = #13) then
            len := len - 2
         else
            len := len - 1;
      end else
         len := len - 1;
   end;

   {correct to new length}
   if(len <> Length(st)) then
      SetLength(st, len);
end;

procedure EliminateWhiteSpace(var st: StdString);
var
   i,
   l,
   newlen,
   count: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      newlen := l;
      count := 0;

      for i := 1 to l do begin
         if(st[i] in strWhiteSpace) then
            dec(newlen)
         else begin
            inc(count);
            st[count] := st[i]
         end;
      end;

      SetLength(st, newlen);
   end;
end;

function CopyToDel(var s: StdString; const chars: array of char): StdString;
var
   i,
   c,
   slen: longint;

begin
   if(High(chars) = 0) then
      exit(s);

   slen := length(s);
   Result := '';

   if(slen > 0) then begin
      i := 1;

      while (i <= slen) do begin
         for c := 0 to high(chars) do begin
            if(s[i] = chars[c]) then begin
               Result := copy(s, 1, i - 1);
               delete(s, 1, i);
               exit;
            end;
         end;

         inc(i);
      end;
   end;
end;

function CopyToDel(var s: StdString): StdString;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (not (s[i] in strWhiteSpace)) do
         inc(i);

      Result := copy(s, 1, i - 1);
      delete(s, 1, i);
   end else
      Result := '';
end;

function CopyToDel(var s: StdString; c: char): StdString;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (s[i] <> c) do
         inc(i);

      Result := copy(s, 1, i - 1);
      delete(s, 1, i);
   end else
      Result := '';
end;

function CopyAfterDel(var s: StdString): StdString;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (not (s[i] in strWhitespace)) do
         inc(i);

      Result := copy(s, i + 1, Length(s));
      delete(s, i, Length(s));
   end else
      Result := '';
end;

function CopyAfterDel(var s: StdString; c: char): StdString;
var
   i,
   slen: longint;

begin
   slen := length(s);
   if(slen > 0) then begin
      i := 1;

      while (i <= slen) and (s[i] <> c) do
         inc(i);

      Result := copy(s, i + 1, Length(s));
      delete(s, i, Length(s));
   end else
      Result := '';
end;

function ExtractFileName(const st: StdString): StdString;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;

      while (i > 0) and (not(st[i] in DirectorySeparators)) do
         dec(i);

      if(i + 1 < l) then
         Result := copy(st, i + 1 , 255)
      else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileNameNoExt(const st: StdString): StdString;
var
   i,
   l,
   e,
   dotpos: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;

      while(i > 0) and (not (st[i] in DirectorySeparators)) do
         dec(i);

      if(i <= l) then begin
         {now that we've found where the beginning of the filename is,
         we need to find where the end is(without the extension)}
         dotpos := StringPos(st, ExtensionSeparator, i);

         if(dotpos > 0) then
            e := dotpos
         else
            e := l;

         {now just copy the filename}
         Result := copy(st, i + 1, e - i - 1);
      end else
         Result := st;
   end else
      Result := st;
end;

function ExtractAllNoExt(const st: StdString): StdString;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l <> 0) then begin
      i := l;

      {go backwards through string until an extension separator is encountered}
      while(i > 1) and (st[i] <> ExtensionSeparator) do begin
         {quit with original if directory separator encountered before extension separator}
         if(st[i] in DirectorySeparators) then
            exit(st);

         dec(i);
      end;

      if(i > 1) then
         Result := copy(st, 1, i - 1)
      else
        Result := st;
   end else
      Result := '';
end;

function ExtractFileDir(const st: StdString): StdString;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;

      while (i >= 1) and (not (st[i] in DirectorySeparators)) do
         dec(i);

      if(i >= 2) then
         Result := copy(st, 1, i - 1)
      else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileExt(const st: StdString): StdString;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;

      while (i >= 1) and (st[i] <> ExtensionSeparator) do begin
         if(st[i] in DirectorySeparators) then
            exit('');

         dec(i);
      end;

      if(i > 0) then begin
         {extract the extension and return it}
         Result := copy(st, i, Length(st) - i + 1);
      end else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileExtNoDot(const st: StdString): StdString;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
      i := l;
      while (i >= 1) and (st[i] <> ExtensionSeparator) do
         dec(i);

      if(i > 0) then begin
         {extract the extension and return it}
         Result := copy(st, i + 1, 255);
      end else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileExts(const st: StdString; level: longint): StdString;
var
   i,
   l,
   currentLevel: longint;

begin
   l := Length(st);

   if(l > 0) and (level > 0) then begin
      i := l;
      currentLevel := 0;

      while (i > 1) and (level <> currentLevel) do begin
         dec(i);

         if(st[i] = ExtensionSeparator) then
            inc(currentLevel)
         else if(st[i] in DirectorySeparators) then
            break;
      end;

      if(currentLevel = level) then begin
         {extract the extension and return it}
         Result := copy(st, i, 255);
      end else
         Result := '';
   end else
      Result := '';
end;

function ExtractFilePath(const st: StdString): StdString;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 0) then begin
     i := l;

     while (i >= 1) and (not (st[i] in DirectorySeparators)) do
        dec(i);

      if(i >= 2) then
         Result := copy(st, 1, i)
      else
         Result := '';
   end else
      Result := '';
end;

function ExtractFileDrive(const st: StdString): StdString;
var
   i,
   l: longint;

begin
   l := Length(st);

   if(l > 1) then begin
      if(st[2] = DriveSeparator) then
         Result := copy(st, 1, 2)
      else if(st[1] in DirectorySeparators) and (st[2] in DirectorySeparators) then begin
         {skip the share}
         i := 2;

         while (i < l) and not (st[i + 1] in DirectorySeparators) do
            inc(i);
         inc(i);

         while(i < l) and not (st[i + 1] in DirectorySeparators) do inc
            (i);

         Result := copy(st, 1, i);
      end else
         Result := '';
   end else
      Result := '';
end;


function GetParentDirectory(const st: StdString): StdString;
begin
   Result := ExpandFileName(IncludeTrailingPathDelimiter(st) + '..')
end;

function IncludeTrailingPathDelimiterNonEmpty(const st: StdString): StdString;
begin
   if(st <> '') then
      Result := IncludeTrailingPathDelimiter(st)
   else
      Result := '';
end;

function strExplode(const s: StdString; delimiter: char): TStringArray;
var
   i,
   len,
   p,
   prevp,
   n,
   charcount: longint; {i, string length, position, previous position, string count}
   str: StdString;
   stringarray: TStringArray = nil;

begin
   if(s <> '') then begin
      len := Length(s);

      p := -1;
      n := 0;
                                                                 ;
      {figure out how many strings will be required}
      for i := 1 to len do begin
         if(s[i] = delimiter) then begin
            inc(n);
            p := i;
         end;
      end;

      {if there are characters behind the last delimiter we have one more string}
      if(p <= len) then
         inc(n);

      {if there are no delimiters we have only one string to explode}
      if(p = -1) then
         n := 1;

      {allocate memory for string array}
      SetLength(stringarray, n);

      {prepare for exploding string}
      prevp := 0;
      n     := 0;

      {extract individual strings}
      for i := 1 to len do begin
         if(s[i] = delimiter) then begin
            charcount := i - prevp;
            str := copy(s, prevp + 1, charcount - 1);
            inc(n);
            stringarray[n-1] := str;

            prevp := i;
         end;
      end;

      if(prevp < len) then begin
         stringarray[n] := copy(s, prevp + 1, len-prevp);
      end else
         stringarray[n] := '';

      Result := stringarray;
   end else
      Result := nil;
end;

procedure strExplode(const s: StdString; delimiter: char; var a: array of ShortString; maxStrings: loopint);
var
   i,
   len,
   prevp,
   n,
   charcount: longint; {i, string length, position, previous position, string count}
   str: StdString;

begin
   if(s <> '') then begin
      len := Length(s);

      n := 0;

      {prepare for exploding string}
      prevp := 0;
      n     := 0;

      {extract individual strings}
      for i := 1 to len do begin
         if(s[i] = delimiter) then begin
            charcount := i - prevp;
            str := copy(s, prevp + 1, charcount - 1);
            inc(n);
            a[n - 1] := str;

            prevp := i;
            if(maxStrings > 0) and (n >= maxStrings) then
               break;
         end;
      end;

      {leftover string}
      if(maxStrings > 0) and (n >= maxStrings) then
         exit;

      if(prevp < len) then
         a[n] := copy(s, prevp + 1, len - prevp)
      else
         a[n] := '';
   end;
end;

procedure StringFromBytes(out s: StdString; size: loopint; const bytes);
begin
   if(Size > 0) then begin
      s := '';
      SetLength(s, size);
      Move(bytes, s[1], size);
   end else
      s := '';
end;

function GetKeyValue(const s: StdString; out key, value: StdString; const separator: char): boolean;
var
   p: loopint;

begin
   if(s <> '') then begin
      p := pos(separator, s);

      if(p > 0) then begin
         key := Copy(s, 0, p - 1);
         StringUtils.StripWhitespace(key);

         value := Copy(s, p + 1, Length(s) - p);
         StringUtils.StripWhitespace(value);

         exit(key <> '');
      end;
   end;

   key := '';
   value := '';
   Result := false;
end;
{$ENDIF}

END.
