{
   oxuConsoleLog, console log handler
   Copyright (C) 2016. Dejan Boras

   Started On:    26.12.2016.
}

{$MODE OBJFPC}{$H+}
UNIT oxuConsoleLog;

INTERFACE

   USES sysutils, uLog, appuLog,
      uOX, oxuConsoleBackend, oxuConsole;

VAR
   loghOXConsole: TLogHandler;

IMPLEMENTATION

VAR
   oldLogCallback: TProcedure;
   extlog: TLog;

procedure SetupLog();
begin
   if(not extlog.Flags.Initialized) then begin
      log.Init(extlog);

      {setup console log}
      extlog.QuickOpen(appLog.fileName, '', logcREWRITE, loghOXConsole);
      extlog.chainLog := stdlog.chainLog;
      stdlog.chainLog := @extlog;
   end;

   {call the old log callback}
   if(oldLogCallback <> nil) then
      oldLogCallback();
end;

procedure hwriteln({%H-}logf: PLog; priority: longint; const s: string);
begin
   if(priority = logcINFO) then
      oxConsole.console.i(s)
   else if(priority = logcWARNING) then
      oxConsole.console.w(s)
   else if(priority = logcERROR) then
      oxConsole.console.e(s)
   else if(priority = logcVERBOSE) then
      oxConsole.console.v(s)
   else if(priority = logcFATAL) then
      oxConsole.console.f(s)
   else if(priority = logcDEBUG) then
      oxConsole.console.d(s)
   else
      oxConsole.console.i(s);
end;

{output nothing to the console until oX is initialized, then use the actual handler method}
procedure hwritelnPreInit(logf: PLog; priority: longint; const s: string);
begin
   if(ox.Initialized) then begin
      loghOXConsole.writeln := @hwriteln;
      hwriteln(logf, priority, s);
   end;
end;

INITIALIZATION
   log.Init(extlog);

   {use the standard log handler for most operations}
   loghOXConsole := log.handler.Dummy;
   loghOXConsole.Name           := 'ox.console';
   loghOXConsole.fileExtension  := '';
   loghOXConsole.writeln        := @hwritelnPreInit;
   {nothing should be output to the file by default }
   loghOXConsole.noHeader       := true;

   oldLogCallback := appLog.setupCallback;
   appLog.setupCallback := @SetupLog;
END.

