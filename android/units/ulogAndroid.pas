{
   ulogAndroid, uLog android handler
   Copyright (C) 2019. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT ulogAndroid;

INTERFACE

   USES
      uStd, uLog;

TYPE

   { TAndroidLogHandler }

   TAndroidLogHandler = object(TLogHandler)
      constructor Create();
      procedure Writeln(log: PLog; priority: longint; const s: StdString); virtual;
      procedure WritelnRaw(log: PLog; const s: StdString); virtual;
   end;

VAR
   loghAndroid: TLogHandler;

procedure logi(priority: longint; const what: StdString);
procedure logi(const what: StdString);
procedure loge(const what: StdString);

IMPLEMENTATION

CONST
   androidPriorities: array[0..logcPRIORITY_MAX] of longint = (
      ANDROID_LOG_INFO, {logcINFO}
      ANDROID_LOG_WARN, {logcWARNING}
      ANDROID_LOG_ERROR, {logcERROR}
      ANDROID_LOG_VERBOSE, {logcVERBOSE}
      ANDROID_LOG_FATAL, {logcFATAL}
      ANDROID_LOG_DEBUG, {logcDEBUG}
      ANDROID_LOG_INFO {logcOK}
   );

procedure logi(priority: longint; const what: StdString);
begin
   SysLogWrite(priority, PAnsiChar(what));
end;

procedure logi(const what: StdString);
begin
   SysLogWrite(ANDROID_LOG_INFO, PAnsiChar(what));
end;

procedure loge(const what: StdString);
begin
   SysLogWrite(ANDROID_LOG_ERROR, PAnsiChar(what));
end;

{ TAndroidLogHandler }

constructor TAndroidLogHandler.Create();
begin
   inherited;
   Name := 'android';
   FileExtension := '';
   NoHeader := true;
   NeedOpen := false;
end;

procedure TAndroidLogHandler.Writeln(log: PLog; priority: longint; const s: StdString);
begin
   SysLogWrite(androidPriorities[priority], PAnsiChar(S));
end;

procedure TAndroidLogHandler.WritelnRaw(log: PLog; const s: StdString);
begin
   SysLogWrite(ANDROID_LOG_INFO, PAnsiChar(S));
end;

INITIALIZATION
   log.Handler.pDefault := @loghAndroid;

END.
