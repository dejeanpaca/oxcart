{
   appuLog, application logging
   Copyright (C) 2012. Dejan Boras

   Started On:    28.11.2012.
}

{$INCLUDE oxdefines.inc}
UNIT appuLog;

INTERFACE

   USES
      uStd, uLog, uFileUtils,
      uAppInfo, appuPaths, uApp,
      oxuRunRoutines;

TYPE
   appTLog = record
     FileName: StdString;
     {callback for setting up log files}
     SetupCallback: TProcedure;

     {skip initialization}
     SkipInit: boolean;

     procedure Initialize();
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
      log.Settings.Path := appPath.Configuration.Path + 'logs' + DirectorySeparator;

      if(not FileUtils.CreateDirectory(log.Settings.Path)) then
         log.Settings.Path := appPath.Configuration.Path;

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

procedure Initialize();
begin
   if(not appLog.SkipInit) then
      appLog.Initialize();
end;

INITIALIZATION
   app.InitializationProcs.Add('log', @initialize);

END.
