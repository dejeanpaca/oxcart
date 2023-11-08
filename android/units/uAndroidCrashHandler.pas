{
   uAndroidCrashHandler
   Copyright (C) Dejan Boras 2020.
}

{$INCLUDE oxheader.inc}
UNIT uAndroidCrashHandler;

INTERFACE

   USES
      sysutils, uStd, uError, StringUtils;

IMPLEMENTATION

VAR
   oldExitProc: pointer;

procedure loge(const what: string);
begin
   SysLogWrite(ANDROID_LOG_ERROR, pchar(what));
end;

procedure RunTimeErrorDisplay(addr: pointer);
var
   s: StdString;

begin
   {display the error message}
   if(addr <> nil) then begin
      loge('┻━┻ ︵ ╯(°□° ╯)');

      s := getRunTimeErrorDescription(ErrorCode);

      loge('Error (' + sf(ErrorCode) + '): ' + s + ' @ $' + addr2str(addr));
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
   loge('(╯°□°)╯︵ ┻━┻');
   loge('Unhandled exception @ $' +  addr2str(addr));

   if(obj is Exception) then begin
      loge(DumpExceptionCallStack(Exception(obj)));
   end else begin
      loge('Exception object ' + obj.ClassName + ' is not of class Exception.');
      loge(DumpExceptionCallStack(addr, frameCount, frames));
   end;
end;

INITIALIZATION
   {store the old exit proc and set the new one}
   oldExitProc := ExitProc;
   ExitProc := @RunTimeError;

   ExceptProc := @UnhandledException;

END.
