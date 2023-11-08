{
   oxeduAndroidSettingsFile
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidSettingsFile;

INTERFACE

   USES
      uStd, uLog, udvars,
      {app}
      appuPaths,
      {oxed}
      uOXED, oxeduAndroidSettings, oxuDvarFile;

VAR
   oxedAndroidSettingsFile: oxTDvarFile;

IMPLEMENTATION

procedure init();
begin
   oxedAndroidSettingsFile.Load();
end;

procedure deinit();
begin
   oxedAndroidSettingsFile.Save();
end;

INITIALIZATION
   oxedAndroidSettingsFile.Create();
   oxedAndroidSettingsFile.FileName := 'android.dvar';
   oxedAndroidSettingsFile.dvg := @oxedAndroidSettings.dvg;

   oxed.init.Add('android.settings_file', @init, @deinit)

END.