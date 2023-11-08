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
      {is android support enabled}
      Enabled,
      {should you manage android files yourself}
      ManualFileManagement: boolean;

      class procedure Reset(); static;
   end;

VAR
   oxedAndroidSettings: oxedTAndroidSettings;

IMPLEMENTATION

VAR
   dvEnabled,
   dvManualFileManagement,
   dvPackageName: TDVar;

{ oxedTAndroidSettings }

class procedure oxedTAndroidSettings.Reset();
begin
  with oxedAndroidSettings do begin
     PackageName := '';
     ManualFileManagement := false;
     Enabled := false;
  end;
end;


INITIALIZATION
   oxedTAndroidSettings.Reset();

   dvar.Init(oxedAndroidSettings.dvg, 'android');

   dvgOXED.Add(dvEnabled, 'enabled', dtcBOOL, @oxedAndroidSettings.Enabled);

   oxedAndroidSettings.dvg.Add(dvManualFileManagement, 'manual_file_management', dtcBOOL, @oxedAndroidSettings.ManualFileManagement);
   oxedAndroidSettings.dvg.Add(dvPackageName, 'package_name', dtcSTRING, @oxedAndroidSettings.PackageName);

   oxedProjectManagement.OnNew.Add(@oxedAndroidSettings.Reset);
   oxedProjectManagement.OnClosed.Add(@oxedAndroidSettings.Reset);

END.
