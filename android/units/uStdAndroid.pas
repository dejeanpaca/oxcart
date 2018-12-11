{
   uStd, standard resources unit(something like system unit)
   Copyright (C) Dejan Boras 2011.

   Started on:    30.01.2011.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$MODESWITCH TYPEHELPERS}
UNIT uStdAndroid;

INTERFACE

   USES
      sysutils, uStd, strings, androidlog;

IMPLEMENTATION

{report exceptions under android}
procedure AndroidCatchUnhandledException(Obj: TObject; Addr: Pointer; FrameCount: Longint; Frames: PPointer);
var
   message: string;
   i: LongInt;

procedure printBacktrace(addr: pointer);
var
   pmessage: pchar;

begin
   message := BackTraceStrFunc(addr);
   pmessage := StrAlloc(length(message));
   StrPCopy(pmessage, message);
   __android_log_write(ANDROID_LOG_FATAL, 'error', pmessage);
   StrDispose(pmessage);
end;

begin
   __android_log_write(ANDROID_LOG_FATAL, 'error',
      pchar('An unhandled exception occurred at $' + HexStr(PtrUInt(Addr), SizeOf(PtrUInt) * 2) + ' :'));

   if(Obj is Exception) then begin
      message := Exception(Obj).ClassName + ' : ' + Exception(Obj).Message;
      __android_log_write(ANDROID_LOG_FATAL, 'error', pchar(message));
   end else
      __android_log_write(ANDROID_LOG_FATAL, 'error', pchar('Exception object ' + Obj.ClassName + ' is not of class Exception.'));

   printBacktrace(addr);
   if (FrameCount > 0) then begin
      for i := 0 to FrameCount - 1 do
         printBacktrace(Frames[i]);
   end;

   __android_log_write(ANDROID_LOG_FATAL, 'error', '');
end;

INITIALIZATION
   ExceptProc := @AndroidCatchUnhandledException;

END.
