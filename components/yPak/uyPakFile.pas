{
   uyPakFile, yPak file helper
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uyPakFile;

INTERFACE

   USES
      uStd, uFile, StringUtils;

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

   { ypkfTHeader }

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

      {returns total size for all data, excluding header}
      function DataSize(): fileint;
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

   ypkPData = ^ypkTData;

   { ypkTData }

   ypkTData = record
      {how many files do we have}
      Files: loopint;
      {blob size}
      BlobSize: fileint;
      {blob memory containing file names}
      Blob: PByte;
      {ypk entries}
      Entries: ypkfTEntries;

      {correct file path separators for all entries}
      procedure CorrectPaths();
      {get file name for the given file index}
      function GetFn(index: loopint): PShortString;
      {finds a file with the specified name in the entries}
      function Find(const fn: string): longint;

      class procedure Initialize(out d: ypkTData); static;
   end;

   { ypkTFile }

   ypkTFile = record
      Error: loopint;
      f: PFile;

      { ERROR HANDLING }
      procedure eRaise(e: longint);
      function eGet(): longint;
      procedure eReset();

      class procedure Initialize(out ypkf: ypkTFile); static;

      class procedure InitializeHeader(out hdr: ypkfTHeader); static;

      { HEADER }
      procedure ReadHeader(out hdr: ypkfTHeader);
      procedure WriteHeader(const hdr: ypkfTHeader);

      { ENTRIES }
      function ReadEntries(var e: ypkfTEntries; count: longint): fileint;
      procedure WriteEntries(var e: ypkfTEntries);

      function ReadEntries(var data: ypkTData): fileint;

      { FILENAMES BLOB }
      function ReadBlob(out blob: PByte; size: fileint): fileint;
      function ReadBlob(var data: ypkTData): fileint;
      function WriteBlob(var blob: PByte; size: fileint): fileint;
   end;

CONST
   ypkHEADER_SIZE       = SizeOf(ypkfTHeader);
   ypkENTRY_SIZE        = SizeOf(ypkfTEntry);

IMPLEMENTATION

{ ypkTData }

procedure ypkTData.CorrectPaths();
var
   i: loopint;
   fn: PShortString;

begin
   for i := 0 to Entries.n - 1 do begin
      fn := GetFn(i);

      ReplaceDirSeparators(fn^);
   end;
end;

function ypkTData.GetFn(index: loopint): PShortString;
begin
   Result := @EmptyShortString;

   if(index >= 0) and (index < Entries.n) then begin
      Result := PShortString(Blob + PtrInt(Entries.List[index].FileNameOffset));
   end;
end;

function ypkTData.Find(const fn: string): longint;
var
   i: longint;

begin
   if(Entries.n > 0) and (Blob <> nil) and (BlobSize > 0) then begin
      for i := 0 to Entries.n - 1 do begin
         if(GetFN(i)^ = fn) then
            exit(i);
      end;
   end;

   Result := -1;
end;

class procedure ypkTData.Initialize(out d: ypkTData);
begin
   ZeroOut(d, SizeOf(d));
   d.Entries.InitializeValues(d.Entries);
end;

{ ypkfTHeader }

function ypkfTHeader.DataSize(): fileint;
begin
   Result := BlobSize + FilesSize;
end;

{ ERROR HANDLING }

procedure ypkTFile.eRaise(e: longint);
begin
   Error := e;
end;

function ypkTFile.eGet(): longint;
begin
   result := error;
   Error := 0;
end;

procedure ypkTFile.eReset();
begin
   Error := 0;
end;

class procedure ypkTFile.Initialize(out ypkf: ypkTFile);
begin
   ZeroOut(ypkf, SizeOf(ypkf));
end;

class procedure ypkTFile.InitializeHeader(out hdr: ypkfTHeader);
begin
   ZeroOut(hdr, SizeOf(hdr));

   hdr.ID         := ypkID;
   hdr.Endian     := ypkENDIAN;
   hdr.Version    := ypkVERSION;
end;

{ HEADER }

procedure ypkTFile.ReadHeader(out hdr: ypkfTHeader);
begin
   f^.Read(hdr, SizeOf(hdr));

   if(f^.Error = 0) then begin
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

procedure ypkTFile.WriteHeader(const hdr: ypkfTHeader);
begin
   f^.Write(hdr, SizeOf(hdr));
end;

{ ENTRIES }

function ypkTFile.ReadEntries(var e: ypkfTEntries; count: longint): fileint;
begin
   e.Allocate(count);

   if(count > 0) then begin
      e.n := count;

      f^.Read(e.List[0], int64(count) * ypkENTRY_SIZE);
   end;

   Result := eNONE;
end;

procedure ypkTFile.WriteEntries(var e: ypkfTEntries);
begin
   if(e.n > 0) then
      f^.Write(e.List[0], int64(e.n) * ypkENTRY_SIZE);
end;

function ypkTFile.ReadEntries(var data: ypkTData): fileint;
begin
   Result := ReadEntries(data.Entries, data.Files);
end;

function ypkTFile.ReadBlob(out blob: PByte; size: fileint): fileint;
begin
   Result := 0;

   blob := nil;

   if(size > 0) then begin
      XGetMem(blob, size);

      Result := f^.Read(blob^, size);
   end;
end;

function ypkTFile.ReadBlob(var data: ypkTData): fileint;
begin
   Result := ReadBlob(data.Blob, data.BlobSize);
end;

function ypkTFile.WriteBlob(var blob: PByte; size: fileint): fileint;
begin
   Result := 0;

   if(size > 0) and (blob <> nil) then
      Result := f^.Write(blob^, size);
end;

END.
