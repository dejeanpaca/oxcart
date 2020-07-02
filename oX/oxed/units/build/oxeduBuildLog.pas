{
   oxeduBuild, build logging
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuildLog;

INTERFACE

   USES
      uLog, StringUtils,
      uAppInfo, appuLog;

VAR
   oxedBuildLog: TLog;

IMPLEMENTATION

VAR
   oldLogCallback: TProcedure;

procedure SetupLog();
begin
   if(not oxedBuildLog.Flags.Initialized) then begin
      {setup html log}
      oxedBuildLog.QuickOpen(ExtractFilePath(appLog.FileName) +  'build', appInfo.GetVersionString() + ' build log', logcREWRITE, log.Handler.Standard);

      if(oxedBuildLog.Error = 0) then
         log.v('Build log at ' + oxedBuildLog.FileName);
   end;

   {call the old log callback}
   if(oldLogCallback <> nil) then
      oldLogCallback();
end;

INITIALIZATION
   log.Init(oxedBuildLog);

   oldLogCallback := appLog.setupCallback;
   appLog.setupCallback := @SetupLog;

FINALIZATION
   oxedBuildLog.Close();
   oxedBuildLog.Dispose();

END.
