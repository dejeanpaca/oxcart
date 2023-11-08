{
   oxeduAndroidSettingsFile, oxed settings
   Copyright (C) 2019. Dejan Boras

   Started On:    17.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidSettingsFile;

INTERFACE

   USES
      dvaruFile,
      {oxed}
      oxeduProjectManagement, oxeduProject, oxeduAndroidSettings;

CONST
   OXED_ANDROID_SETTINGS_FILE = 'android.dvar';

TYPE
   { oxedTAndroidSettingsFile }

   oxedTAndroidSettingsFile = record
     class function GetFn(): string; static;
     class procedure Load(); static;
     class procedure Save(); static;
   end;

IMPLEMENTATION

{ oxedTAndroidSettingsFile }

class function oxedTAndroidSettingsFile.GetFn(): string;
begin
   Result := oxedProject.GetConfigFilePath(OXED_ANDROID_SETTINGS_FILE);
end;

class procedure oxedTAndroidSettingsFile.Load();
begin
   if(oxedAndroidSettings.Enabled) then
      dvarf.ReadText(oxedAndroidSettings.dvg, GetFn());
end;

class procedure oxedTAndroidSettingsFile.Save();
begin
   if(oxedAndroidSettings.Enabled) then
      dvarf.WriteText(oxedAndroidSettings.dvg, GetFn());
end;

INITIALIZATION
   oxedProjectManagement.OnLoadProject.Add(@oxedTAndroidSettingsFile.Load);
   oxedProjectManagement.OnSaveProject.Add(@oxedTAndroidSettingsFile.Save);

END.
