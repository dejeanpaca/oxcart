{
   oxeduBuild, build logging
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuildLog;

INTERFACE

   USES
      uLog, StringUtils,
      uAppInfo, appuLog,
      {oxed}
      oxeduConsole, uBuildExec;

TYPE
   { oxedTBuildLog }

   oxedTBuildLog = record
      Log: TLog;

      procedure e(const what: string);
      procedure k(const what: string);
      procedure w(const what: string);
      procedure f(const what: string);
      procedure i(const what: string);
      procedure d(const what: string);
      procedure v(const what: string);

      procedure Collapsed(const what: string);
      procedure Leave();
   end;


VAR
   oxedBuildLog: oxedTBuildLog;

IMPLEMENTATION

VAR
   oldLogCallback: TProcedure;

procedure SetupLog();
begin
   if(not oxedBuildLog.Log.Flags.Initialized) then begin
      {setup html log}
      oxedBuildLog.Log.QuickOpen(ExtractFilePath(appLog.FileName) +  'build', appInfo.GetVersionString() + ' build log', logcREWRITE, log.Handler.Standard);

      if(oxedBuildLog.Log.Error = 0) then
         log.v('Build log at ' + oxedBuildLog.Log.FileName);

      oxedBuildLog.Log.ChainLog := @consoleLog;
      BuildExec.Log := @oxedBuildLog.Log;
   end;

   {call the old log callback}
   if(oldLogCallback <> nil) then
      oldLogCallback();
end;

{ oxedTBuildLog }

procedure oxedTBuildLog.e(const what: string);
begin
   Log.e(what);
   oxedConsole.con.e(what);
end;

procedure oxedTBuildLog.k(const what: string);
begin
   Log.k(what);
   oxedConsole.con.k(what);
end;

procedure oxedTBuildLog.w(const what: string);
begin
   Log.w(what);
   oxedConsole.con.w(what);
end;

procedure oxedTBuildLog.f(const what: string);
begin
   Log.f(what);
   oxedConsole.con.f(what);
end;

procedure oxedTBuildLog.i(const what: string);
begin
   Log.i(what);
   oxedConsole.con.i(what);
end;

procedure oxedTBuildLog.d(const what: string);
begin
   Log.d(what);
   oxedConsole.con.d(what);
end;

procedure oxedTBuildLog.v(const what: string);
begin
   Log.v(what);
   oxedConsole.con.v(what);
end;

procedure oxedTBuildLog.Collapsed(const what: string);
begin
   Log.Collapsed(what);
end;

procedure oxedTBuildLog.Leave();
begin
   Log.Leave();
end;

INITIALIZATION
   log.Init(oxedBuildLog.Log);

   oldLogCallback := appLog.UseSetupCallback(@SetupLog);

FINALIZATION
   oxedBuildLog.Log.Close();
   oxedBuildLog.Log.Dispose();

END.
