{
   appudvarConfiguration, app DVAR text configuration file support
   Copyright (C) 2012. Dejan Boras

   Started On:    08.01.2012.
}

{$INCLUDE oxheader.inc}
UNIT appudvarConfiguration;

INTERFACE

   USES
     udvars, uApp,
     {ox}
     oxuDvarFile;

TYPE

   { appTDVarTextConfiguration }

   appTDVarTextConfiguration = record
      AutoLoad,
      AutoSave: boolean;

      DvarFile: oxTDvarFile;
   end;

VAR
   appDVarTextConfiguration: appTDVarTextConfiguration;

IMPLEMENTATION

procedure Load();
begin
   if(appDVarTextConfiguration.AutoLoad) then
      appDVarTextConfiguration.DvarFile.Load();
end;

procedure Save();
begin
   if(appDVarTextConfiguration.AutoSave) then
      appDVarTextConfiguration.DvarFile.Save();
end;

INITIALIZATION
   appDVarTextConfiguration.DvarFile.Create();
   appDVarTextConfiguration.DvarFile.FileName := 'config.dvar';
   appDVarTextConfiguration.DvarFile.dvg := @dvar.dvars;
   appDVarTextConfiguration.AutoLoad := true;
   appDVarTextConfiguration.AutoSave := true;

   app.InitializationProcs.Add('dvar.textload', @load, @save);

END.

