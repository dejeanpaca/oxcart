{
   oxeduPlatformSettingsFile, per platform settings file
   Copyright (C) 2019. Dejan Boras

   Started On:    29.10.2019
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPlatformSettingsFile;

INTERFACE

   USES
      uStd, uLog, udvars, dvaruFile,
      {oxed}
      oxeduProjectManagement, oxeduProject, oxeduPlatform;

TYPE
   { oxedTPlatformSettingsFile }

   oxedTPlatformSettingsFile = record
      function GetFn(var platform: oxedTPlatform): string;
      procedure Load(var platform: oxedTPlatform);
      procedure Save(var platform: oxedTPlatform);
   end;

VAR
   oxedPlatformSettingsFile: oxedTPlatformSettingsFile;

IMPLEMENTATION

{ oxedTPlatformSettingsFile }

function oxedTPlatformSettingsFile.GetFn(var platform: oxedTPlatform): string;
begin
   Result := oxedProject.GetConfigFilePath(platform.Id + '.dvar');
end;

procedure oxedTPlatformSettingsFile.Load(var platform: oxedTPlatform);
var
   dvg: PDVarGroup;
   fn: StdString;

begin
   if(platform.Enabled) then begin
      dvg := platform.GetDvarGroup();

      if(dvg <> nil) then begin
         fn := GetFn(platform);
         dvarf.ReadText(dvg^, fn);
         log.v('Loaded ' + fn);
      end;
   end;
end;

procedure oxedTPlatformSettingsFile.Save(var platform: oxedTPlatform);
var
   dvg: PDVarGroup;
   fn: StdString;

begin
   if(platform.Enabled) then begin
      dvg := platform.GetDvarGroup();

      if(dvg <> nil) then begin
         fn := GetFn(platform);
         dvarf.WriteText(dvg^, fn);
         log.v('Saved ' + fn);
      end;
   end;
end;

END.
