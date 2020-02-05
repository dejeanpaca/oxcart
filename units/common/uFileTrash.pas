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
      {$ENDIF};

TYPE

   { TFileTrash }

   TFileTrash = record
      LastError: loopint;

      function Recycle(const fn: StdString): boolean;
   end;

VAR
   FileTrash: TFileTrash;

IMPLEMENTATION

{ TFileTrash }

{$IFDEF WINDOWS}
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
{$ELSE}
procedure TFileTrash.Recycle(const fn: StdString);
begin

end;
{$ENDIF}

END.
