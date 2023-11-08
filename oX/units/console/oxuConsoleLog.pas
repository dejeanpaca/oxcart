{
   oxuConsoleLog, console log handler
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuConsoleLog;

INTERFACE

   USES
      sysutils, uStd, uLog,
      appuLog,
      {ox}
      uOX, oxuConsoleBackend, oxuConsole;

TYPE

   { oxTConsoleLogHandler }

   oxTConsoleLogHandler = object(TLogHandler)
      constructor Create();

      procedure Writeln(log: PLog; priority: longint; const s: StdString); virtual;
   end;

VAR
   loghOXConsole: oxTConsoleLogHandler;

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
      extlog.ChainLog := stdlog.ChainLog;
      stdlog.ChainLog := @extlog;
   end;

   {call the old log callback}
   if(oldLogCallback <> nil) then
      oldLogCallback();
end;

{ oxTConsoleLogHandler }

constructor oxTConsoleLogHandler.Create();
begin
   Name := 'ox.console';
   FileExtension := '';
   NoHeader := true;
end;

procedure oxTConsoleLogHandler.Writeln(log: PLog; priority: longint; const s: StdString);
begin
   {if log file is closing we probably already have no buffer}
   if(ox.Initialized) and (oxConsole.Console.Contents.a > 0) and (not log^.Flags.Closing) then begin
      if(priority = logcINFO) then
         oxConsole.Console.i(s)
      else if(priority = logcWARNING) then
         oxConsole.Console.w(s)
      else if(priority = logcERROR) then
         oxConsole.Console.e(s)
      else if(priority = logcVERBOSE) then
         oxConsole.Console.v(s)
      else if(priority = logcFATAL) then
         oxConsole.Console.f(s)
      else if(priority = logcDEBUG) then
         oxConsole.Console.d(s)
      else
         oxConsole.Console.i(s);
   end;
end;

INITIALIZATION
   log.Init(extlog);

   loghOXConsole.Create();

   oldLogCallback := appLog.UseSetupCallback(@SetupLog);
END.
