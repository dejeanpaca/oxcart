{
   ypkuFS, YPAK file system
   Copyright (C) 2011. Dejan Boras

   Started On:    06.03.2011.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT ypkuFS;

INTERFACE

   USES uStd, ufhStandard, {$IFDEF UNIX}BaseUnix, uFileUnix, {$ENDIF}
      uLog, StringUtils,
      uFileUtils, uFile, {%H-}uFiles, ufhSub, uyPak;

TYPE
   ypkPFSFile = ^ypkTFSFile;

   { ypkTFSFile }

   ypkTFSFile = record
      f: TFile;
      entries: ypkTEntries;

      procedure CorrectPaths();
   end;

   ypkTFileSystemGlobal = record
      {default buffer size set for fs files, 0 means no buffer}
      bufferSize: fileint;
      {correct file paths when a file is added to the filesystem}
      correctPaths: boolean;

      vfsh: PFileHandler;
      vfs: TVFileSystem;

      {add a file to the vfs file list}
      function Add(const fn: string): ypkPFSFile;
      {$IFDEF UNIX}
      function Add(d: cint; offs, size: fileint): ypkPFSFile;
      function Add(handleID: longint; d: cint; offs, size: fileint): ypkPFSFile;
      {$ENDIF}
      {add a pool of ypk files to the vfs file list}
      procedure AddPool(const fn: string);
      {mount and unmount the filesystem}
      procedure Mount();
      procedure Unmount();

      {disposes of the entire pool}
      procedure DisposePool();

      { UTILITIES }
      {find a file inside the filesystem and return a pointer to the corresponding ypk fs}
      function Find(const fn: string; out entryIdx: longint): ypkPFSFile;
      {finds a file inside the filesystem and stores its information, returns true if found, false if not}
      function Find(const fn: string; var offs, size: fileint): boolean;
      {finds the ypk file which contains the specified file by it's name}
      function GetFS(const fn: string): ypkPFSFile;

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
   ALLOCATE_STEP = 64;

TYPE
   ypkTFilesystem = specialize TPreallocatedArrayList<ypkPFSFile>;

VAR
   filesystem: ypkTFilesystem;

procedure writeLog(var fs: ypkTFSFile; const s: string);
var
   e: string;

begin
   e := 'ypkError: ' + sf(ypk.error) + ', fError:' + sf(fs.f.error);
   if(ioE <> 0) then
      e := e + ', ioE:' + sf(ioE);

   log.e(tag + 'Error(' + e + '): ' + fs.f.fn);
   if(s <> '') then
      log.e('Description: ' + s);
end;

procedure InitFSFile(var fs: ypkTFSFile);
begin
   ZeroOut(fs, SizeOf(fs));
   fInit(fs.f);
end;

function getFile(): longint;
var
   idx, pn, i: longint;

begin
   result := -1;

   {need to allocate more fs pointers}
   if(filesystem.nFiles >= filesystem.nAllocated) then begin
      pn := filesystem.nAllocated;

      inc(filesystem.nAllocated, ALLOCATE_STEP);
      {try to allocate memory}
      try
         SetLength(filesystem.files, filesystem.nAllocated);

         {initialize file pointers}
         for i := pn to (filesystem.nAllocated-1) do
            filesystem.files[i] := nil;
      except
         Exit;
      end;
   end;

   {get an index to a fs pointer}
   idx := filesystem.nFiles;
   inc(filesystem.nFiles);

   {allocate memory for that pointer}
   new(filesystem.files[idx]);
   if(filesystem.files[idx] <> nil) then begin
      InitFSFile(filesystem.files[idx]^);
      result := idx;
   end;
end;

function ypkfsAdd(var fs: ypkTFSFile): ypkPFSFile;
var
   hdr: ypkTHeader;

begin
   result := nil;

   ypk.ReadHeader(fs.f, hdr);
   if(fs.f.error = 0) then begin
      ypk.ReadEntries(fs.f, fs.entries, hdr.Files);

      if(fs.f.error = 0) then begin
         result := @fs;

         log.i(tag + 'Loaded file successfully: ' + fs.f.fn + '(handleID: ' + sf(fs.f.handleID) +
            ', files: ' + sf(hdr.Files) + ', offs: ' + sf(fs.f.fOffset) + ', size: ' + sf(fs.f.fSize) + ')');
      end else
         writeLog(fs, 'Cannot read entries.')
   end else
      writeLog(fs, 'Invalid or unsupported file header.')
end;

function ypkTFileSystemGlobal.Add(const fn: string): ypkPFSFile;
var
   fsidx: longint;
   fs: ypkPFSFile;

begin
   result := nil;

   if(fn <> '') then begin
      fsidx := getFile();

      if(fsidx > -1) then begin
         fs := filesystem.files[fsidx];

         {open the file}
         fs^.f.Open(fn);
         if(fs^.f.error = 0) then begin
            if(bufferSize > 0) then
               fs^.f.Buffer(bufferSize);

            result := ypkfsAdd(fs^)
         end else
            writeLog(fs^, 'Cannot open file.')
      end;
   end;
end;

{$IFDEF UNIX}
function ypkTFileSystemGlobal.Add(d: cint; offs, size: fileint): ypkPFSFile;
begin
   result := Add(-1, d, offs, size);
end;

function ypkTFileSystemGlobal.Add(handleID: longint; d: cint; offs, size: fileint): ypkPFSFile;
var
   fsidx: longint;
   fs: ypkPFSFile;

begin
   result := nil;

   fsidx := getFile();

   if(fsidx > -1) then begin
      fs := filesystem.files[fsidx];

      {open the file}
      fOpenUnx(fs^.f, d, offs, size);
      if(fs^.f.error = 0) then begin
         fs^.f.handleID := handleID;
         result := ypkfsAdd(fs^);
      end else
         writeLog(fs^, 'Cannot open file.')
   end;
end;

{$ENDIF}

procedure ypkTFileSystemGlobal.AddPool(const fn: string);
begin
   if(fn <> '') then begin
   end;
end;

procedure ypkTFileSystemGlobal.Mount();
var
   i: longint;

begin
   {initialize filesystem}
   if(filesystem.nFiles > 0) then
      for i := 0 to (filesystem.nFiles-1) do begin
         if(filesystem.files[i] <> nil) then
            filesystem.files[i]^.f.Buffer(fcMinimumBufferSize);
      end;

   if(filesystem.nFiles > 0) then
      log.i(tag+'Filesystem successfully mounted.')
   else
      log.i(tag+'Filesystem not mounted. No files.')
end;

procedure ypkTFileSystemGlobal.Unmount();
var
   i: longint;

begin
   {close all files}
   if(filesystem.nFiles > 0) then
   for i := 0 to (filesystem.nFiles-1) do begin
      if(filesystem.files[i] <> nil) then
         if(filesystem.files[i]^.f.fMode <> fcfNONE) then
            filesystem.files[i]^.f.Close();
   end;

   {dispose of pool}
   ypkTFileSystemGlobal.DisposePool();

   log.i(tag + 'Filesystem successfully unmounted.');
end;

procedure ypkTFileSystemGlobal.DisposePool();
var
   i: longint;

begin
   if(filesystem.nFiles > 0) then
      for i := 0 to (filesystem.nFiles-1) do begin
         if(filesystem.files[i] <> nil) then begin
            filesystem.files[i]^.f.Dispose();

            dispose(filesystem.files[i]);
            filesystem.files[i] := nil;
         end;
      end;

   SetLength(filesystem.files, 0);
   filesystem.nFiles       := 0;
   filesystem.nAllocated   := 0;
end;

{ HANDLER }
{checks whether the specified file can be found in the filesystem}
function finFS(const fn: string): fileint;
var
   entryIdx: longint;
   fs: ypkPFSFile;

begin
   fs := ypkfs.Find(fn, entryIdx);

   if(entryIdx > -1) then
      result := fs^.entries.e[entryIdx].size
   else
      result := -1;
end;

function OpenFile(var f: TFile; const fn: string): boolean;
var
   entry: ypkPEntry;
   entryIdx: longint;
   fs: ypkPFSFile;

begin
   result := false;

   fs := ypkfs.Find(fn, entryIdx);
   if(entryIdx > -1) then begin
      entry := @fs^.entries.e[entryIdx].offs;

      f.Open(fs^.f, entry^.offs, entry^.size);
      if(fs^.f.error = 0) then begin
         result := fs^.f.Seek(entry^.offs) > -1;
      end;
   end;
end;

{ UTILITIES }
function ypkTFileSystemGlobal.Find(const fn: string; var offs, size: fileint): boolean;
var
   fs: ypkPFSFile;
   entryIdx: longint;

begin
   fs := ypkTFileSystemGlobal.Find(fn, entryIdx);
   if(entryIdx > -1) then begin
      offs := fs^.entries.e[entryIdx].offs;
      size := fs^.entries.e[entryIdx].size;
      exit(true);
   end;

   result := false;
end;

function ypkTFileSystemGlobal.Find(const fn: string; out entryIdx: longint): ypkPFSFile;
var
   i: longint;

begin
   entryIdx := -1;

   if(filesystem.nFiles > 0) then
   for i := (filesystem.nFiles-1) downto 0 do begin
      if(filesystem.files[i] <> nil) then begin
         entryIdx := ypk.Find(filesystem.files[i]^.entries, fn);

         if(entryIdx > -1) then
            exit(filesystem.files[i]);
      end;
   end;
end;

function ypkTFileSystemGlobal.GetFS(const fn: string): ypkPFSFile;
var
   entryIdx: longint;
   fs: ypkPFSFile;

begin
   fs := ypkTFileSystemGlobal.Find(fn, entryIdx);

   if(entryIdx > -1) then
      exit(fs);

   result := nil;
end;

function ypkTFileSystemGlobal.FileCount(var fs: ypkTFSFile): longint;
begin
   result := fs.entries.n;
end;

function ypkTFileSystemGlobal.FileCount(): longint;
var
   i,
   count: longint;

begin
   count := 0;

   if(filesystem.nFiles > 0) then
      for i := 0 to (filesystem.nFiles-1) do begin
         if(filesystem.files[i] <> nil) then
            inc(count, filesystem.files[i]^.entries.n);
      end;

   result := 0;
end;

{ ypkTFSFile }

procedure ypkTFSFile.CorrectPaths();
begin

end;

INITIALIZATION
   ypkfs.correctPaths := true;
   ypkfs.bufferSize := 8192;
   fsInit(ypkfs.vfs);
   ypkfs.vfsh:= @subfHandler;

   ypkfs.vfs.Name             := 'ypkVFS';
   ypkfs.vfs.FileInFS         := @finFS;
   ypkfs.vfs.OpenFile         := @OpenFile;

   fsAdd(ypkfs.vfs);

   {initialize filesystem}
   filesystem.nFiles       := 0;
   filesystem.nAllocated   := 0;

FINALIZATION
   ypkfs.DisposePool();
END.
