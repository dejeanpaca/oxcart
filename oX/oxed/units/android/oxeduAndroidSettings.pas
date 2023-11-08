{
   oxeduSettings, oxed settings
   Copyright (C) 2017. Dejan Boras

   Started On:    23.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidSettings;

INTERFACE

   USES
      uStd, udvars, uFile,
      {oxed}
      uOXED, oxeduProjectManagement;

TYPE
   { oxedTAndroidSettingss }

   oxedTAndroidSettings = record
      {android package name}
      PackageName: string;

      class procedure OnLoad(); static;
      procedure Reset();
   end;

VAR
   oxedAndroidSettings: oxedTAndroidSettings;

IMPLEMENTATION

VAR
   dvPackageName: TDVar;

   dvgAndroid: TDVarGroup;

{ oxedTAndroidSettings }

class procedure oxedTAndroidSettings.OnLoad();
begin
   with oxedAndroidSettings do begin
      PackageName := '';
   end;
end;

procedure oxedTAndroidSettings.Reset();
begin

end;


INITIALIZATION
   oxedAndroidSettings.PackageName := '';

   dvgOXED.Add('android', dvgAndroid);
   dvgAndroid.Add(dvPackageName, 'package_name', dtcSINGLE, @oxedAndroidSettings.PackageName);

END.
