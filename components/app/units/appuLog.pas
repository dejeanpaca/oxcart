{
   appuLog, application logging
   Copyright (C) 2012. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuLog;

INTERFACE

   USES
      uStd, uLog, uFileUtils,
      uAppInfo, appuPaths, uApp,
      oxuRunRoutines;

TYPE

   { appTLog }

   appTLog = record
     FileName: StdString;
     {callback for setting up log files}
     SetupCallback: TProcedure;

     {skip initialization}
     SkipInit: boolean;

     procedure Initialize();
     {use a new setup callback and return the old one}
     function UseSetupCallback(callback: TProcedure): TProcedure;
   end;

VAR
   appLog: appTLog;


IMPLEMENTATION

procedure appTLog.Initialize();
{$IFNDEF NOLOG}
var
   logFN: StdString;
{$ENDIF}

begin
   {quit if already initialized}
   if(not stdlog.Flags.Initialized) then begin
      {create directory for logs}
      log.Settings.Path := appPath.Configuration.GetLocal() + 'logs' + DirectorySeparator;

      if(not FileUtils.CreateDirectory(log.Settings.Path)) then
         log.Settings.Path := appPath.Configuration.GetLocal();

      {$IFNDEF NOLOG}
      {setup default log file}
      logFN := 'default';

      if(appInfo.NameShort <> '') then
         logFN := appInfo.NameShort;

      if(not log.settings.UseHandlerFileExtension) then
         logFN := logFN + '.log';

      FileName := logFN;
      UniqueString(FileName);

      log.InitStd(FileName, appInfo.GetVersionString(), logcREWRITE);
      {$ENDIF}
   end;

   {call other log setup routines}
   if(SetupCallback <> nil) then
      SetupCallback();
end;

function appTLog.UseSetupCallback(callback: TProcedure): TProcedure;
begin
   Result := SetupCallback;
   SetupCallback := callback;
end;

procedure Initialize();
begin
   if(not appLog.SkipInit) then
      appLog.Initialize();
end;

INITIALIZATION
   app.InitializationProcs.Add('log', @initialize);

END.
