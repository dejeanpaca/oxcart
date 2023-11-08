{
   appudvarConfiguration
   app DVAR text configuration file support
   Copyright (C) 2012. Dejan Boras

   Started On:    08.01.2012.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appudvarConfiguration;

INTERFACE

   USES
     sysutils, uLog, udvars, dvaruFile,
     uApp, appuPaths,
     oxuRunRoutines;

TYPE

   { appTDVarTextConfiguration }

   appTDVarTextConfiguration = record
     FileName,
     Path: string;

     AutoLoad,
     AutoSave: boolean;

     function GetFN(): string;
     class procedure Load(); static;
     class procedure Save(); static;
   end;

VAR
   appDVarTextConfiguration: appTDVarTextConfiguration;

IMPLEMENTATION

{ appTDVarTextConfiguration }

function appTDVarTextConfiguration.GetFN(): string;
begin
   if(Path = '') then
      result := appPath.Configuration.Path + Filename
   else
      result := Path + Filename;
end;

class procedure appTDVarTextConfiguration.Load();
var
   fn: string;

begin
   fn := appDVarTextConfiguration.GetFN();

   dvarf.ReadText(fn);
   log.i('dvar > loaded configuration file from: ' + fn);
end;

class procedure appTDVarTextConfiguration.Save();
var
   fn: string;

begin
   fn := appDVarTextConfiguration.GetFN();

   dvarf.WriteText(fn);
   log.i('dvar > wrote configuration file to: ' + fn);
end;

procedure Load();
begin
   if(appDVarTextConfiguration.AutoLoad) then
      appDVarTextConfiguration.Load()
end;

procedure Save();
begin
   if(appDVarTextConfiguration.AutoSave) then
      appDVarTextConfiguration.Save();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   appDVarTextConfiguration.FileName := 'dvar.cfg';
   appDVarTextConfiguration.AutoLoad := true;
   appDVarTextConfiguration.AutoSave := true;

   app.InitializationProcs.Add(initRoutines, 'dvar.textload', @load, @save);

END.

