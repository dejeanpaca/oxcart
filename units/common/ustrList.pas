{
   ustrList, string list management
   Copyright (C) 2011. Dejan Boras

   Started On:    27.03.2011.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT ustrList;

INTERFACE

   USES ctypes, uStd, StringUtils;

TYPE
   TStringListProcessCallback = procedure(i: longint; const s: string);

   { TStringListGlobal }

   TStringListGlobal = record
      { compact pchar string arrays }
      {move the string pointer to the next string in the list}
      function NextString(var s: pchar): boolean;
      {convert a compact pchar string list into a array of pshortstrings}
      function Convert(s: pchar; var list: TpShortStringArray; var n: longint): longint;
      procedure Convert(s: pcchar; var list: TpShortStringArray; var n: longint);
      {convert a compact pchar string list to a compact shortstring list}
      function Convert(s: pchar; var p: pointer; var list: TpShortStringArray; var n: longint): longint;
      function Convert(s: pcchar; var p: pointer; var list: TpShortStringArray; var n: longint): longint;
      {convert a space separated pchar string list to compact shortstring list}
      function ConvertSpaceSeparated(s: pchar; var p: pointer;
         var list: TpShortStringArray; var n: longint): longint;
      function ConvertSpaceSeparated(s: pcchar; var p: pointer;
         var list: TpShortStringArray; var n: longint): longint;
      function ConvertNullSeparated(s: pchar; var p: pointer;
         var list: TpShortStringArray; var n: longint): longint;

      {convert a space separated string list to compact shortstring list}
      function ConvertSpaceSeparated(const s: string; var list: TAnsiStringArray; var n: longint): longint;

      {process a list of space separated strings via a callback}
      procedure ProcessSpaceSeparated(s: pchar; clback: TStringListProcessCallback);
      procedure ProcessSpaceSeparated(const s: string; clback: TStringListProcessCallback);

      {converts a list to a space separated string}
      function ConvertToSpaceSeparated(var list: TAnsiStringArray; out s: string): longint;

      {disposing of string lists}
      procedure Dispose(var l: TpShortStringArray);
      procedure Dispose(var l: TShortStringArray);
      procedure Dispose(var l: TpCharDynArray);

      {disposing of compact lists}
      procedure Dispose(var p: pointer; var list: TpShortStringArray);
   end;

VAR
   strList: TStringListGlobal;

IMPLEMENTATION

{ compact pchar string arrays }
function TStringListGlobal.NextString(var s: pchar): boolean;
begin
   if(s^ <> #0) then begin
      s := s + (length(s) + 1);

      exit(true);
   end else 
      exit(false);
end;

function TStringListGlobal.Convert(s: pchar; var list: TpShortStringArray; var n: longint): longint;
var
   ps: pchar;
   i: longint = 0;

begin
   result := eNONE;

   {first we need to figure out how many strings we got}
   ps := pchar(s);
   repeat
      if(ps^ <> #0) then 
         inc(n);
   until (NextString(ps) = false);

   {next, allocate memory for the string list}
   SetLength(list, n);
   if(Length(list) <> n) then
      exit(eNO_MEMORY);

   {next we will put each string into the list}
   ps := pchar(s);
   repeat
      if(ps^ <> #0) then begin
         {put the string into the list}
         list[i] := MakepShortString(ps);
         inc(i);
      end;
   until (NextString(ps) = false);
end;

procedure TStringListGlobal.Convert(s: pcchar; var list: TpShortStringArray; var n: longint);
begin
   Convert(pchar(s), list, n);
end;

function TStringListGlobal.Convert(s: pchar; var p: pointer; var list: TpShortStringArray; var n: longint): longint;
var
   ps: pchar; {points to a current pchar string}
   totalsize: longint   = 0; {the total number of bytes required for the compact list}
   i: longint           = 0;
   pp: pshortstring; {points to the current shortstring in the compact list}

{clean up if failed to perform(error happened)}
procedure cleanup();
begin
   if(list <> nil) then 
      SetLength(list, 0);

   XFreeMem(p);
   n := 0;
end;

begin
   n := 0;

   {first we need to figure out how many strings we got}
   ps := pchar(s);
   repeat
      if(ps^ <> #0) then begin
         inc(totalsize, length(ps)+1); 
         inc(n);
      end;
   until (NextString(ps) = false);

   {next, allocate memory for the string list}
   SetLength(list, n);
   if(Length(list) <> n) then begin
      cleanup();
      exit(eNO_MEMORY);
   end;

   {allocate memory for the compact list}
   {BUG: Without the extra memory allocated corruptions occur. Overwriting?}
   GetMem(p, totalsize+36);

   if(p = nil) then begin
      cleanup();
      exit(eNO_MEMORY);
   end;

   pp := p;

   {next we will put each string into the compact list}
   ps := pchar(s);
   repeat
      if(ps^ <> #0) then begin
         {put the string into the compact list}
         pp^ := pCharToShortString(ps);
         list[i] := pp;
         inc(pp, Length(pp^)+1);
         inc(i);
      end;
   until (NextString(ps) = false);

   result := eNONE;
end;

function TStringListGlobal.Convert(s: pcchar; var p: pointer; var list: TpShortStringArray; var n: longint): longint;
begin
   result := Convert(pchar(s), p, list, n);
end;

{convert a space separated pchar string list to compact shortstring list}
function TStringListGlobal.ConvertSpaceSeparated(s: pchar; var p: pointer;
   var list: TpShortStringArray; var n: longint): longint;
var
   pc: pChar;
   i,
   TotalSize,
   StringSize: longint;

   ExtString: ShortString;
   pp: pshortstring;
   wSpace: boolean = false;

begin
   result := eNONE;

   {if there are strings}
   if(s <> nil) then begin
      {get the string size and the string count}
      pc          := s;
      if(pc^ = #0) then
         exit; {if there are no strings}

      TotalSize   := 0;
      n           := 0;
      wSpace := true;

      repeat
         inc(TotalSize);

         if(not (pc^ in[#32, #9, #0])) then begin
            if(wSpace = true) then begin
               wSpace := false;
               inc(n);
            end
         end else 
            wSpace := true;

         inc(pc);
      until (pc^ = #0);
      inc(TotalSize); {also account for the null character}

      {if there are no strings at all}
      if(n = 0) then 
         exit;

      {get memory for all the strings}
      GetMem(p, TotalSize);
      if(p = nil) then
         exit(eNO_MEMORY);

      {get memory for extension string pointers}
      SetLength(list, n);
      if(Length(list) <> n) then begin
         XFreeMem(p);
         SetLength(list, 0);
         exit(eNO_MEMORY);
      end;

      {extract all the strings}
      TotalSize   := 0; 
      i           := 0; 
      pc          := (s-1); 
      pp          := p;

      repeat
         StringSize := 0;

         repeat
            inc(pc);

            if (not (pc^ in [#0, #32])) then begin
               ExtString[StringSize+1] := pc^; 
               inc(StringSize);
            end;
         until (pc^ in [#0, #32]);

         {found an extension, so we'll add it}
         if(StringSize <> 0) then begin
            ExtString[0] := char(StringSize);
            inc(StringSize);
            {copy the extension to the heap}
            move(ExtString[0], (pp)^, StringSize); {<here is the fault}
            {add the pointer}
            list[i] := (pp);
            {next extension}
            inc(TotalSize, StringSize);
            inc(pointer(pp), StringSize);
            inc(i);
         end;
      until (pc^ = #0);
   end;
end;

function TStringListGlobal.ConvertSpaceSeparated(s: pcchar; var p: pointer;
   var list: TpShortStringArray; var n: longint): longint;
begin
   result := ConvertSpaceSeparated(pchar(s), p, list, n);
end;

function TStringListGlobal.ConvertNullSeparated(s: pchar; var p: pointer;
   var list: TpShortStringArray; var n: longint): longint;
var
   pc: pChar;
   i,
   TotalSize,
   StringSize: longint;

   ExtString: ShortString;
   pp: pshortstring;
   wSpace: boolean = false;

begin
   result := eNONE;

   {if there are strings}
   if(s <> nil) then begin
      {get the string size and the string count}
      pc          := s;

      if(pc^ = #0) and ((pc + 1)^ = #0)then
         exit; {if there are no strings}

      TotalSize   := 0;
      n           := 0;
      wSpace := true;

      repeat
         inc(TotalSize);

         if(not (pc^ in[#0])) then begin
            if(wSpace = true) then begin
               wSpace := false;
               inc(n);
            end
         end else
            wSpace := true;

         inc(pc);
      until (pc^ = #0) and ((pc + 1)^ = #0);
      inc(TotalSize); {also account for the null character}

      {if there are no strings at all}
      if(n = 0) then
         exit;

      {get memory for all the strings}
      GetMem(p, TotalSize);
      if(p = nil) then
         exit(eNO_MEMORY);

      {get memory for extension string pointers}
      SetLength(list, n);
      if(Length(list) <> n) then begin
         XFreeMem(p);
         SetLength(list, 0);
         exit(eNO_MEMORY);
      end;

      {extract all the strings}
      TotalSize   := 0;
      i           := 0;
      pc          := s - 1;
      pp          := p;

      repeat
         StringSize := 0;

         repeat
            inc(pc);

            if (not (pc^ in [#0])) then begin
               ExtString[StringSize + 1] := pc^;
               inc(StringSize);
            end;
         until (pc^ in [#0]);

         {found an extension, so we'll add it}
         if(StringSize <> 0) then begin
            ExtString[0] := char(StringSize);
            inc(StringSize);

            {copy the extension to the heap}
            move(ExtString[0], (pp)^, StringSize); {<here is the fault}

            {add the pointer}
            list[i] := (pp);

            {next extension}
            inc(TotalSize, StringSize);
            inc(pointer(pp), StringSize);
            inc(i);
         end;
      until (pc^ = #0) and ((pc + 1)^ = #0);
   end;
end;

function TStringListGlobal.ConvertSpaceSeparated(const s: string; var list: TAnsiStringArray; var n: longint): longint;
var
   pc: longint;
   i, 
   StringSize, 
   StringLen: longint;
   ExtString: ShortString;
   wSpace: boolean = false;

begin
   result := eNONE;
   StringLen := Length(s);

   {if there are strings}
   if(StringLen > 0) then begin
      {get the string size and the string count}
      n := 0;
      pc := 1;
      wSpace := true;

      repeat
         if(not (s[pc] in[#32, #9, #0])) then begin
            if(wSpace = true) then begin
               wSpace := false;
               inc(n);
            end
         end else
            wSpace := true;

         inc(pc);
      until (pc = StringLen);

      {if there are no strings at all}
      if(n = 0) then
         exit;

      {get memory for extension string pointers}
      SetLength(list, n);

      if(Length(list) <> n) then begin
         SetLength(list, 0);
         exit(eNO_MEMORY);
      end;

      {extract all the strings}
      i  := 0;
      pc := 0;

      repeat
         StringSize := 0;
         repeat
            inc(pc);
            if (not (s[pc] in [#0, #32])) then begin
               ExtString[StringSize + 1] := s[pc];
               inc(StringSize);
            end;
         until (s[pc] in [#0, #32]) or (pc = stringLen);

         {found an extension, so we'll add it}
         if(StringSize <> 0) then begin
            ExtString[0] := char(StringSize);
            list[i] := ExtString;

            {next extension}
            inc(i);
         end;

      until (pc = StringLen);
   end else begin
      n := 0;
      SetLength(list, 0);
   end;
end;

procedure TStringListGlobal.ProcessSpaceSeparated(s: pchar; clback: TStringListProcessCallback);
var
   pc: pChar;
   i, 
   StringSize: longint;
   ExtString: shortstring;
   pp: shortstring;

begin
   {if there are strings}
   if(s <> nil) then begin
      {extract all the strings}
      i := 0;
      pc := (s-1);

      repeat
         StringSize := 0;

         repeat
            inc(pc);

            if (not (pc^ in [#0, #32])) then begin
               ExtString[StringSize + 1] := pc^;
               inc(StringSize);
            end;
         until (pc^ in [#0, #32]);
         ExtString[0] := char(StringSize);

         {found an extension, so we'll add it}
         if(StringSize <> 0) then begin
            {copy the extension to the heap}
            pp := copy(ExtString, 1, StringSize);

            if(clback <> nil) then
               clback(i, pp);

            {next extension}
            inc(i);
         end;
      until (pc^ = #0);
   end;
end;

procedure TStringListGlobal.ProcessSpaceSeparated(const s: string; clback: TStringListProcessCallback);
var
   pc: longint;
   i, 
   StringSize, 
   StringLen: longint;
   ExtString: shortstring;
   pp: shortstring;

begin
   StringLen := Length(s);

   {if there are strings}
   if(StringLen > 0) then begin
      {extract all the strings}
      i := 0;
      pc := 0;

      repeat
         StringSize := 0;

         repeat
            inc(pc);

            if (not (s[pc] in [#0, #32])) then begin
               ExtString[StringSize+1] := s[pc];
               inc(StringSize);
            end;
         until (s[pc] in [#0, #32]);

         ExtString[0] := char(StringSize);

         {found an extension, so we'll add it}
         if(StringSize <> 0) then begin
            {copy the extension to the heap}
            pp := copy(ExtString, 1, StringSize);

            if(clback <> nil) then
               clback(i, pp);

            {next extension}
            inc(i);
         end;
      until pc = StringLen;
   end;
end;

{disposing}

function TStringListGlobal.ConvertToSpaceSeparated(var list: TAnsiStringArray; out s: string): longint;
var
   i, 
   n, 
   stringSize, 
   currentPosition: longint;
   TotalSize: longint;

begin
   result := eNONE;

   s := '';
   n := Length(list);

   if(n > 0) then begin
      TotalSize := 0;

      for i := 0 to (n - 1) do begin
         stringSize := Length(list[i]);
         inc(totalSize, stringSize);

         {account for space after each character}
         if(i < n - 1) then
            inc(TotalSize);
      end;

      if(TotalSize > 0) then begin
         SetLength(s, TotalSize);
         currentPosition := 1;

         for i := 0 to (n - 1) do begin
            stringSize := Length(list[i]);

            if(stringSize > 0) then begin
               Move(list[i][1], s[currentPosition], stringSize);
               inc(currentPosition, stringSize);

               if(i < n - 1) then begin
                  s[currentPosition] := ' ';
                  inc(currentPosition);
               end;
            end;
         end;

      end;
   end;
end;

procedure TStringListGlobal.Dispose(var l: TpShortStringArray);
var
   i, 
   n: longint;

begin
   n := Length(l);

   if(n > 0) then begin
      for i := 0 to (n-1) do
         XFreeMem(l[i]);

      SetLength(l, 0);
      l := nil;
   end;
end;

procedure TStringListGlobal.Dispose(var l: TShortStringArray);
var
   n: longint;

begin
   n := Length(l);

   if(n > 0) then begin
      SetLength(l, 0);
      l := nil;
   end;
end;

procedure TStringListGlobal.Dispose(var l: TpCharDynArray);
var
   i,
   n: longint;

begin
   n := Length(l);

   if(n > 0) then begin
      for i := 0 to (n-1) do
         XFreeMem(l[i]);

      SetLength(l, 0);
      l := nil;
   end;
end;

{disposing of compact lists}
procedure TStringListGlobal.Dispose(var p: pointer; var list: TpShortStringArray);
begin
   XFreeMem(p);

   if(list <> nil) then begin
      SetLength(list, 0);
      list := nil;
   end;
end;

END.
