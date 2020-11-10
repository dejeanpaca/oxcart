{
   uFileStrings, file string helper
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uFileStrings;

INTERFACE

   USES
      sysutils, uStd, StringUtils,
      uFile, uFileUtils, uFiles;

TYPE

   { TFileStrings }

   TFileStrings = record
      {load list of short strings into a packed memory structur}
      function LoadPacked(var f: TFile; out p: TPackedStrings): fileint;
      {Load a list of strings from given file. Returns number of strings loaded on success or fileutil error code.}
      function LoadList(var f: TFile; out s: TStringArray): fileint;

      {load list of short strings into a packed memory structur}
      function LoadPacked(const fn: string; out p: TPackedStrings): fileint;
      {Load a list of strings from given file. Returns number of strings loaded on success or fileutil error code.}
      function LoadList(const fn: string; out s: TStringArray): fileint;
   end;

VAR
   fStrings: TFileStrings;

IMPLEMENTATION

{ TFileStrings }

function TFileStrings.LoadPacked(var f: TFile; out p: TPackedStrings): fileint;
var
   current: shortstring;
   index,
   totalStrings,
   totalSize: loopint;

begin
   current := '';
   Result := eNONE;
   TPackedStrings.Init(p);

   totalStrings := 0;
   totalSize := 0;

   repeat
      f.ReadShortString(current);

      if(f.Error = 0) then begin
         inc(totalSize, Length(current));
         inc(totalStrings);
      end else
         break;
   until f.EOF();

   if(f.Error = 0) then begin
      f.SeekStart();
      index := 0;

      p.Allocate(totalStrings, totalSize);

      repeat
         f.Readln(current);

         if(f.Error = 0) then begin
            p.Store(current, index);
            inc(index);
         end else
            break;
      until f.EOF();

      exit(totalStrings);
   end;

   exit(eFILE_READ);
end;

function TFileStrings.LoadList(var f: TFile; out s: TStringArray): fileint;
begin
   s := nil;
   Result := eNONE;

   LoadList(f, s);
   f.ReadStrings(s);

   if(f.Error = 0) then
      exit(Length(s));

   exit(eFILE_READ);
end;

function TFileStrings.LoadPacked(const fn: string; out p: TPackedStrings): fileint;
var
   f: TFile;

begin
   fFile.Init(f);
   f.Open(fn);
   p := nil;

   if(f.Error = 0) then begin
      LoadPacked(f, p);
   end else
      Result := eFILE_OPEN;

   f.CloseAndDestroy();
end;

function TFileStrings.LoadList(const fn: string; out s: TStringArray): fileint;
var
   f: TFile;

begin
   s := nil;
   Result := eNONE;

   fFile.Init(f);
   f.Open(fn);

   if(f.Error = 0) then begin
      Result := LoadList(f, s);
   end else
      Result := eFILE_OPEN;

   f.CloseAndDestroy();
end;

END.
