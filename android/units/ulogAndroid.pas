{
   ulogAndroid, uLog android handler
   Copyright (C) 2019. Dejan Boras

   Started On:    11.11.2019.
}

{$MODE OBJFPC}{$H+}
UNIT ulogAndroid;

INTERFACE

   USES
      uLog;

VAR
   loghAndroid: TLogHandler;

IMPLEMENTATION

CONST
   androidPriorities: array[0..logcPRIORITY_MAX] of longint = (
      ANDROID_LOG_INFO, {logcINFO}
      ANDROID_LOG_WARN, {logcWARNING}
      ANDROID_LOG_ERROR, {logcERROR}
      ANDROID_LOG_VERBOSE, {logcVERBOSE}
      ANDROID_LOG_FATAL, {logcFATAL}
      ANDROID_LOG_DEBUG {logcDEBUG}
   );

procedure hwriteln(logf: PLog; priority: longint; const s: StdString);
begin
   SysLogWrite(androidPriorities[priority], S);
end;

INITIALIZATION
   {use the standard log handler for most operations}
   loghAndroid                := log.handler.Dummy;
   loghAndroid.Name           := 'android';
   loghAndroid.FileExtension  := '';
   loghAndroid.writeln        := @hwriteln;

   {nothing should be output to the file by default }
   loghAndroid.NoHeader       := true;

   log.Handler.pDefault := @loghAndroid;
END.
