{
   oxuLogHTML, sets up html logging for oX
   Copyright (C) 2012. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuLogHTML;

INTERFACE

   USES
     uAppInfo,
     {logs}
     uLog, ulogHTML, appuLog;

IMPLEMENTATION

VAR
   oldLogCallback: TProcedure;
   extlog: TLog;

procedure SetupLog();
begin
   if(not extlog.Flags.Initialized) then begin
      {setup html log}
      extlog.QuickOpen(appLog.fileName, appInfo.GetVersionString(), logcREWRITE, loghHTML);
      extlog.chainLog := stdlog.chainLog;
      stdlog.chainLog := @extlog;
   end;

   {call the old log callback}
   if(oldLogCallback <> nil) then
      oldLogCallback();
end;

INITIALIZATION
   log.Init(extlog);

   oldLogCallback := appLog.SetupCallback;
   appLog.SetupCallback := @SetupLog;

FINALIZATION
   extlog.Close();
   extlog.Dispose();

END.
