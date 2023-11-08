{
   uyPakFile, yPak file helper
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uyPakFile;

INTERFACE

   USES
      uStd, uFile;

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
   ypkfTHeader = packed record
      {file ID}
      ID: ypkTID;
      {file endian}
      Endian,
      {version of the ypk file}
      Version: word;
      {size of the data blob}
      BlobSize,
      {number of files we have}
      Files,
      {offset where the files start (files offset is already included into each file entry offset, but is here to indicate the start of the files block)}
      FilesOffset,
      {total size for files block}
      FilesSize: fileint;
   end;

   ypkfPEntry = ^ypkfTEntry;
   {contains a entry for a file}
   ypkfTEntry = packed record
      {offset for the filename in the blob}
      FileNameOffset,
      {offset for the file in the ypk file}
      Offset,
      {size of the file}
      Size: fileint;
   end;

   ypkfTEntries = specialize TSimpleList<ypkfTEntry>;

   { ypkfTGlobal }

   ypkfTGlobal = record
      Error: loopint;

      { ERROR HANDLING }
      procedure eRaise(e: longint);
      function eGet(): longint;
      procedure eReset();

      procedure InitializeHeader(out hdr: ypkfTHeader);

      { HEADER }
      procedure ReadHeader(var f: TFile; out hdr: ypkfTHeader);
      procedure WriteHeader(var f: TFile; const hdr: ypkfTHeader);

      { ENTRIES }
      function ReadEntries(var f: TFile; var e: ypkfTEntries; count: longint): fileint;
      procedure WriteEntries(var f: TFile; var e: ypkfTEntries);

      { FILENAMES BLOB }
      function ReadBlob(var f: TFile; out blob: PByte; size: fileint): fileint;
      function WriteBlob(var f: TFile; out blob: PByte; size: fileint): fileint;
   end;

CONST
   ypkHEADER_SIZE       = SizeOf(ypkfTHeader);
   ypkENTRY_SIZE        = SizeOf(ypkfTEntry);

VAR
   ypkf: ypkfTGlobal;

IMPLEMENTATION

{ ERROR HANDLING }

procedure ypkfTGlobal.eRaise(e: longint);
begin
   Error := e;
end;

function ypkfTGlobal.eGet(): longint;
begin
   result := error;
   Error := 0;
end;

procedure ypkfTGlobal.eReset();
begin
   Error := 0;
end;

procedure ypkfTGlobal.InitializeHeader(out hdr: ypkfTHeader);
begin
   ZeroOut(hdr, SizeOf(hdr));

   hdr.ID         := ypkID;
   hdr.Endian     := ypkENDIAN;
   hdr.Version    := ypkVERSION;
end;

{ HEADER }

procedure ypkfTGlobal.ReadHeader(var f: TFile; out hdr: ypkfTHeader);
begin
   f.Read(hdr, SizeOf(hdr));

   if(f.Error = 0) then begin
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

procedure ypkfTGlobal.WriteHeader(var f: TFile; const hdr: ypkfTHeader);
begin
   f.Write(hdr, SizeOf(hdr));
end;

{ ENTRIES }

function ypkfTGlobal.ReadEntries(var f: TFile; var e: ypkfTEntries; count: longint): fileint;
begin
   if(count > 0) then begin
      e.n := count;

      try
         SetLength(e.List, e.n);
      except
         exit(eNO_MEMORY);
      end;

      f.Read(e.List[0], int64(count) * ypkENTRY_SIZE);
   end;

   Result := eNONE;
end;

procedure ypkfTGlobal.WriteEntries(var f: TFile; var e: ypkfTEntries);
begin
   if(e.n > 0) then
      f.Write(e.List[0], int64(e.n) * ypkENTRY_SIZE);
end;

function ypkfTGlobal.ReadBlob(var f: TFile; out blob: PByte; size: fileint): fileint;
begin
   Result := 0;

   blob := nil;

   if(size > 0) then begin
      XGetMem(blob, size);

      Result := f.Read(blob^, size);
   end;
end;

function ypkfTGlobal.WriteBlob(var f: TFile; out blob: PByte; size: fileint): fileint;
begin
   Result := 0;

   blob := nil;

   if(size > 0) then begin
      Result := f.Write(blob^, size);
   end;
end;

END.
