{
   ypkuFS, YPAK file system
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ypkuFS;

INTERFACE

   USES
      uStd, ufhStandard, {$IFDEF UNIX}BaseUnix, ufhUnix, {$ENDIF}
      uLog, StringUtils,
      uFileUtils, uFile, {%H-}uFiles, ufhSub, uyPakFile;

TYPE
   ypkPFSFile = ^ypkTFSFile;

   { ypkTFSFile }

   ypkTFSFile = record
      f: TFile;
      {ypk file handler}
      ypkf: ypkTFile;
      {blob size}
      BlobSize: fileint;
      {blob memory containing file names}
      Blob: PByte;
      {ypk entries}
      Entries: ypkfTEntries;

      {correct file path separators for all entries}
      procedure CorrectPaths();
      {get file name for entry specified by index}
      function GetFn(index: loopint): PShortString;
      {finds a file with the specified name in the entries}
      function Find(var e: ypkfTEntries; const fn: string): longint;
   end;

   { ypkTFileSystemGlobal }

   ypkTFileSystemGlobal = record
      {default buffer size set for fs files, 0 means no buffer}
      BufferSize: fileint;
      {correct file paths when a file is added to the filesystem}
      CorrectPaths: boolean;

      vfsh: PFileHandler;
      vfs: TVFileSystem;

      {add a file to the vfs file list}
      function Add(const fn: StdString): ypkPFSFile;
      {add a file to the vfs file list}
      function Add(var f: TFile): ypkPFSFile;
      {$IFDEF UNIX}
      function Add(d: cint; offs, size: fileint): ypkPFSFile;
      {$ENDIF}
      {add a pool of ypk files to the vfs file list}
      procedure AddPool(const fn: StdString);
      {mount and unmount the filesystem}
      procedure Mount();
      procedure Unmount();

      {disposes of the entire pool}
      procedure DisposePool();

      { UTILITIES }
      {find a file inside the filesystem and return a pointer to the corresponding ypk fs}
      function Find(const fn: StdString; out entryIdx: longint): ypkPFSFile;
      {finds a file inside the filesystem and stores its information, returns true if found, false if not}
      function Find(const fn: StdString; var offs, size: fileint): boolean;
      {finds the ypk file which contains the specified file by it's name}
      function GetFS(const fn: StdString): ypkPFSFile;

      {returns the number of files total in a single fs file}
      function FileCount(var fs: ypkTFSFile): longint;
      {returns the number of files total in the FS}
      function FileCount(): longint;
   end;

VAR
   ypkfs: ypkTFileSystemGlobal;

IMPLEMENTATION

CONST
   tag = 'ypkvfs > ';

TYPE
   ypkTFilesystem = specialize TSimpleList<ypkPFSFile>;

VAR
   filesystem: ypkTFilesystem;

procedure writeLog(var fs: ypkTFSFile; const s: StdString);
var
   e: StdString;

begin
   e := 'ypkError: ' + sf(fs.ypkf.Error) + ', fError: ' + fs.f.GetErrorString();

   if(ioE <> 0) then
      e := e + ', ioE:' + sf(ioE);

   log.e(tag + 'Error (' + e + '): ' + fs.f.fn);

   if(s <> '') then
      log.e('Description: ' + s);
end;

procedure InitFSFile(var fs: ypkTFSFile);
begin
   ZeroOut(fs, SizeOf(fs));
   fFile.Init(fs.f);

   fs.ypkf.Initialize(fs.ypkf);
   fs.ypkf.f := @fs.f;
end;

function getFile(): longint;
var
   f: ypkPFSFile = nil;

begin
   Result := -1;

   New(f);

   {get an index to a fs pointer}
   filesystem.Add(f);
   InitFSFile(f^);

   Result := filesystem.n - 1;
end;

function ypkfsAdd(var fs: ypkTFSFile): ypkPFSFile;
var
   hdr: ypkfTHeader;

begin
   Result := nil;

   fs.ypkf.ReadHeader(hdr);

   if(fs.f.Error <> 0) then begin
      writeLog(fs, 'Failed reading ypk header.');
      exit(nil);
   end;

   if(fs.ypkf.Error <> 0) then begin
      writeLog(fs, 'Invalid ypk header.');
      exit(nil);
   end;

   fs.ypkf.ReadBlob(fs.Blob, fs.BlobSize);
   fs.ypkf.ReadEntries(fs.Entries, hdr.Files);

   if(fs.f.Error = 0) then begin
      Result := @fs;

      log.i(tag + 'Loaded file successfully: ' + fs.f.fn +
         ', files: ' + sf(hdr.Files) + ', offs: ' + sf(fs.f.fOffset) + ', size: ' + sf(fs.f.fSize) + ')');
   end else
      writeLog(fs, 'Cannot read blob or entries.')
end;

function ypkTFileSystemGlobal.Add(const fn: StdString): ypkPFSFile;
var
   fsidx: longint;
   fs: ypkPFSFile;

begin
   Result := nil;

   if(fn <> '') then begin
      fsidx := getFile();

      if(fsidx > -1) then begin
         fs := filesystem.List[fsidx];

         {open the file}
         fs^.f.Open(fn);

         if(fs^.f.Error = 0) then begin
            if(BufferSize > 0) then
               fs^.f.Buffer(BufferSize);

            Result := ypkfsAdd(fs^)
         end else
            writeLog(fs^, 'Cannot open file.')
      end;
   end;
end;

function ypkTFileSystemGlobal.Add(var f: TFile): ypkPFSFile;
var
   fsidx: longint;
   fs: ypkPFSFile;

begin
   Result := nil;

   fsidx := getFile();

   if(fsidx > -1) then begin
      fs := filesystem.List[fsidx];

      {set the file}
      fs^.f := f;

      if(fs^.f.Error = 0) then begin
         if(BufferSize > 0) then
            fs^.f.Buffer(BufferSize);

         Result := ypkfsAdd(fs^);
      end else
         writeLog(fs^, 'Given ypks file already has an error: ' + fs^.f.GetErrorString())
   end else
      log.e('Cannot get an ypkfs file in the list');
end;

{$IFDEF UNIX}
function ypkTFileSystemGlobal.Add(d: cint; offs, size: fileint): ypkPFSFile;
var
   fsidx: longint;
   fs: ypkPFSFile;

begin
   Result := nil;

   fsidx := getFile();

   if(fsidx > -1) then begin
      fs := filesystem.List[fsidx];

      {open the file}
      fOpenUnix(fs^.f, d, offs, size);

      if(fs^.f.Error = 0) then begin
         Result := ypkfsAdd(fs^);
      end else
         writeLog(fs^, 'Cannot open file.')
   end;
end;

{$ENDIF}

procedure ypkTFileSystemGlobal.AddPool(const fn: StdString);
begin
   if(fn <> '') then begin
   end;
end;

procedure ypkTFileSystemGlobal.Mount();
var
   i: longint;

begin
   {initialize filesystem}
   if(filesystem.n > 0) then begin
      for i := 0 to (filesystem.n - 1) do begin
         if(filesystem.List[i] <> nil) then
            filesystem.List[i]^.f.Buffer(fFile.MinimumBufferSize);
      end;
   end;

   if(filesystem.n > 0) then
      log.i(tag + 'Filesystem successfully mounted.')
   else
      log.i(tag + 'Filesystem not mounted. No files.')
end;

procedure ypkTFileSystemGlobal.Unmount();
var
   i: longint;

begin
   {close all files}
   if(filesystem.n > 0) then begin
      for i := 0 to (filesystem.n -1 ) do begin
         if(filesystem.List[i] <> nil) then
            if(filesystem.List[i]^.f.fMode <> fcfNONE) then
               filesystem.List[i]^.f.Close();
      end;
   end;

   {dispose of pool}
   DisposePool();

   log.i(tag + 'Filesystem successfully unmounted.');
end;

procedure ypkTFileSystemGlobal.DisposePool();
var
   i: longint;

begin
   if(filesystem.n > 0) then begin
      for i := 0 to (filesystem.n - 1) do begin
         if(filesystem.List[i] <> nil) then begin
            filesystem.List[i]^.f.Dispose();

            Dispose(filesystem.List[i]);
            filesystem.List[i] := nil;
         end;
      end;
   end;

   filesystem.Dispose();
end;

{ HANDLER }
{checks whether the specified file can be found in the filesystem}
function finFS(const fn: StdString): fileint;
var
   entryIdx: longint;
   fs: ypkPFSFile;

begin
   fs := ypkfs.Find(fn, entryIdx);

   if(entryIdx > -1) then
      Result := fs^.Entries.List[entryIdx].Size
   else
      Result := -1;
end;

function OpenFile(var f: TFile; const fn: StdString): boolean;
var
   entry: ypkfPEntry;
   entryIdx: longint;
   fs: ypkPFSFile;

begin
   Result := false;

   fs := ypkfs.Find(fn, entryIdx);

   if(entryIdx > -1) then begin
      entry := @fs^.Entries.List[entryIdx].Offset;

      f.Open(fs^.f, entry^.Offset, entry^.Size);

      if(fs^.f.error = 0) then
         Result := fs^.f.Seek(entry^.Offset) > -1;
   end;
end;

{ UTILITIES }
function ypkTFileSystemGlobal.Find(const fn: StdString; var offs, size: fileint): boolean;
var
   fs: ypkPFSFile;
   entryIdx: longint;

begin
   fs := Find(fn, entryIdx);

   if(entryIdx > -1) then begin
      offs := fs^.Entries.List[entryIdx].Offset;
      size := fs^.Entries.List[entryIdx].Size;
      exit(true);
   end;

   Result := false;
end;

function ypkTFileSystemGlobal.Find(const fn: StdString; out entryIdx: longint): ypkPFSFile;
var
   i: longint;

begin
   entryIdx := -1;
   Result := nil;

   if(filesystem.n > 0) then begin
      for i := (filesystem.n - 1) downto 0 do begin
         if(filesystem.List[i] <> nil) then begin
            entryIdx := filesystem.List[i]^.Find(filesystem.List[i]^.Entries, fn);

            if(entryIdx > -1) then
               exit(filesystem.List[i]);
         end;
      end;
   end;
end;

function ypkTFileSystemGlobal.GetFS(const fn: StdString): ypkPFSFile;
var
   entryIdx: longint;
   fs: ypkPFSFile;

begin
   fs := Find(fn, entryIdx);

   if(entryIdx > -1) then
      exit(fs);

   Result := nil;
end;

function ypkTFileSystemGlobal.FileCount(var fs: ypkTFSFile): longint;
begin
   Result := fs.Entries.n;
end;

function ypkTFileSystemGlobal.FileCount(): longint;
var
   i,
   count: longint;

begin
   count := 0;

   if(filesystem.n > 0) then
      for i := 0 to (filesystem.n - 1) do begin
         if(filesystem.List[i] <> nil) then
            inc(count, filesystem.List[i]^.Entries.n);
      end;

   Result := 0;
end;

{ ypkTFSFile }

procedure ypkTFSFile.CorrectPaths();
begin
   {TODO: Implement file path correction}
end;

function ypkTFSFile.GetFn(index: loopint): PShortString;
begin
   Result := @EmptyShortString;

   if(index >= 0) and (index < Entries.n) then begin
      Result := PShortString(Blob + ptrint(Entries.List[index].FileNameOffset));
   end;
end;

function ypkTFSFile.Find(var e: ypkfTEntries; const fn: string): longint;
var
   i: longint;

begin
   if(e.n > 0) then
      for i := 0 to (e.n-1) do begin
         if(GetFN(i)^ = fn) then
            exit(i);
      end;

   Result := -1;
end;

INITIALIZATION
   ypkfs.CorrectPaths := true;
   ypkfs.BufferSize := 8192;
   fFile.fsInit(ypkfs.vfs);
   ypkfs.vfsh := @subfHandler;

   ypkfs.vfs.Name             := 'ypkVFS';
   ypkfs.vfs.FileInFS         := @finFS;
   ypkfs.vfs.OpenFile         := @OpenFile;

   fFile.fsAdd(ypkfs.vfs);

   {initialize filesystem}
   filesystem.InitializeValues(filesystem);

FINALIZATION
   ypkfs.DisposePool();

END.
