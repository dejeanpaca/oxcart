{
   uError
   Copyright (C) Dejan Boras 2020.
}

{$INCLUDE oxheader.inc}
UNIT uErrorCrashHandler;

INTERFACE

   USES
      sysutils, uStd, uError;

IMPLEMENTATION

VAR
   oldExitProc: pointer;

procedure RunTimeErrorDisplay(addr: pointer);
var
   s: StdString;

begin
   {display the error message}
   if(addr <> nil) and (isConsole) then begin
      writeln(stdout, '┻━┻ ︵ ╯(°□° ╯)');

      s := getRunTimeErrorDescription(ErrorCode);

      writeln(stdout, 'Error (', ErrorCode, '): ', s, ' @ $', addr2str(addr));
      writeln(DumpCallStack(1));
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
   if(not isConsole) then
      exit;

   writeln(stdout, '(╯°□°)╯︵ ┻━┻');
   writeln(stdout, 'Unhandled exception @ $',  addr2str(addr), ' :');

   if(obj is Exception) then begin
      writeln(stdout, DumpExceptionCallStack(Exception(obj)));
   end else begin
      writeln(stdout, 'Exception object ', obj.ClassName, ' is not of class Exception.');
      writeln(stdout, DumpExceptionCallStack(addr, frameCount, frames));
   end;

   writeln(stdout,'');
end;

INITIALIZATION
   {store the old exit proc and set the new one}
   oldExitProc := ExitProc;
   ExitProc := @RunTimeError;

   ExceptProc := @UnhandledException;

END.
