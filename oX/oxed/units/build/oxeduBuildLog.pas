{
   oxeduBuild, build logging
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuildLog;

INTERFACE

   USES
      uLog, StringUtils,
      uAppInfo, appuLog,
      {oxed}
      oxeduConsole;

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
   end;

   {call the old log callback}
   if(oldLogCallback <> nil) then
      oldLogCallback();
end;

{ oxedTBuildLog }

procedure oxedTBuildLog.e(const what: string);
begin
   Log.e(what);
   oxedConsole.ne(what);
end;

procedure oxedTBuildLog.k(const what: string);
begin
   Log.k(what);
   oxedConsole.nk(what);
end;

procedure oxedTBuildLog.w(const what: string);
begin
   Log.w(what);
   oxedConsole.nw(what);
end;

procedure oxedTBuildLog.f(const what: string);
begin
   Log.f(what);
   oxedConsole.nf(what);
end;

procedure oxedTBuildLog.i(const what: string);
begin
   Log.i(what);
   oxedConsole.ni(what);
end;

procedure oxedTBuildLog.d(const what: string);
begin
   Log.d(what);
   oxedConsole.nd(what);
end;

procedure oxedTBuildLog.v(const what: string);
begin
   Log.v(what);
   oxedConsole.nv(what);
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

   oldLogCallback := appLog.setupCallback;
   appLog.setupCallback := @SetupLog;

FINALIZATION
   oxedBuildLog.Log.Close();
   oxedBuildLog.Log.Dispose();

END.
