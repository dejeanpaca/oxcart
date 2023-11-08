{
   ulogAndroid, android log handler
   Copyright (C) 2011. Dejan Boras

   Started On:    24.12.2011.
}

{ ANDROID LOG HANDLER }
{$MODE OBJFPC}{$H+}
UNIT ulogAndroid;

INTERFACE

   USES uLog;

VAR
   loghAndroid: TLogHandler;

IMPLEMENTATION

CONST
	andrLogTypeRemaps: array[0..6] of longint = (
   {logcINFO}   	ANDROID_LOG_INFO,
   {logcWARNING}  ANDROID_LOG_WARN,
   {logcERROR} 	ANDROID_LOG_ERROR,
   {logcVERBOSE}  ANDROID_LOG_VERBOSE,
   {logcFATAL} 	ANDROID_LOG_FATAL,
   {logcDEBUG}	   ANDROID_LOG_DEBUG,
   {logcOK}   	   ANDROID_LOG_INFO);

procedure andrwriteln(logf: PLog; priority: longint; const s: string; nochainlog: boolean);
var
   androidPriority: longint;

begin
	androidPriority := ANDROID_LOG_INFO;

	if(priority >= 0) and (priority <= high(andrLogTypeRemaps)) then
	   androidPriority := andrLogTypeRemaps[priority];

   SysLogWrite(androidPriority, PAnsiChar(logf^.tag), PAnsiChar(s));

   if(logf^.chainLog <> nil) and (not nochainlog) then
      logf^.chainLog^.HandlerWriteln(priority, s, false);
end;

procedure andrwritelnraw(logf: PLog; const s: string);
begin
   SysLogWrite(ANDROID_LOG_INFO, PAnsiChar(logf^.tag), PAnsiChar(s));
end;

procedure andrEnterSection(logf: PLog; const s: string);
begin
   logf^.HandlerWritelnRaw('> ' + s);

   if(logf^.chainLog <> nil) then
      logf^.chainLog^.Enter(s);
end;

procedure andrLeaveSection(logf: PLog);
begin
   logf^.HandlerWritelnRaw(' <');

   if(logf^.chainLog <> nil) then
      logf^.chainLog^.Leave();
end;

procedure initHandler();
begin
   loghAndroid := log.handler.Dummy;
   loghAndroid.Name           := 'android';
   loghAndroid.needOpen       := false;
   loghAndroid.writeln        := @andrwriteln;
   loghAndroid.writelnraw     := @andrwritelnraw;
   loghAndroid.enterSection   := @andrEnterSection;
   loghAndroid.leaveSection   := @andrLeaveSection;

   log.handler.pDefault := @loghAndroid;
end;

INITIALIZATION
   initHandler();

END.
