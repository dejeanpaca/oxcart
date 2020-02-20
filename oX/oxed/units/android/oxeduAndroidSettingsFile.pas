{
   oxeduAndroidSettingsFile
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidSettingsFile;

INTERFACE

   USES
      uStd, uLog, udvars, dvaruFile,
      {app}
      appuPaths,
      {oxed}
      uOXED, oxeduAndroidSettings;

TYPE
   { oxedTAndroidSettingsFile }

   oxedTAndroidSettingsFile = record
      function GetFn(): StdString;
      procedure Load();
      procedure Save();
   end;

VAR
   oxedAndroidSettingsFile: oxedTAndroidSettingsFile;

IMPLEMENTATION

{ oxedTPlatformSettingsFile }

function oxedTAndroidSettingsFile.GetFn(): StdString;
begin
   Result := appPath.Configuration.Path + 'android.dvar';
end;

procedure oxedTAndroidSettingsFile.Load();
var
   fn: StdString;

begin
   fn := GetFn();
   dvarf.ReadText(oxedAndroidSettings.dvg, fn);
   log.v('Loaded: ' + fn);
end;

procedure oxedTAndroidSettingsFile.Save();
var
   fn: StdString;

begin
   fn := GetFn();
   dvarf.WriteText(oxedAndroidSettings.dvg, fn);
   log.v('Saved: ' + fn);
end;

procedure init();
begin
   oxedAndroidSettingsFile.Load();
end;

procedure deinit();
begin
   oxedAndroidSettingsFile.Save();
end;

INITIALIZATION
   oxed.init.Add('android.settings_file', @init, @deinit)

END.
