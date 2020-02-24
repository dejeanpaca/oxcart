{
   appudvarConfiguration, app DVAR text configuration file support
   Copyright (C) 2012. Dejan Boras
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
   appdvarConfiguration: appTDVarTextConfiguration;

IMPLEMENTATION

procedure Load();
begin
   if(appdvarConfiguration.AutoLoad) then
      appdvarConfiguration.DvarFile.Load();
end;

procedure Save();
begin
   if(appdvarConfiguration.AutoSave) then
      appdvarConfiguration.DvarFile.Save();
end;

INITIALIZATION
   appdvarConfiguration.DvarFile.Create();
   appdvarConfiguration.DvarFile.FileName := 'config.dvar';
   appdvarConfiguration.DvarFile.dvg := @dvar.dvars;
   appdvarConfiguration.AutoLoad := true;
   appdvarConfiguration.AutoSave := true;

   app.InitializationProcs.Add('dvar.textload', @load, @save);

END.

