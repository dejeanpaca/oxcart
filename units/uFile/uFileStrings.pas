{
   uFileStrings, file string helper
   Copyright (C) 2018. Dejan Boras

   Started On:    25.12.2018.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT uFileStrings;

INTERFACE

   USES sysutils, uStd, StringUtils, uFile, uFileUtils, uFiles;

TYPE

   { TFileStrings }

   TFileStrings = record
      {load list of short strings into a packed memory structur}
      function LoadPacked(const fn: string; out p: TPackedStrings): fileint;
      {Load a list of strings from given file. Returns number of strings loaded on success or fileutil error code.}
      function LoadList(const fn: string; out s: TStringArray): fileint;
   end;

VAR
   fStrings: TFileStrings;

IMPLEMENTATION

{ TFileStrings }

function TFileStrings.LoadPacked(const fn: string; out p: TPackedStrings): fileint;
var
   f: TFile;
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

   fFile.Init(f);
   f.Open(fn);
   if(f.Error = 0) then begin
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

         exit(totalStrings)
      end;

      f.CloseAndDestroy();
      exit(eFILE_READ);
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
      f.ReadStrings(s);

      if(f.Error = 0) then
         exit(Length(s));

      f.CloseAndDestroy();
      exit(eFILE_READ);
   end else
      Result := eFILE_OPEN;

   f.CloseAndDestroy();
end;

END.
