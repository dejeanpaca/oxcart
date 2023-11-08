{
   uFileUtils, file utilities
   Copyright (C) 2013. Dejan Boras

   Started On:    01.11.2013.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT uFileUtils;

INTERFACE

   USES
      sysutils,
      uStd, StringUtils;

CONST
   eFILE_ERROR                         = -1;
   eFILE_OPEN                          = -2;
   eFILE_READ                          = -3;
   eFILE_WRITE                         = -4;

   eFILE_COPY_OPEN_SOURCE              = -5;
   eFILE_COPY_CREATE_DESTINATION       = -6;
   eFILE_COPY_READ_SOURCE              = -7;
   eFILE_COPY_WRITE_DESTINATION        = -8;

   {skip parent directory link (.. files)}
   FILE_FIND_ALL_SKIP_PARENT_DIRECTORY_LINK  = $1;
   {find only directories}
   FILE_FIND_ALL_ONLY_DIRECTORIES            = $2;
   {find hidden files and directories}
   FILE_FIND_ALL_HIDDEN                      = $4;

   { EXTENDED ATTRIBUTES }

   {does the directory contain other directories (sub-directories)}
   faContainsDirectories            = $00080000;
   {did we determine the above state already}
   faContainsDirectoriesDetermined  = $00100000;

   {$IFDEF WINDOWS}
   {work around faHidden not portable warning}
   faHiddenWindows = $00000002;
   {$ENDIF}

TYPE
   TFilePathType = (
      PATH_TYPE_NON_EXISTENT,
      PATH_TYPE_FILE,
      PATH_TYPE_DIRECTORY
   );

TYPE
   {describes a file}
   PFileDescriptor = ^TFileDescriptor;

   { TFileDescriptor }

   TFileDescriptor = record
      {file name}
      Name: StdString;
      {last modification time}
      Time: LongInt;
      {file size}
      Size: Int64;
      {file attributes}
      Attr: TBitSet;

      {tells whether this is a directory}
      function IsDirectory(): boolean;
      {tells whether this is a file}
      function IsFile(): boolean;
      {is the file a hidden file}
      function IsHidden(): boolean;

      procedure From(const s: TSearchRec);
      procedure From(const s: TUnicodeSearchRec);
      class procedure From(out f: TFileDescriptor; const s: TSearchRec); static;
      class procedure From(out f: TFileDescriptor; const s: TUnicodeSearchRec); static;
   end;

   {list of file descriptors}
   PFileDescriptorList = ^TFileDescriptorList;
   TFileDescriptorList = specialize TSimpleList<TFileDescriptor>;

   { TFileTraverse }

   TFileTraverse = record
   public
      {extensions which are only to be included in processing (whitelist)}
      Extensions: array of StdString;
      {extensions which are to be excluded from being processed (blacklist)}
      ExtensionsBlacklist: array of StdString;

      Running: boolean;
      Recursive: boolean;

      {called when a file is found with matching extension (if any), if returns false traversal is stopped}
      OnFile: function(const fn: StdString): boolean;

      procedure Initialize();
      class procedure Initialize(out traverse: TFileTraverse); static;

      {processes a tree with a starting path}
      procedure Run(const startPath: StdString);
      {processes current path}
      procedure Run();

      {add an extension to the extension whitelist}
      procedure AddExtension(const ext: StdString);
      {add an extension to the extension blacklist}
      procedure ExcludeExtension(const ext: StdString);

      {reset extensions}
      procedure ResetExtensions();

      {stop traversing}
      procedure Stop();

   private
      path: StdString;
      {causes process to stop traversing files/directories if set to true}
      stopTraverse: boolean;
      {processes an individual directory (called recursively)}
      procedure RunDirectory(const name: StdString);
   end;

   { TFileUtilsGlobal }

   TFileUtilsGlobal = record
      {checks if a handle is valid}
      class function ValidHandle(handle: THandle): boolean; static; inline;

      {check if a file exists and return its size, otherwise return -1}
      class function Exists(const fn: StdString): fileint; static;
      {gets the size of a specified file, or returns -1 if an error occurs (note: will reset file position)}
      class function hFileSize(const f: THandle): fileint; static;
      {checks if a directory exists}
      class function DirectoryExists(const dir: StdString): boolean; static;
      {checks if a directory is empty}
      class function DirectoryEmpty(const dir: StdString): boolean; static;
      {tells if the specified path contains sub-directories}
      class function ContainsDirectories(const dir: StdString): boolean; static;
      {create the specified directory (unlike CreateDir, returns true if directory already exists)}
      class function CreateDirectory(const dir: StdString): boolean; static;
      {remove directory recusively, returns true if succeeds, returns false if any files/paths failed to delete}
      class function RmDir(const dir: StdString): boolean; static;
      {tells what kind of type the given path is}
      class function PathType(const path: StdString): TFilePathType; static;

      {create a file, returns true if successful}
      class function Create(const fn: StdString): boolean; static;
      {erase a file, returns true if successful}
      class function Erase(const fn: StdString): boolean; static;

      {copy a file from source to destination}
      class function Copy(const source, destination: StdString): longint; static;

      {normalize path, correct directory separators and replace special characters}
      class procedure NormalizePath(var s: StdString); static;
      {do everything NormalizePath() does and also include trailing delimiter}
      class procedure NormalizePathEx(var s: StdString); static;

      {load a file as a string}
      class function LoadString(const fn: StdString; out data: StdString): fileint; static;
      {load file}
      class function Load(const fn: StdString; out data: pointer): fileint; static;

      {load string from a pipe file (or regular file)}
      class function LoadStringPipe(const fn: StdString; out data: StdString): fileint; static;

      {write a file}
      class function CreateFile(const fn: StdString): longint; static;
      {write a file}
      class function Write(const fn: StdString; var data; size: fileint): longint; static;
      {write a file}
      class function WriteString(const fn: StdString; const data: StdString): longint; static;

      {save specified memory to file}
      class function SaveMem(const fn: StdString; var m; size: int64): int64; static;
      {load file to memory, with the specified amount of bytes}
      class function LoadToMem(const fn: StdString; var m; size: int64): int64; static;
      {load file to memory, and allocate enough memory to fit the file}
      class function LoadToMemAlloc(const fn: StdString; var m: pointer): int64; static;

      {tells if a file is a hidden file}
      class function IsHiddenFile(f: TRawbyteSearchRec): boolean; static;

      {find all files in a path and return them as a list of file descriptors, returns 0 if no error}
      class function FindAll(const path: StdString; attr: longint; out list: TFileDescriptorList; properties: TBitSet = 0): longint; static;
      class function FindAll(const path: StdString; out list: TFileDescriptorList; properties: TBitSet = 0): longint; static;
      class function FindDirectories(const path: StdString; attr: longint; out list: TFileDescriptorList; properties: TBitSet = 0): longint; static;

      {sort files}
      class procedure Sort(var list: TFileDescriptorList; directoriesFirst: boolean = true; caseSensitive: boolean = false); static;
      {only sorts directories to be first}
      class procedure SortDirectoriesFirst(var list: TFileDescriptorList); static; static;

      {get information about a file}
      procedure GetFileInfo(const fn: string; out f: TFileDescriptor);
      procedure GetFileInfo(const fn: StdString; out f: TFileDescriptor);
   end;

VAR
   HomePath: StdString;
   FileUtils: TFileUtilsGlobal;

{just a slightly different version of SetTextBuf, to avoid compiler complaining about uninitialized variables}
procedure FileSetTextBuf(var f: text; {%H-}out buf); [INTERNPROC:fpc_in_settextbuf_file_x];

IMPLEMENTATION

{ TFileDescriptor }

function TFileDescriptor.IsDirectory(): boolean;
begin
   Result := Attr and faDirectory <> 0;
end;

function TFileDescriptor.IsFile(): boolean;
begin
   Result := Attr and faDirectory = 0;
end;

function TFileDescriptor.IsHidden(): boolean;
begin
   Result := (Name[1] = '.') and (Name <> '..') and (Name <> '.');

   {$IFDEF WINDOWS}
   Result := Result or (Attr and faHiddenWindows > 0);
   {$ENDIF}
end;

procedure TFileDescriptor.From(const s: TSearchRec);
begin
   Self.Name := s.Name;
   Self.Time := s.Time;
   Self.Size := s.Size;
   Self.Attr := s.Attr;
end;

procedure TFileDescriptor.From(const s: TUnicodeSearchRec);
begin
   Self.Name := UTF8String(s.Name);
   Self.Time := s.Time;
   Self.Size := s.Size;
   Self.Attr := s.Attr;
end;

class procedure TFileDescriptor.From(out f: TFileDescriptor; const s: TSearchRec);
begin
   ZeroOut(f, SizeOf(f));
   f.From(s);
end;

class procedure TFileDescriptor.From(out f: TFileDescriptor; const s: TUnicodeSearchRec);
begin
   ZeroOut(f, SizeOf(f));
   f.From(s);
end;

class function TFileUtilsGlobal.ValidHandle(handle: THandle): boolean;
begin
   {$IF defined(WINDOWS) AND defined(CPU64)}
      Result := int64(handle) <> -1;
   {$ELSE}
      Result := int32(handle) <> -1;
   {$ENDIF}
end;

class function TFileUtilsGlobal.Exists(const fn: StdString): fileint;
var
   f: file;

begin
   if(fn <> '') then begin
      {first try regular files}
      if(FileReset(f, fn) = 0) then begin
         Result := FileSize(f);
         ioerror();

         Close(f);
         ioerror();
      end else begin
         Result := -1;
         ioE := eNONE;
      end;
   end else
      Result := -1;
end;

class function TFileUtilsGlobal.hFileSize(const f: THandle): fileint;
begin
   Result := FileSeek(f, fileint(0), fsFromEnd);

   if(Result <> -1) then
      FileSeek(f, fileint(0), fsFromBeginning);
end;

class function TFileUtilsGlobal.DirectoryExists(const dir: StdString): boolean;
begin
   Result := sysutils.DirectoryExists(dir);
end;

class function TFileUtilsGlobal.DirectoryEmpty(const dir: StdString): boolean;
var
   f: TRawbyteSearchRec;
   error: longint;

begin
   error := FindFirst(IncludeTrailingPathDelimiter(dir) + '*.*', faAnyFile, f);

   if(error = 0) then begin
      repeat
         if(f.Name <> '.') and (f.Name <> '..') then begin
            FindClose(f);
            exit(false);
         end;

         error := FindNext(f);
      until (error <> 0);

      FindClose(f);
      exit(true);
   end;

   FindClose(f);
   exit(false);
end;

class function TFileUtilsGlobal.ContainsDirectories(const dir: StdString): boolean;
var
   f: TRawbyteSearchRec;
   error: longint;

begin
   error := FindFirst(IncludeTrailingPathDelimiterNonEmpty(dir) + '*.*', faAnyFile, f);

   if(error = 0) then begin
      repeat
         if(f.Attr and faDirectory > 0) and (f.Name <> '.') and (f.Name <> '..') then begin
            FindClose(f);
            exit(true);
         end;

         error := FindNext(f);
      until (error <> 0);
   end;

   FindClose(f);
   exit(false);
end;

class function TFileUtilsGlobal.CreateDirectory(const dir: StdString): boolean;
begin
   {first find if the path exists}
   if(not DirectoryExists(dir)) then
      Result := CreateDir(dir)
   else
      Result := true;
end;

class function RmDirChildren(const dir: StdString): boolean;
var
   src: TSearchRec;
   code: longint;

begin
   Result := true;

   {find first}
   if(dir = '') then
      code := FindFirst('*', faReadOnly or faDirectory, src)
   else
      code := FindFirst(dir + DirectorySeparator + '*', faReadOnly or faDirectory, src);

   if(code = 0) then begin
      repeat
         {avoid special directories}
         if(src.Name <> '.') and (src.Name <> '..') then begin
            {found directory, recurse into it}
            if(src.Attr and faDirectory > 0) then begin
               if(not RmDirChildren(dir + DirectorySeparator + src.Name)) then
                  Result := false;
            end;
         end;

         {delete file}
         if(src.Attr and faDirectory = 0) then begin
            if(not DeleteFile(dir + DirectorySeparator + src.Name)) then
               Result := false;
         end;

         {next file/directory}
         code := FindNext(src);
      until (code <> 0);
   end;

   {remove directory}
   if(dir <> '') then begin
      if(not RemoveDir(dir)) then
         Result := false;
   end;

   {we're done}
   FindClose(src);
end;

class function TFileUtilsGlobal.RmDir(const dir: StdString): boolean;
begin
   Result := RmDirChildren(ExcludeTrailingPathDelimiter(dir));
end;

class function TFileUtilsGlobal.PathType(const path: StdString): TFilePathType;
var
   f: TSearchRec;
   descriptor: TFileDescriptor;

begin
   Result := PATH_TYPE_NON_EXISTENT;

   if(FindFirst(path, faAnyFile, f) = 0) then begin
      TFileDescriptor.From(descriptor, f);
   end;
end;

class function TFileUtilsGlobal.Create(const fn: StdString): boolean;
var
   f: file;

begin
   ZeroOut(f, SizeOf(f));
   ioE := eNONE;

   {first try regular files}
   if(FileRewrite(f, fn) = 0) then begin
      Close(f);
      ioerror();
      exit(true);
   end;

   exit(false);
end;

class function TFileUtilsGlobal.Erase(const fn: StdString): boolean;
begin
   Result := DeleteFile(fn);
end;

class function TFileUtilsGlobal.Copy(const source, destination: StdString): longint;
const
  BUFFER_SIZE = 32768;

var
   sF, dF: file;
   buffer: array[0..BUFFER_SIZE - 1] of byte;
   count, written: fileint;

begin
   Result := 0;
   count := 0;
   written := 0;
   {$IFDEF DEBUG}
   buffer[0] := 0;
   {$ENDIF}

   ZeroOut(sf, SizeOf(sF));
   ZeroOut(df, SizeOf(dF));

   if(FileReset(sF, source) <> 0) then
      exit(eFILE_COPY_OPEN_SOURCE);

   if(FileRewrite(dF, destination) <> 0) then begin
      Close(sF);
      Close(dF);
      ioErrorIgn();
      exit(eFILE_COPY_CREATE_DESTINATION);
   end;

   Result := FileSize(sF);

   repeat
      BlockRead(sF, buffer, BUFFER_SIZE, count);
      if(ioerror() <> 0) then begin
         Result := eFILE_COPY_READ_SOURCE;
         break;
      end;

      BlockWrite(dF, buffer, count, written);
      if(ioerror() <> 0) then begin
         Result := eFILE_COPY_WRITE_DESTINATION;
         break;
      end;

      if(written <> count) then begin
         Result := eFILE_COPY_WRITE_DESTINATION;
         break;
      end;
   until eof(sF);

   Close(dF);
   if(Result <> 0) then
      ioErrorIgn()
   else begin
      if(ioerror() <> 0) then
         Result := eFILE_COPY_WRITE_DESTINATION;
   end;

   Close(sF);
   ioErrorIgn();
end;

class procedure TFileUtilsGlobal.NormalizePath(var s: StdString);
begin
   ReplaceDirSeparators(s);

   if(pos('~', s) <> 0) then
      s := StringReplace(s, '~', homePath, []);
end;

class procedure TFileUtilsGlobal.NormalizePathEx(var s: StdString);
begin
   NormalizePath(s);

   if(s <> '') then
      s := IncludeTrailingPathDelimiter(s);
end;

class function TFileUtilsGlobal.LoadString(const fn: StdString; out data: StdString): fileint;
var
   f: file;
   size,
   countRead,
   error: fileint;

procedure cleanup();
begin
   close(f);
   ioErrorIgn();
end;

begin
   Result := 0;
   countRead := 0;
   data := '';

   error := FileReset(f, fn);
   if(error <> 0) then
      exit(-error);

   size := FileSize(f);
   error := ioerror();
   if(error <> 0) then begin
      cleanup();
      exit(-error);
   end;

   Result := size;

   try
      SetLength(data, size);
   except
      cleanup();
      exit(eFILE_ERROR);
   end;

   BlockRead(f, data[1], size, countRead);
   if (countRead <> size) then begin
      cleanup();
      error := ioerror();
      if(error <> 0) then
         exit(-error);
   end;

   Result := size;

   error := ioerror();
   if(error <> 0) then begin
      cleanup();
      exit(-error);
   end;

   close(f);
   error := ioerror();
   if(error <> 0) then
      Result := -error;
end;

class function TFileUtilsGlobal.Load(const fn: StdString; out data: pointer): fileint;
var
   f: file;
   size,
   countRead: fileint;
   error: loopint;

procedure cleanup();
begin
   close(f);
   ioErrorIgn();
end;

begin
   countRead := 0;

   error := FileReset(f, fn);
   if(error <> 0) then
      exit(-error);

   size := FileSize(f);
   error := ioerror();
   if(error <> 0) then begin
      cleanup();
      exit(-error);
   end;

   try
      getmem(data, size);
   except
      cleanup();
      exit(-203);
   end;

   BlockRead(f, data^, size, countRead);
   if (countRead <> size) then begin
      error := ioerror();
      cleanup();
      exit(-error);
   end;

   Result := size;

   error := ioerror();
   if(error <> 0) then begin
      cleanup();
      exit(-error);
   end;

   close(f);
   error := ioerror();
   if(error <> 0) then
      Result := -error;
end;

class function TFileUtilsGlobal.LoadStringPipe(const fn: StdString; out data: StdString): fileint;
var
   buffer: array[0..32767] of char;
   f: THandle;
   size,
   countRead,
   dataPosition,
   totalSize: fileint;

procedure cleanup();
begin
   FileClose(f);
   ioErrorIgn();
end;

begin
   Result := 0;
   data := '';

   f := FileOpen(fn, fmShareDenyNone);
   if(not ValidHandle(f)) then
      exit(-1);

   totalSize := 0;
   countRead := 0;
   size := hFileSize(f);

   if(size > 0) then begin
      totalSize := size;

      {we managed to get a size, so we read more}
      Result := size;

      try
         SetLength(data, size);
      except
         cleanup();
         exit(eFILE_ERROR);
      end;

      countRead := FileRead(f, data[1], size);

      if (countRead <> size) then begin
         cleanup();
         exit(-1);
      end;

      Result := size;
   end else begin
      totalSize := 0;
      dataPosition := 1;
      buffer[0] := #0; {silence}

      repeat
         {read }
         countRead := FileRead(f, buffer[0], Length(buffer));

         if(countRead <= 0) then begin
            {return error if nothing read}
            if(totalSize = 0) then
               totalSize := countRead;

            break;
         end;

         inc(totalSize, countRead);

         {increase our size}
         SetLength(data, totalSize);
         move(buffer[0], data[dataPosition], countRead);

         {move to next position}
         inc(dataPosition, countRead);
      until countRead <= 0;
   end;

   FileClose(f);
   Result := TotalSize;
end;

class function TFileUtilsGlobal.CreateFile(const fn: StdString): longint;
var
   f: file;
   error: loopint;

procedure cleanup();
begin
   close(f);
   ioErrorIgn();
end;

begin
   error := FileRewrite(f, fn);
   if(error <> 0) then
      exit(-error);

   Close(f);
   error := ioerror();

   if(error <> 0) then
      Result := -error
   else
      Result := 0;
end;

class function TFileUtilsGlobal.Write(const fn: StdString; var data; size: fileint): longint;
var
   f: file;
   countWritten: int64;
   error: loopint;

procedure cleanup();
begin
   close(f);
   ioErrorIgn();
end;

begin
   countWritten := 0;

   error := FileRewrite(f, fn);
   if(error <> 0) then
      exit(-error);

   if(size > 0) then begin

      BlockWrite(f, data, size, countWritten);
      if (countWritten <> size) then begin
         error := ioerror();
         cleanup();
         exit(-error);
      end;

      error := ioerror();
      if(error <> 0) then begin
         cleanup();
         exit(-error)
      end;
   end;

   close(f);
   error := ioerror();
   if (ioerror() <> 0) then
      Result := -error
   else
      Result := eNONE;
end;

class function TFileUtilsGlobal.WriteString(const fn: StdString; const data: StdString): longint;
begin
   if(data <> '') then
      Result := Write(fn, (@data[1])^, Length(data))
   else
      Result := CreateFile(fn);
end;

class function TFileUtilsGlobal.SaveMem(const fn: StdString; var m; size: int64): int64;
var
   f: file;
   brw: int64 = 0;
   error: longint;

begin
   Result := -1;

   {open the file}
   error := FileRewrite(f, fn);
   if(error <> 0) then
      exit(-error);

   {save the memory contents to the file}
   blockwrite(f, m, size, brw);
   error := ioerror();
   if(error <> 0) then begin
      close(f);
      ioErrorIgn();
      exit(-error);
   end;

   {close the file}
   close(f);
   error := ioerror();
   if(error <> 0) then
      exit(-error);

   Result := brw;
end;

class function TFileUtilsGlobal.LoadToMem(const fn: StdString; var m; size: int64): int64;
var
   f: file;
   br: int64 = 0;
   fsize: int64;
   error: longint;

procedure cleanup();
begin
   close(f);
   ioErrorIgn();
end;

begin
   Result := -1;

   {open the file}
   error := FileReset(f, fn);
   if(error <> 0) then
      exit(-error);

   {get the file size}
   fsize := FileSize(f);
   error := ioerror();
   if(error <> 0) then begin
      cleanup();
      exit(error);
   end;

   Result := fsize;
   if(size < fsize) then
      size := fsize;

   {allocate memory for the file}
   blockread(f, m, size, br);
   if(ioerror() = 0) then begin
      {close the file}
      close(f);
      error := ioerror();
      if(error = 0) then
         {return how much was read}
         Result := br
      else
        Result := -error;
   end;

   cleanup();
end;

class function TFileUtilsGlobal.LoadToMemAlloc(const fn: StdString; var m: pointer): int64;
var
   f: file;
   br: int64 = 0;
   size: int64;
   error: longint;

procedure cleanup();
begin
   close(f);
   ioErrorIgn();
end;

begin
   Result := -1;

   {open the file}
   error := FileReset(f, fn);
   if(error <> 0) then
      exit(-error);

   {get the file size}
   size := FileSize(f);
   error := ioerror();
   if(error <> 0) then begin
      cleanup();
      exit(-error);
   end;

   {allocate memory for the file}
   GetMem(m, size);
   if(m <> nil) then begin
      {read the file contents to the memory}
      blockread(f, m^, size, br);
      error := ioerror();
      if(error = 0) then begin
         {close the file}
         close(f);
         ioErrorIgn();
         Result := br;
      end else
         exit(-error);
   end else
      exit(0);

   cleanup();
end;

class function TFileUtilsGlobal.IsHiddenFile(f: TRawbyteSearchRec): boolean;
begin
   Result := (f.Name[1] = '.') and (f.Name <> '..') and (f.Name <> '.');

   {$IFDEF WINDOWS}
   Result := Result or (f.Attr and faHiddenWindows > 0);
   {$ENDIF}
end;

class function TFileUtilsGlobal.FindAll(const path: StdString; attr: longint; out list: TFileDescriptorList; properties: TBitSet): longint;
var
   f: TRawbyteSearchRec;
   error: longint;
   descriptor: TFileDescriptor;

begin
   list.Initialize(list);

   error := FindFirst(path, attr, f);
   ZeroPtr(@descriptor, SizeOf(descriptor));

   if(error = 0) then begin
      if(not properties.IsSet(FILE_FIND_ALL_ONLY_DIRECTORIES)) then begin
         repeat
            if(f.Name <> '.') and ((f.Name <> '..') or (not properties.IsSet(FILE_FIND_ALL_SKIP_PARENT_DIRECTORY_LINK))) then begin
               if(properties.IsSet(FILE_FIND_ALL_HIDDEN) or (not IsHiddenFile(f))) then begin
                  descriptor.From(f);

                  list.Add(descriptor);
               end;
            end;

            if(FindNext(f) <> 0) then
               break;
         until (error <> 0);
      end else begin
         repeat
            if(f.Name <> '.') and ((f.Name <> '..') or (not properties.IsSet(FILE_FIND_ALL_SKIP_PARENT_DIRECTORY_LINK))) and (f.Attr and faDirectory > 0) then begin
               if(properties.IsSet(FILE_FIND_ALL_HIDDEN) or (not IsHiddenFile(f))) then begin
                  descriptor.From(f);

                  list.Add(descriptor);
               end;
            end;

            if(FindNext(f) <> 0) then
               break;
         until (error <> 0);
      end;
   end;

   {done}
   ioErrorIgn();
   FindClose(f);

   Result := error;
end;

class function TFileUtilsGlobal.FindAll(const path: StdString; out list: TFileDescriptorList; properties: TBitSet): longint;
begin
   Result := FindAll(path, faDirectory or faReadOnly, list, properties);
end;

class function TFileUtilsGlobal.FindDirectories(const path: StdString; attr: longint; out list: TFileDescriptorList; properties: TBitSet): longint;
begin
   Result := FindAll(path, attr, list, properties or FILE_FIND_ALL_ONLY_DIRECTORIES);
end;

class procedure TFileUtilsGlobal.Sort(var list: TFileDescriptorList; directoriesFirst: boolean; caseSensitive: boolean);
Var
   i,
   j,
   step: loopint;

   tmp: TFileDescriptor;

   function greaterThan(const a1, a2: TFileDescriptor): boolean;
   begin
      if(a1.IsDirectory() and a2.IsDirectory()) then
         Result := CompareText(a1.Name, a2.Name) > 0
      else if(a1.IsDirectory() and (not a2.IsDirectory())) then
         Result := false
      else if(not a1.IsDirectory() and (a2.IsDirectory())) then
         Result := true
      else
         Result := CompareText(a1.Name, a2.Name) > 0
   end;

   function greaterThanIgnoreDir(const a1, a2: TFileDescriptor): boolean;
   begin
      Result := CompareText(a1.Name, a2.Name) > 0
   end;

   function greaterThanSensitive(const a1, a2: TFileDescriptor): boolean;
   begin
      if(a1.IsDirectory() and a2.IsDirectory()) then
         Result := a1.Name > a2.Name
      else if(a1.IsDirectory() and (not a2.IsDirectory())) then
         Result := false
      else if(not a1.IsDirectory() and (a2.IsDirectory())) then
         Result := true
      else
         Result := a1.Name > a2.Name
   end;

   function greaterThanIgnoreDirSensitive(const a1, a2: TFileDescriptor): boolean;
   begin
      Result := a1.Name > a2.Name
   end;

Begin
   step := list.n div 2;  // step := step shr 1

   {TODO: maybe also use quick sort for large amounts of files}

   {shell sort}
   if(not caseSensitive) then begin
      if(directoriesFirst) then begin
         while (step > 0) do begin
            for i := step to list.n - 1 do begin
               tmp := list.List[i];
               j := i;

               while ((j >= step) and greaterThan(list.List[j - step], tmp)) do begin
                  list.List[j] := list[j - step];
                  dec(j, step);
               end;

               list.List[j] := tmp;
            end;

            step := step div 2;
         end;
      end else begin
         while (step > 0) do begin
            for i := step to list.n - 1 do begin
               tmp := list.List[i];
               j := i;

               while ((j >= step) and greaterThanIgnoreDir(list.List[j - step], tmp)) do begin
                  list.List[j] := list[j - step];
                  dec(j, step);
               end;

               list.List[j] := tmp;
            end;

            step := step div 2;
         end;
      end;
   end else begin
      if(directoriesFirst) then begin
         while (step > 0) do begin
            for i := step to list.n - 1 do begin
               tmp := list.List[i];
               j := i;

               while ((j >= step) and greaterThanSensitive(list.List[j - step], tmp)) do begin
                  list.List[j] := list[j - step];
                  dec(j, step);
               end;

               list.List[j] := tmp;
            end;

            step := step div 2;
         end;
      end else begin
         while (step > 0) do begin
            for i := step to list.n - 1 do begin
               tmp := list.List[i];
               j := i;

               while ((j >= step) and greaterThanIgnoreDirSensitive(list.List[j - step], tmp)) do begin
                  list.List[j] := list[j - step];
                  dec(j, step);
               end;

               list.List[j] := tmp;
            end;

            step := step div 2;
         end;
      end;
   end;
end;

class procedure TFileUtilsGlobal.SortDirectoriesFirst(var list: TFileDescriptorList);
Var
   i,
   j,
   step: loopint;

   tmp: TFileDescriptor;

   function greaterThan(const a1, a2: TFileDescriptor): boolean;
   begin
      Result := (not a1.IsDirectory()) and a2.IsDirectory();
   end;

Begin
   step := list.n div 2;  // step := step shr 1

   {TODO: maybe also use quick sort for large amounts of files}

   {shell sort}

   while (step > 0) do begin
      for i := step to list.n - 1 do begin
         tmp := list.List[i];
         j := i;

         while ((j >= step) and greaterThan(list.List[j - step], tmp)) do begin
            list.List[j] := list[j - step];
            dec(j, step);
         end;

         list.List[j] := tmp;
      end;

      step := step div 2;
   end;
end;

procedure TFileUtilsGlobal.GetFileInfo(const fn: string; out f: TFileDescriptor);
var
   searchRec: TSearchRec;

begin
   FindFirst(fn, faAnyFile or faDirectory, searchRec);

   TFileDescriptor.From(f, searchRec);

   FindClose(searchRec);
end;

procedure TFileUtilsGlobal.GetFileInfo(const fn: StdString; out f: TFileDescriptor);
var
   searchRec: TUnicodeSearchRec;

begin
   FindFirst(UnicodeString(fn), faAnyFile or faDirectory, searchRec);

   TFileDescriptor.From(f, searchRec);

   FindClose(searchRec);
end;

{ TFileTraverse }

procedure TFileTraverse.Initialize();
begin
   Recursive := true;
end;

class procedure TFileTraverse.Initialize(out traverse: TFileTraverse);
begin
   ZeroPtr(@traverse, SizeOf(traverse));
   traverse.Initialize();
end;

procedure TFileTraverse.Run(const startPath: StdString);
begin
   path           := startPath;
   stopTraverse   := false;
   Running        := true;

   RunDirectory('');
   Running := false;
end;

procedure TFileTraverse.Run();
begin
   Run('');
end;

procedure TFileTraverse.AddExtension(const ext: StdString);
begin
   SetLength(Extensions, Length(Extensions) + 1);
   Extensions[Length(Extensions) - 1] := ext;
end;

procedure TFileTraverse.ExcludeExtension(const ext: StdString);
begin
   SetLength(ExtensionsBlacklist, Length(ExtensionsBlacklist) + 1);
   ExtensionsBlacklist[Length(ExtensionsBlacklist) - 1] := ext;
end;

procedure TFileTraverse.ResetExtensions();
begin
   SetLength(ExtensionsBlacklist, 0);
   SetLength(Extensions, 0);
end;

procedure TFileTraverse.Stop();
begin
   stopTraverse := true;
end;

procedure TFileTraverse.RunDirectory(const name: StdString);
var
   src: TUnicodeSearchRec;
   i,
   result: longint;
   ext,
   fname: StdString;
   ok: boolean;

begin
   {build path}
   if(name <> '') then
      path := IncludeTrailingPathDelimiterNonEmpty(path) + name;

   {find first}
   if(path = '') then
      result := FindFirst('*', faReadOnly or faDirectory, src)
   else
      result := FindFirst(UTF8Decode(Path + DirectorySeparator + '*'), faReadOnly or faDirectory, src);

   if(result = 0) then begin
      repeat
         {avoid special directories}
         if(src.Name <> '.') and (src.Name <> '..') then begin
            {found directory, recurse into it}
            if(src.Attr and faDirectory > 0) then begin
               if(Recursive) then
                  RunDirectory(UTF8Encode(src.Name));
            end else begin
               ok    := true;
               ext   := UTF8Lower(ExtractFileExt(utf8string(UTF8Encode(src.Name))));

               {check if extension matches any on the blacklist (if there is a blacklist)}
               if(ExtensionsBlacklist <> nil) then begin
                  for i := 0 to Length(ExtensionsBlacklist) - 1 do begin
                     if(ext = ExtensionsBlacklist[i]) then
                        ok := false;
                  end;
               end;

               {check if file matches extension (if any specified)}
               if(Extensions <> nil) and (ok) then begin
                  ok := false;

                  for i := 0 to Length(Extensions) - 1 do
                     if(ext = Extensions[i]) then
                        ok := true;
               end;

               if(ok) then begin
                  {build filename}
                  if(path <> '') then
                     fname := path + DirectorySeparator + UTF8Encode(src.Name)
                  else
                     fname := UTF8Encode(src.Name);

                  {call OnFile to perform operations on the file}
                  if(OnFile <> nil) and (not OnFile(fname)) then
                     stopTraverse := true;
               end;
            end;
         end;

         if(stopTraverse) then
            break;

         {next file/directory}
         result := FindNext(src);
      until (result <> 0);
   end;

   path := ExcludeTrailingPathDelimiter(ExtractFilePath(path));

   {we're done}
   FindClose(src);
end;

INITIALIZATION
   {$IFDEF UNIX}
   HomePath := GetEnvironmentVariable('HOME');
   {$ENDIF}

END.
