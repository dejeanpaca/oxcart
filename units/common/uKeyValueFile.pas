{
   uKeyValueFile
   Copyright (C) 2011. Dejan Boras

   Started On:    02.03.2015.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$I-}
UNIT uKeyValueFile;

INTERFACE

   USES uStd, StringUtils;

TYPE
   TKeyValueEntry = record
      Key,
      Value: string;
   end;

   TKeyValueList = specialize TPreallocatedArrayList<TKeyValueEntry>;

   { TKeyValueFileGlobal }

   TKeyValueFile = record
      ioE: longint;
      Separator: char;

      List: TKeyValueList;

      procedure Add(const key, value: string);
      procedure Reset();
      procedure Dispose();

      function Load(const path: string): boolean;
      function Write(const path: string): boolean;

      private
         function ioerr(): longint;
   end;

   { TKeyValueFileGlobal }

   TKeyValueFileGlobal = record
      procedure Init(out f: TKeyValueFile);
   end;

VAR
   KeyValueFile: TKeyValueFile;
   KeyValueFiles: TKeyValueFileGlobal;

IMPLEMENTATION

{ TKeyValueFileGlobal }

procedure TKeyValueFileGlobal.Init(out f: TKeyValueFile);
begin
   ZeroOut(f, SizeOf(f));

   f.Separator     := '=';
   f.List.InitializeValues(f.List);
end;


{ TKeyValueFile }

procedure TKeyValueFile.Add(const key, value: string);
var
   entry: TKeyValueEntry;

begin
   entry.Key := key;
   entry.Value := value;

   List.Add(entry);
end;

procedure TKeyValueFile.Reset();
begin
   List.Dispose();
end;

procedure TKeyValueFile.Dispose;
begin
   Reset();
end;

function TKeyValueFile.Load(const path: string): boolean;
var
   f: text;
   buf: array[0..8191] of byte;
   s,
   key,
   value: string;

begin
   Reset();
   Result := false;
   ioE := 0;

   Assign(f, path);
   system.Reset(f);
   if(ioerr() <> 0) then
      exit;

   SetTextBuf(f, buf{%H-});

   repeat
      readln(f, s);
      if(ioerr() <> 0) then
         break;

      if(GetKeyValue(s, key, value, Separator)) then
         Add(key, value);
   until eof(f);

   Close(f);
   ioerr();

   if(ioE = 0) then
      Result := true;
end;

function TKeyValueFile.Write(const path: string): boolean;
var
   f: text;
   buf: array[0..8191] of byte;
   i: longint;

begin
   Result := false;
   ioE := 0;

   Assign(f, path);
   Rewrite(f);
   if(ioerr() <> 0) then
      exit;

   SetTextBuf(f, buf{%H-});

   if(List.n > 0) then
      for i := 0 to (List.n - 1) do begin
         writeln(f, List.List[i].Key, ' ', separator, ' ', List.List[i].Value);

         if(ioerr() <> 0) then
            break;
      end;

   Close(f);
   ioerr();

   if(ioE = 0) then
      Result := true;
end;

function TKeyValueFile.ioerr: longint;
begin
   Result := ioerror();

   if(Result <> 0) then
      ioE := Result;
end;

INITIALIZATION
   KeyValueFiles.Init(keyValueFile);
END.

