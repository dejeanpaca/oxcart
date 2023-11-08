{
   oxeduAndroidSettingsFile
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
   oxedAndroidSettings.Setup();
   oxedAndroidSettings.Validate();
end;

procedure deinit();
begin
   oxedAndroidSettingsFile.Save();
end;

INITIALIZATION
   oxedAndroidSettingsFile.Create(oxedAndroidSettings.dvg);
   oxedAndroidSettingsFile.FileName := 'android.dvar';

   oxed.init.Add('android.settings_file', @init, @deinit)

END.
