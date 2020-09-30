{
   uErrorLog
   Copyright (C) Dejan Boras 2020.
}

{$INCLUDE oxheader.inc}
UNIT uErrorLog;

INTERFACE

   USES
      sysutils, uStd, uLog, uError, StringUtils;

IMPLEMENTATION

VAR
   oldExitProc: pointer;

procedure RunTimeErrorDisplay(addr: pointer);
var
   s: StdString;

begin
   {display the error message}
   if(addr <> nil) and (isConsole) then begin
      log.e('┻━┻ ︵ ╯(°□° ╯)');

      s := getRunTimeErrorDescription(ErrorCode);

      log.e('Error (' + sf(ErrorCode) + '): ' + s + ' @ $' + addr2str(addr));
   end;
end;

procedure RunTimeError();
begin
   {restore the previous error handler}
   ExitProc := oldExitProc;

   RunTimeErrorDisplay(ErrorAddr);
end;

procedure UnhandledException(obj: TObject; addr: Pointer; {%H-}frameCount: Longint; {%H-}frames: PPointer);
begin
   log.e('(╯°□°)╯︵ ┻━┻');
   log.e('Unhandled exception @ $' + addr2str(addr) + ' :');

   if(obj is Exception) then begin
      log.e(DumpExceptionCallStack(Exception(obj)));
   end else begin
      log.e('Exception object ' + obj.ClassName + ' is not of class Exception.');
      log.e(DumpExceptionCallStack(addr, frameCount, frames));
   end;

   ExceptProc := @oldExceptProc;
   if(oldExceptProc <> nil) then
      oldExceptProc(obj, addr, frameCount, frames);
end;

INITIALIZATION
   {$IFNDEF ANDROID}
   {store the old exit proc and set the new one}
   oldExitProc := ExitProc;
   ExitProc := @RunTimeError;

   oldExceptProc := @ExceptProc;
   ExceptProc := @UnhandledException;
   {$ENDIF}

END.
