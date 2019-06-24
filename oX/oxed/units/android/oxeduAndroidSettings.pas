{
   oxeduAndroidSettings, oxed android settings
   Copyright (C) 2019. Dejan Boras

   Started On:    17.06.2019.
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
      dvg: TDVarGroup;

      {android package name}
      PackageName: StdString;
      {should you manage android files yourself}
      ManualFileManagement: boolean;

      class procedure Reset(); static;
   end;

VAR
   oxedAndroidSettings: oxedTAndroidSettings;

IMPLEMENTATION

VAR
   dvPackageName: TDVar;

{ oxedTAndroidSettings }

class procedure oxedTAndroidSettings.Reset();
begin
  with oxedAndroidSettings do begin
     PackageName := '';
     ManualFileManagement := false;
  end;
end;


INITIALIZATION
   oxedTAndroidSettings.Reset();

   dvar.Init(oxedAndroidSettings.dvg, 'android');

   oxedAndroidSettings.dvg.Add(dvPackageName, 'package_name', dtcSTRING, @oxedAndroidSettings.PackageName);

   oxedProjectManagement.OnNew.Add(@oxedAndroidSettings.Reset);
   oxedProjectManagement.OnClosed.Add(@oxedAndroidSettings.Reset);

END.
