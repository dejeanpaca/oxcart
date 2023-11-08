{
   uyPak, yPak base unit
   Copyright (C) 2011. Dejan Boras

   Started On:    24.02.2011.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT uyPak;

INTERFACE

   USES uStd, uFile;

TYPE
   ypkTID = array[0..3] of char;

CONST
   ypkID: ypkTID           = 'yPAK';

   ypkDirSep: char         = DirectorySeparator; {directory separator for ypk}

   ypkVERSION              = $0100;
   ypkMAX_FN_LENGTH        = 87; {maximum filename length}

   { ENDIANS }
   YPK_ENDIAN_LITTLE       = $0000;
   YPK_ENDIAN_BIG          = $FFFF;

   ypkENDIAN               = {$IFDEF ENDIAN_LITTLE}YPK_ENDIAN_LITTLE{$ELSE}YPK_ENDIAN_BIG{$ENDIF};

   { YPAK ERROR CODES }
   ypkeIO                  = $0100;
   
   ypkeUNSUPPORTED_ENDIAN  = $0101;
   ypkeUNSUPPORTED_VERSION = $0102;
   ypkeINVALID_ID          = $0103;

TYPE
   ypkTHeader = packed record
      ID: ypkTID;
      Endian: word;
      Version: word;
      Files: longint;
   end;

   ypkPEntry = ^ypkTEntry;
   ypkTEntry = packed record
      offs, size: longint;
      fn: string[ypkMAX_FN_LENGTH];
   end;

   ypkTEntries = specialize TSimpleList<ypkTEntry>;

   ypkTGlobal = record
      error: longint;

      { ERROR HANDLING }
      procedure eRaise(e: longint);
      function eGet(): longint;
      procedure eReset();

      { HEADER }
      procedure ReadHeader(var f: TFile; out hdr: ypkTHeader);
      procedure WriteHeader(var f: TFile; filecount: longint);

      { ENTRIES }
      function ReadEntries(var f: TFile; var e: ypkTEntries; count: longint): longint;
      procedure WriteEntries(var f: TFile; var e: ypkTEntries);

      {finds a file with the specified name in the entries}
      function Find(var e: ypkTEntries; const fn: string): longint;
   end;

CONST
   ypkHEADER_SIZE       = SizeOf(ypkTHeader);
   ypkENTRY_SIZE        = SizeOf(ypkTEntry);

VAR
   ypk: ypkTGlobal;

IMPLEMENTATION

{ ERROR HANDLING }

procedure ypkTGlobal.eRaise(e: longint);
begin
   error := e;
end;

function ypkTGlobal.eGet(): longint;
begin
   result := error;
   error := 0;
end;

procedure ypkTGlobal.eReset();
begin
   error := 0;
end;


{ HEADER }

procedure ypkTGlobal.ReadHeader(var f: TFile; out hdr: ypkTHeader);
begin
   f.Read(hdr, SizeOf(hdr));

   if(f.error = 0) then begin
      { check if it is a valid and supported file }
      if(hdr.ID = ypkID) then begin
         if(hdr.Endian = ypkENDIAN) then begin
            if(hdr.Version <> ypkVERSION) then
               eRaise(ypkeUNSUPPORTED_VERSION);
         end else
            eRaise(ypkeUNSUPPORTED_ENDIAN);
      end else
         eRaise(ypkeINVALID_ID);
   end;
end;

procedure ypkTGlobal.WriteHeader(var f: TFile; filecount: longint);
var
   hdr: ypkTHeader;

begin
   hdr.ID         := ypkID;
   hdr.Endian     := ypkENDIAN;
   hdr.Version    := ypkVERSION;
   hdr.Files      := filecount;

   f.Write(hdr, SizeOf(hdr));
end;

{ ENTRIES }

function ypkTGlobal.ReadEntries(var f: TFile; var e: ypkTEntries; count: longint): longint;
begin
   if(count > 0) then begin
      e.n := count;

      try
         SetLength(e.list, e.n);
      except
         exit(eNO_MEMORY);
      end;

      f.Read(e.list[0], int64(count) * ypkENTRY_SIZE);
   end;

   result := eNONE;
end;

procedure ypkTGlobal.WriteEntries(var f: TFile; var e: ypkTEntries);
begin
   if(e.n > 0) then
      f.Write(e.list[0], int64(e.n) * ypkENTRY_SIZE);
end;

function ypkTGlobal.Find(var e: ypkTEntries; const fn: string): longint;
var
   i: longint;

begin
   if(e.n > 0) then
      for i := 0 to (e.n-1) do begin
         if(e.list[i].fn = fn) then
            exit(i);
      end;

   result := -1;
end;

END.
