{
   oxeduPlatformSettingsFile, per platform settings file
   Copyright (C) 2019. Dejan Boras

   Started On:    29.10.2019
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPlatformSettingsFile;

INTERFACE

   USES
      dvaruFile, udvars,
      {oxed}
      oxeduProjectManagement, oxeduProject, oxeduPlatform;

TYPE
   { oxedTPlatformSettingsFile }

   oxedTPlatformSettingsFile = record
     class function GetFn(var platform: oxedTPlatform): string; static;
     class procedure Load(var platform: oxedTPlatform; var dvg: TDVarGroup); static;
     class procedure Save(var platform: oxedTPlatform; var dvg: TDVarGroup); static;
   end;

IMPLEMENTATION

{ oxedTPlatformSettingsFile }

class function oxedTPlatformSettingsFile.GetFn(var platform: oxedTPlatform): string;
begin
   Result := oxedProject.GetConfigFilePath(platform.Id + '.dvar');
end;

class procedure oxedTPlatformSettingsFile.Load(var platform: oxedTPlatform; var dvg: TDVarGroup);
begin
   if(platform.Enabled) then
      dvarf.ReadText(dvg, GetFn(platform));
end;

class procedure oxedTPlatformSettingsFile.Save(var platform: oxedTPlatform; var dvg: TDVarGroup);
begin
   if(platform.Enabled) then
      dvarf.WriteText(dvg, GetFn(platform));
end;

END.
