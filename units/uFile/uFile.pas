{
   uFile, file operations and abstraction
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uFile;

INTERFACE

   USES
      sysutils, StringUtils, uStd, uError, uFileUtils, uThreads;

CONST
   {invalid handle for a file}
   fINVALID_HANDLE      = 0;

   {ERROR CONSTANTS}
   feOPENED             = $100; {cannot perform operation if file opened}
   feCLOSED             = $101; {cannot perform operation if file closed}
   feERROR_STATE        = $102; {file is in error state}
   feOPEN               = $103; {failed to open file}
   feNEW                = $104; {failed to create file}
   feSEEK               = $105; {failed seeking}
   feLAST_ERROR         = feSEEK; {last error}

   feSTRINGS: array[0..5] of string = (
      'File already opened',
      'File already closed',
      'File is in an error state',
      'Failed to open file',
      'Failed to create file',
      'Failed to seek'
   );

   {FILE OPERATION CONSTANTS}

   {FILE MODES}
   fcfNONE              = $0000; {no file mode specified}
   fcfREAD              = $0001; {read-only}
   fcfWRITE             = $0002; {write-only}
   fcfRW                = fcfREAD or fcfWRITE; {read and write}

TYPE
   {seek operations}
   fTSeekOperation = (
      fSEEK_SET, {seek from the position 0}
      fSEEK_CUR, {seek from the current position}
      fSEEK_END {seek from end}
   );


   {a custom file handler}
   PFileHandler = ^TFileHandler;
   PFile = ^TFile;

   fTHandle = int64;

   { TFile }

   TFile = record
      fn: StdString;
      fMode,
      fType,
      fNew: longword;
      Error,
      IoError: longint;

      fSize, {size of the file}
      fSizeLimit, {max limit to which the file can grow}
      fPosition, {currrent position in the file}
      fOffset, {file offset}
      bSize, {buffer size}
      bLimit, {buffer limit}
      bPosition: fileint; {buffer position}
      bExternal: boolean; {buffer is external (not allocated by us)}

      pData: pointer;
      bData: pbyte; {buffer data}
      pHandler: PFileHandler;
      HandlerProps: longword;

      LineEndings: TLineEndingType;
      LineEndingChars: StdString;

      {extra data}
      ExtData: pointer;
      Handle: fTHandle;
      HandleID: longint;
      pSub: PFile;

      procedure RaiseError(err: longint);
      procedure ErrorIgnore();
      function GetIOError(): longint;
      procedure ErrorReset();

      {GENERAL FILE OPERATIONS}

      function GetErrorString(): StdString;

      {set defaults for a file}
      procedure SetDefaults(const fileName: StdString);
      procedure SetDefaults(new: boolean; mode: longint; const fileName: StdString);
      {return the size of the file}
      function GetSize(): fileint;

      {dispose handler}
      procedure HandlerDispose();
      {dispose file}
      procedure Dispose();

      {get file descriptor (handle)}
      function GetFD(): int64;

      {FILE HANDLER}
      {assign a file handler to a file}
      procedure AssignHandler(var handler);

      {read an entire file into memory once it is opened, only works for reading mode}
      procedure ReadUp();
      {close a opened file}
      procedure Close();
      {close a opened file and dispose of the file data}
      procedure CloseAndDestroy();
      {set a file buffer}
      procedure Buffer(Size: fileint);
      {set an external file buffer}
      procedure ExternalBuffer(pBuffer: pointer; Size: fileint);
      {set a buffer using automatic settings}
      procedure AutoSetBuffer();
      {dispose a file buffer}
      procedure DisposeBuffer();

      {set the file mode}
      procedure SetMode(mode: longword);
      {set the line ending type}
      procedure SetLineEndings(ln: TLineEndingType);

      {READING AND WRITING}
      {read count bytes into buffer buf from file f}
      function Read(out buf; count: fileint): fileint;
      {write count bytes from buffer buf to file f}
      function Write(const buf; count: fileint): fileint;
      {flushes contents of buffer to the file if there is anything to write}
      procedure Flush();
      {a kludge used to read a line from a file, even a binary one}
      procedure Readln(out s: StdString);
      {a kludge used to read a shortstring line from a file, even a binary one}
      procedure Readln(out s: shortstring);
      {a kludge used to write a line to a file, even a binary one}
      procedure Writeln(const s: StdString);
      {a kludge used to write a shortstring line to a file, even a binary one}
      procedure Writeln(const s: shortstring);
      {write a string}
      procedure Write(const s: StdString);
      {get the entire file as a string}
      function GetString(): StdString;
      {seeks to a position in the file}
      function Seek(position: fileint): fileint;
      function Seek(position: fileint; mode: fTSeekOperation): fileint;
      {seek to start}
      procedure SeekStart();
      {checks if the file has reached the end}
      function EOF(): boolean;

      {read file as an array of strings}
      function ReadStrings(out strings: TStringArray): fileint;

      { ADDITIONAL }
      function ReadShortString(out s: shortstring): fileint;
      function ReadShortString(out s: ansistring): fileint;
      function WriteShortString(const s: shortstring): fileint;

      function ReadAnsiString(out s: ansistring): fileint;
      function WriteAnsiString(const s: ansistring): fileint;
   end;

   {routine types used by the file handler}

   { TFileHandler }

   TFileHandler = object
      Name: StdString;

      UseBuffering,
      DoReadUp: boolean;

      constructor Create();

      procedure Make(var f: TFile); virtual;
      procedure Dispose(var f: TFile); virtual;
      procedure Open(var f: TFile); virtual;
      procedure New(var f: TFile); virtual;
      function Read(var f: TFile; out buf; count: fileint): fileint; virtual;
      function Write(var f: TFile; const buf; count: fileint): fileint; virtual;
      function Seek(var f: TFile; pos: fileint): fileint; virtual;
      procedure Destroy(var f: TFile); virtual;
      procedure Close(var f: TFile); virtual;
      procedure Flush(var f: TFile); virtual;
      procedure OnBufferSet(var f: TFile); virtual;
   end;


{$IFNDEF FILE_NOFS}
   PVFileSystem = ^TVFileSystem;
   TVFileSystem = record
      Name: StdString;
      FileInFS: function(const path: StdString): fileint;
      OpenFile: function(var f: TFile; const fn: StdString): boolean;
      NewFile: function(var f: TFile; const fn: StdString): boolean;

      Next: PVFileSystem;
   end;
{$ENDIF}

   {specific handlers}
   PFileStdHandler = ^TFileStdHandler;
   TFileStdHandler = record
      Handler: PFileHandler;
   end;

   PFileMemHandler = ^TFileMemHandler;
   TFileMemHandler = record
      Handler: PFileHandler;

      Open: procedure(var f: TFile; mem: pointer; size: fileint);
      New: procedure(var f: TFile; size: fileint);
   end;

   PFileSubHandler = ^TFileSubHandler;
   TFileSubHandler = record
      Handler: PFileHandler;

      Open: procedure(var f: TFile; var fn: TFile; pos, size: fileint);
      New: procedure(var f: TFile; var fn: TFile; pos, size: fileint);
   end;

   { TFileGlobal }

   TFileGlobal = record
      {BUFFER SETTINGS}
      {minimal size of the buffer}
      MinimumBufferSize,
      {size of buffer used for copying files}
      CopyBufferSize: fileint;
      {automatically set buffer for each file}
      AutoSetBuffer: boolean;
      {auto set buffer size}
      AutoSetBufferSize: fileint;
      {use a shared buffer for files in a thread}
      UseSharedBuffer: boolean;

      LineEndings: TLineEndingType;

      {error variables}
      DummyHandler: TFileHandler;
      ZeroFile: TFile;

      {$IFNDEF FILE_NOFS}
      dummyFS: TVFileSystem;
      {$ENDIF}

      Handlers: record
         Std: PFileStdHandler;
         Mem: PFileMemHandler;
         Sub: PFileSubHandler;
      end;

      {ERROR SUPPORT}
      class procedure ErrorReset(); static;
      class function GetErrorString(code: longint; io: longint = -1): StdString; static;

      {FILE OPERATIONS}

      {checks whether a file exists, returns filesize if the file exists, or -1 on error}
      function Exists(const fn: StdString): fileint;

      {GENERAL}
      procedure Init(out f: TFile);
      procedure Init(out h: TFileHandler);

      { FILESYSTEM }
      {$IFNDEF FILE_NOFS}
      procedure fsInit(var fs: TVFileSystem);
      procedure fsAdd(var fs: TVFileSystem);
      function fsExists(const fn: StdString): fileint;
      function fsOpen(var f: TFile; const fn: StdString): boolean;
      {$ENDIF}
   end;

VAR
   fFile: TFileGlobal;

IMPLEMENTATION

THREADVAR
   SharedBuffer: Pointer;

{ TFileHandler }

{$PUSH}{$WARN 5024 off : Parameter "$1" not used}

constructor TFileHandler.Create();
begin
   Name := 'unknown';
end;

procedure TFileHandler.Make(var f: TFile);
begin

end;

procedure TFileHandler.Dispose(var f: TFile);
begin

end;

procedure TFileHandler.Open(var f: TFile);
begin

end;

procedure TFileHandler.New(var f: TFile);
begin

end;

function TFileHandler.Read(var f: TFile; out buf; count: fileint): fileint;
begin
   Result := 0;
end;

function TFileHandler.Write(var f: TFile; const buf; count: fileint): fileint;
begin
   Result := 0;
end;

function TFileHandler.Seek(var f: TFile; pos: fileint): fileint;
begin
   Result := pos;
end;

procedure TFileHandler.Destroy(var f: TFile);
begin

end;

procedure TFileHandler.Close(var f: TFile);
begin

end;

procedure TFileHandler.Flush(var f: TFile);
begin

end;

procedure TFileHandler.OnBufferSet(var f: TFile);
begin

end;

{$POP}

{ERROR HANDLING}

class procedure TFileGlobal.ErrorReset();
begin
   ioErrorIgn();
   ioE := 0;
end;

class function TFileGlobal.GetErrorString(code: longint; io: longint): StdString;
begin
   if(code < feOPENED) then
      Result := GetErrorCodeString(code)
   else if(code >= feOPENED) and (code <= feLAST_ERROR) then
      Result := '[' + sf(code) + '] ' + feSTRINGS[code - feOPENED]
   else
      Result := '';

   if(io <> -1) then
      Result := Result + ' : [' + sf(io) + '] ' + getRunTimeErrorDescription(io);
end;

{ FILE ERROR HANDLING }
procedure TFile.RaiseError(err: longint);
begin
   error := err;
end;


procedure TFile.ErrorIgnore();
begin
   error    := 0;
   IoError  := 0;
   IOResult();
end;

function TFile.GetIOError(): longint;
begin
   IoError := IOResult;

   if(IoError = 0) then
      exit(0)
   else
      error := eIO;

   Result := IoError;
end;

procedure TFile.ErrorReset();
begin
   error    := 0;
   IoError  := 0;
end;

function TFile.GetErrorString(): StdString;
begin
   Result := fFile.GetErrorString(error);
end;


{GENERAL FILE OPERATIONS}

procedure TFile.SetDefaults(const fileName: StdString);
begin
   fPosition      := 0;
   bPosition      := 0;
   bLimit         := 0;
   fSizeLimit     := 0;
   fSize          := 0;
   fn             := fileName;
end;

procedure TFile.SetDefaults(new: boolean; mode: longint; const fileName: StdString);

begin
   if(new) then
      fNew  := 1
   else
      fNew  := 0;

   fMode := mode;
   SetDefaults(fileName);
end;

function TFile.GetSize(): fileint;
begin
   Result := fSize;
end;

procedure TFile.HandlerDispose();
begin
   if(pHandler <> nil) and (pData <> nil) then begin
      pHandler^.Destroy(Self);
      pData := nil;
   end;
end;

procedure TFile.Dispose();
begin
   DisposeBuffer();
   HandlerDispose();
end;


function TFile.GetFD(): int64;
begin
   Result := handle;
end;

{assign a file handler to a file}
procedure TFile.AssignHandler(var handler);
begin
   HandlerDispose();

   pHandler := @handler;
   TFileHandler(handler).Make(Self);
end;

{read an entire file into memory once it is opened, only works for reading mode}
procedure TFile.ReadUp();
var
   doReadUp: boolean;

begin
   ErrorReset();

   if(pHandler <> nil) then
      doReadUp := pHandler^.doReadUp
   else
      doReadUp := true;

   if(doReadUp = true) then begin
      Buffer(fSize);

      if(error = 0) then begin
         SeekStart();

         if(error = 0) then begin
            Read(bData^, fSize);
            fPosition := 0;
            bPosition := 0;
         end;
      end;
   end;
end;

{close a opened file}
procedure TFile.Close();
begin
   Flush();

   SeekStart();

   if(pHandler <> nil) then
      pHandler^.Close(Self);

   HandlerDispose();
end;

procedure TFile.CloseAndDestroy();
begin
   Close();
   Dispose();
end;

{dispose a file buffer}
procedure TFile.DisposeBuffer();
begin
   Flush();

   if(not bExternal) then begin
      XFreeMem(bData);
      bSize := 0;

      if(pHandler <> nil) then
         pHandler^.onbufferset(Self);
   end;
end;

{set a file buffer}
procedure TFile.Buffer(Size: fileint);
begin
   if(Size > 0) and (fMode <> fcfRW) then begin
      bExternal := false;
      if(Size < fFile.MinimumBufferSize) then
         Size := fFile.MinimumBufferSize;

      DisposeBuffer();
      GetMem(bData, Size);
      if(bData <> nil) then begin
         bSize       := Size;
         bPosition   := 0;
         bLimit      := 0;
      end else begin
         RaiseError(eNO_MEMORY);
         exit();
      end;

      pHandler^.onbufferset(Self);
   end else
      DisposeBuffer();
end;

procedure TFile.ExternalBuffer(pBuffer: pointer; Size: fileint);
begin
   if(Size > 0) and (fMode <> fcfRW) then begin
      DisposeBuffer();

      bExternal := true;
      bData := pBuffer;
      bPosition := 0;
      bLimit := 0;
      bSize := Size;
      pHandler^.onbufferset(Self);
   end;
end;

procedure TFile.AutoSetBuffer();
begin
   if(fFile.UseSharedBuffer) then begin
      if(SharedBuffer = nil) then
         GetMem(SharedBuffer, fFile.AutoSetBufferSize);

      ExternalBuffer(SharedBuffer, fFile.AutoSetBufferSize);
   end else begin
      if(fFile.AutoSetBuffer) then
         Buffer(fFile.AutoSetBufferSize);
   end;
end;

{set the file mode}
procedure TFile.SetMode(mode: longword);
begin
   fMode := mode;
end;

procedure TFile.SetLineEndings(ln: TLineEndingType);
begin
   LineEndings := ln;
   LineEndingChars := ln.GetChars();
end;

{READING AND WRITING}
{read count bytes into buffer buf from file f}
function TFile.Read(out buf; count: fileint): fileint;
var
   bRead: fileint; {how much was read, how much is left in buffer}

begin
   if(fMode and fcfREAD > 0) then begin
      if(fSizeLimit <> 0) then begin
         if(fSizeLimit + 1 < fPosition + count) then
            count := fSizeLimit - fPosition;
      end else begin
         if(fSize < fPosition + count) then
            count := fSize - fPosition;
      end;

      bRead := pHandler^.Read(Self, buf, count);
      if(error = 0) then
         inc(fPosition, bRead);

      Result := bRead;
   end else begin
      RaiseError(eREAD);
      Result := -1;
   end;
end;

function TFile.Write(const buf; count: fileint): fileint;
var
   bWrite: fileint;

begin
   if(fMode and fcfWRITE > 0) then begin
      if(fSizeLimit <> 0) then begin
         if(fSizeLimit < fPosition + count) then
            count := fSize - fPosition;
      end;

      bWrite := pHandler^.Write(Self, buf, count);
      if(error = 0) then
         inc(fPosition, bWrite);

      Result := bWrite;
   end else begin
      RaiseError(eWRITE);
      Result := -1;
   end;
end;

procedure TFile.Flush();
begin
   {does the file have a buffer}
   if(bSize > 0) and (bPosition > 0) and (fMode = fcfWRITE) then
      pHandler^.flush(Self);
end;

procedure TFile.Readln(out s: StdString);
var
   c: char = #0;
   chars: longint = 0;
   count: fileint = 0;

begin
   s := '';
   chars := 0;

   repeat
      count := Read(c, 1);

      if(error = 0) and (count > 0) then begin
         if(c = #10) then
            break;

         if (c <> #13) then begin
            inc(chars);
            SetLength(s, chars);
            s[chars] := c;
         end;
      end else
         break;
   until (c = #10);
end;

procedure TFile.Readln(out s: shortstring);
var
   c: char = #0;
   chars: longint = 0;
   count: fileint = 0;

begin
   s := '';
   chars := 0;

   repeat
      count := Read(c, 1);

      if(error = 0) and (count > 0) then begin
         if(c = #10) then
            break;

         if (c <> #13) then begin
            inc(chars);
            SetLength(s, chars);
            s[chars] := c;
         end;
      end else
         break;
   until (c = #10);
end;

procedure TFile.Writeln(const s: StdString);
var
   len: fileint;

begin
   len := Length(s);

   {write string contents}
   if(len > 0) then
      Write(s[1], len);

   {write line ending}
   Write(LineEndingChars[1], Length(LineEndingChars));
end;

procedure TFile.Writeln(const s: shortstring);
var
   len: fileint;

begin
   len := Length(s);

   {write string contents}
   if(len > 0) then
      Write(s[1], len);

   {write line ending}
   Write(LineEndingChars[1], Length(LineEndingChars));
end;

procedure TFile.Write(const s: StdString);
var
   len: fileint;

begin
   len := Length(s);

   {write string contents}
   if(len > 0) then
      Write(s[1], len);
end;

function TFile.GetString(): StdString;
begin
   ReadUp();

   if(fSize > 0) and (bSize > 0) then
      StringFromBytes(Result, fSize, bData^)
   else
      Result := '';
end;

function TFile.Seek(position: fileint): fileint;
begin
   Result := -1;

   if(position <= fSize) then begin
      Result := pHandler^.Seek(Self, position);

      if(error = 0) then begin
         fPosition   := position;
         bPosition   := 0; {invalidate buffer}
         bLimit      := 0;
      end;
   end;
end;

function TFile.Seek(position: fileint; mode: fTSeekOperation): fileint;
begin
   case mode of
      fSEEK_SET: Result := Seek(Position);
      fSEEK_CUR: Result := Seek(fPosition + Position);
      fSEEK_END: Result := Seek(fSize - Position);
      else
         Result := -1;
   end;

   system.writeln('SeekResult: ', Result);
end;

procedure TFile.SeekStart();
begin
   if(fPosition <> 0) then
      Seek(0);
end;

function TFile.EOF(): boolean;
begin
   Result := (fPosition >= fSize) or not((fPosition - bPosition) < fSize);
end;

function TFile.ReadStrings(out strings: TStringArray): fileint;
var
   list: TSimpleStringList;
   currentLine: StdString = '';
   i: loopint;

begin
   ZeroPtr(@list, SizeOf(list));

   list.Increment := 1024;
   strings := nil;

   if(GetSize() > 0) then begin
      repeat
         Readln(currentLine);
         list.Add(currentLine);
      until EOF();
   end;

   Result := Error;

   if(list.n > 0) then begin
      SetLength(strings,  list.n);
      for i := 0 to list.n - 1 do begin
         strings[i] := list.List[i];
      end;
   end;

   list.Dispose();
end;

{ ADDITIONAL }

function TFile.ReadShortString(out s: shortstring): fileint;
var
   len: byte         = 0;
   bRead: fileint    = 0;

begin
   s := '';

   {read string length}
   bRead := Read(len, SizeOf(len));
   if(error = 0) then begin
      SetLength(s, len);

      if(len > 0) then
         {read string contents}
         inc(bRead, Read(s[1], len));
   end;

   Result := bRead;
end;

function TFile.ReadShortString(out s: ansistring): fileint;
var
   len: byte         = 0;
   bRead: fileint    = 0;

begin
   s := '';

   {read string length}
   bRead := Read(len, SizeOf(len));
   if(error = 0) then begin
      SetLength(s, len);

      if(len > 0) then
         {read string contents}
         inc(bRead, Read(s[1], len));
   end;

   Result := bRead;
end;

function TFile.WriteShortString(const s: shortstring): fileint;
begin
   Result := Write(s, int64(Length(s)) + int64(1));
end;

function TFile.ReadAnsiString(out s: ansistring): fileint;
var
   len: longint = 0;
   bread: fileint;

begin
   s := '';

   {read string length}
   bRead := Read(len, SizeOf(len));
   if(error = 0) then begin
      SetLength(s, len);

      if(len > 0) then
         {read string contents}
         inc(bRead, Read(s[1], len));
   end;

   Result := bRead;
end;

function TFile.WriteAnsiString(const s: ansistring): fileint;
var
   len: longint;
   bWrote: fileint;

begin
   len := Length(s);
   {write string length}
   bWrote := Write(len, SizeOf(len));

   {write string contents}
   if(error = 0) and (len > 0) then
      inc(bWrote, Write(s[1], len));

   Result := bWrote;
end;


{FILE OPERATIONS}

function TFileGlobal.Exists(const fn: StdString): fileint;
begin
   Result := FileUtils.Exists(fn);

   {$IFNDEF FILE_NOFS}
(*   if(Result = -1) then
      Result := fsExists(fn);*)
   {$ENDIF}
end;

{GENERAL}
procedure TFileGlobal.Init(out f: TFile);
begin
   ZeroPtr(@f, SizeOf(f));
   f.pHandler := @DummyHandler;
   f.handleID := -1;
   f.SetLineEndings(fFile.LineEndings);
end;

procedure TFileGlobal.Init(out h: TFileHandler);
begin
   h := DummyHandler;
end;

{DUMMY FILE HANDLER}

procedure InitFileHandlers();
begin
   {dummy file handler}
   fFile.DummyHandler.Create();
   fFile.DummyHandler.Name          := 'Dummy';
end;

{ FileSystem }
{$IFNDEF FILE_NOFS}
VAR
   FileSystem: record
      s,
      e: PVFileSystem;
   end;

procedure TFileGlobal.fsInit(var fs: TVFileSystem);
begin
   fs := dummyFS;
end;

procedure TFileGlobal.fsAdd(var fs: TVFileSystem);
begin
   fs.Next := nil;

   if(FileSystem.s = nil) then
      FileSystem.s := @fs
   else
      FileSystem.e^.Next := @FileSystem.s;

   FileSystem.e := @fs;
end;

function TFileGlobal.fsExists(const fn: StdString): fileint;
var
   cur: PVFileSystem;
   res: fileint;

begin
   cur := FileSystem.s;

   if(cur <> nil) then repeat
      res := cur^.FileInFS(fn);
      if(res > -1) then
         exit(res);

      cur := cur^.Next;
   until (cur = nil);

   Result := -1;
end;

function TFileGlobal.fsOpen(var f: TFile; const fn: StdString): boolean;
var
   cur: PVFileSystem;

begin
   cur := FileSystem.s;

   if(cur <> nil) then repeat
      if(cur^.FileInFS(fn) > -1) then
         exit(cur^.OpenFile(f, fn));

      cur := cur^.Next;
   until (cur = nil);

   Result := false;
end;

{ DUMMY FS }
{$PUSH}{$HINTS OFF}

{since these are dummy routines most parameters are unused}
function dumFileInFS(const path: StdString): fileint;
begin
   Result := -1;
end;

function dumOpenFile(var f: TFile; const fn: StdString): boolean;
begin
   Result := false;
end;

function dumNewFile(var f: TFile; const fn: StdString): boolean;
begin
   Result := false;
end;

{$POP}
{$ENDIF}

procedure threadInitializer();
begin
   SharedBuffer := nil;
end;

INITIALIZATION
   {$IFNDEF FILE_NOFS}
   fFile.dummyFS.FileInFS     := @dumFileInFS;
   fFile.dummyFS.OpenFile     := @dumOpenFile;
   fFile.dummyFS.NewFile      := @dumNewFile;
   {$ENDIF}

   InitFileHandlers();

   fFile.Init(fFile.ZeroFile);

   {BUFFER SETTINGS}
   fFile.MinimumBufferSize := 1 * 1024;
   fFile.CopyBufferSize := 32 * 1024;
   fFile.AutoSetBuffer := True;
   fFile.AutoSetBufferSize := fFile.MinimumBufferSize;
   fFile.UseSharedBuffer := False;
   fFile.LineEndings := PLATFORM_LINE_ENDINGS;
   threadInitializer();

   Threads.GetHandlerIndex(@threadInitializer);

END.
