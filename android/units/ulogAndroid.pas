{
   ulogAndroid, uLog android handler
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ulogAndroid;

INTERFACE

   USES
      uStd, uLog;

TYPE

   { TAndroidLogHandler }

   TAndroidLogHandler = object(TLogHandler)
      constructor Create();
      procedure Writeln({%H-}logf: PLog; priority: longint; const s: StdString); virtual;
      procedure WritelnRaw({%H-}log: PLog; const s: StdString); virtual;
      procedure EnterSection({%H-}log: PLog; const s: StdString; collapsed: boolean); virtual;
   end;

VAR
   loghAndroid: TAndroidLogHandler;

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

{ TAndroidLogHandler }

constructor TAndroidLogHandler.Create();
begin
   inherited;

   Name := 'android';
   FileExtension := '';
   NoHeader := true;
   NeedOpen := false;
   ThreadSafe := true;
end;

procedure TAndroidLogHandler.Writeln(logf: PLog; priority: longint; const s: StdString);
begin
   {add tabs to signify a section}
   if(logf^.SectionLevel > 0) then begin
      SysLogWrite(androidPriorities[priority], PAnsiChar(copy(log.SpaceString, 1, logf^.SectionLevel * 2) + s));
   end else
   {level 0 section needs no tabs}
      SysLogWrite(androidPriorities[priority], PAnsiChar(s));
end;

procedure TAndroidLogHandler.WritelnRaw(log: PLog; const s: StdString);
begin
   SysLogWrite(ANDROID_LOG_INFO, PAnsiChar(s));
end;

procedure TAndroidLogHandler.EnterSection(log: PLog; const s: StdString; collapsed: boolean);
begin
   log^.HandlerWriteln(logcINFO, '> ' + s, true);
end;

INITIALIZATION
   loghAndroid.Create();
   log.SetDefaultHandler(loghAndroid);

   {redirect console log to android log}
   consoleLog.QuickOpen('console', '', logcREWRITE, loghAndroid);

END.
