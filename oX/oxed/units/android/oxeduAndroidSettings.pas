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

      class procedure Reset(); static;
   end;

VAR
   oxedAndroidSettings: oxedTAndroidSettings;

IMPLEMENTATION

VAR
   dvPackageName: TDVar;

   dvgAndroid: TDVarGroup;

{ oxedTAndroidSettings }

class procedure oxedTAndroidSettings.Reset();
begin
  with oxedAndroidSettings do begin
     PackageName := '';
  end;
end;


INITIALIZATION
   oxedAndroidSettings.PackageName := '';

   dvgOXED.Add('android', dvgAndroid);
   dvgAndroid.Add(dvPackageName, 'package_name', dtcSINGLE, @oxedAndroidSettings.PackageName);

   oxedProjectManagement.OnNew.Add(@oxedAndroidSettings.Reset);
   oxedProjectManagement.OnClosed.Add(@oxedAndroidSettings.Reset);

END.
