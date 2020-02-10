{
   uFileTrash, file trash/recycle helpers
   Copyright (C) 2020. Dejan Boras

   Started On:    30.01.2020.
}

{$INCLUDE oxheader.inc}
UNIT uFileTrash;

INTERFACE

   USES
      uStd, uFileUtils
      {$IFDEF WINDOWS}
      , ShellApi
      {$ENDIF}
      {$IFDEF LINUX}
      , sysutils, StringUtils
      {$ENDIF};

TYPE

   { TFileTrash }

   TFileTrash = record
      LastError: loopint;

      function Recycle(const {%H-}fn: StdString): boolean;
   end;

VAR
   FileTrash: TFileTrash;

IMPLEMENTATION

{ TFileTrash }

{$IF DEFINED(WINDOWS)}
function TFileTrash.Recycle(const fn: StdString): boolean;
VAR
   fileop: SHFILEOPSTRUCTW;
   from: array[0..4095] of WideChar;

begin
   ZeroOut(fileop, SizeOf(fileop));

   from := StringToWideChar(fn + #0, @from[0], Length(from));

   fileop.wFunc := FO_DELETE;
   fileop.pFrom := @from[0];
   fileop.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT;

   LastError := SHFileOperationW(@fileop);
   if(LastError = 0) then
      exit(True);

   Result := False;
end;
{$ELSEIF DEFINED(LINUX)}
VAR
   trashPath,
   trashPathInfo,
   trashPathFiles: StdString;

procedure DetermineTrashPath();
var
   homeDir: string;

begin
   homeDir := IncludeTrailingPathDelimiterNonEmpty(HomePath);

   {we support only freedesktop.org specification trash folders}

   trashPath := '';
   trashPathInfo := '';
   trashPathFiles := '';

   if(homeDir <> '') then begin
      trashPath := homeDir + '.local/share/Trash';

      if(not FileUtils.DirectoryExists(trashPath)) then begin
         trashPath := homeDir + '.trash';

         if(not FileUtils.DirectoryExists(trashPath)) then begin
            trashPath := homeDir + '/Trash';

            if(not FileUtils.DirectoryExists(trashPath)) then
               trashPath := '';
         end;
      end;

      if(trashPath <> '') then begin
         trashPathInfo := trashPath + '/info/';
         trashPathFiles := trashPath + '/files/';

         if(not FileUtils.DirectoryExists(trashPathFiles)) then
            trashPath := '';
      end;
   end;
end;

function TFileTrash.Recycle(const fn: StdString): boolean;
var
   {.trashinfo file contents}
   info,
   {name of the file/directory}
   name,
   {new base name}
   baseName,
   {new file name (in trash)}
   trashFn,
   {trash info file}
   infoFile,
   {full path to the original file}
   fullPath: string;

   i: loopint;

begin
   Result := false;

   if(trashPath <> '') then begin
      if(fn = '') then begin
         LastError := -eINVALID_ARG;
         exit(false);
      end;

      { expand the file path just in case }
      fullPath := ExpandFileName(fn);

      if(not FileUtils.DirectoryExists(fullPath) and (FileUtils.Exists(fullPath) < 0)) then begin
         LastError := -eINVALID_ARG;
         exit(false);
      end;

      name := ExtractFileName(fullPath);

      info := '[Trash Info]' + LineEnding + 'Path=' + fullPath + LineEnding +
      'DeletionDate=' + FormatDateTime('yyyy-mm-dd"T"hh:mm:ss', Now) + LineEnding;

      infoFile := trashPathInfo + name + '.trashinfo';
      trashFn := trashPathFiles + name;
      i := 0;

      while((FileUtils.Exists(infoFile) > 0) or (FileUtils.Exists(trashFn) > 0)) do begin
         inc(i);

         baseName := name + sf(i);

         infoFile := trashPathInfo + baseName + '.trashinfo';
         trashFn := trashPathFiles + baseName;
      end;

      LastError := FileUtils.WriteString(infoFile, info);

      if(LastError <= 0) then
         exit(false);

      RenameFile(fullPath, trashFn);
      LastError := ioerror();
      if(LastError = 0) then
         exit(true);
   end else begin
      if(FileUtils.DirectoryExists(fn)) then begin
         Result := FileUtils.RmDir(fn)
      end else if(FileUtils.Exists(fn) >= 0) then
         Result := FileUtils.Erase(fn);

      LastError := ioerror();
   end;
end;
{$ELSE}
function TFileTrash.Recycle(const fn: StdString): boolean;
begin
   Result := false;
end;
{$ENDIF}

INITIALIZATION
   DetermineTrashPath();

END.
