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

      Project: record
         dvg: TDVarGroup;

         { PROJECT SETTINGS }

         {android package name}
         PackageName: StdString;
         {should you manage android files yourself}
         ManualFileManagement: boolean;
      end;

      class procedure Reset(); static;
   end;

VAR
   oxedAndroidSettings: oxedTAndroidSettings;

IMPLEMENTATION

VAR
   dvManualFileManagement,
   dvPackageName: TDVar;

{ oxedTAndroidSettings }

class procedure oxedTAndroidSettings.Reset();
begin
  with oxedAndroidSettings do begin
     Project.PackageName := '';
     Project.ManualFileManagement := false;
  end;
end;

procedure preOpen();
begin
   oxedAndroidSettings.Reset();
end;

INITIALIZATION
   oxedTAndroidSettings.Reset();
   oxedProjectManagement.OnPreOpen.Add(@preOpen);

   dvar.Init(oxedAndroidSettings.dvg, 'android');
   dvar.Init(oxedAndroidSettings.Project.dvg, 'android');

   oxedAndroidSettings.Project.dvg.Add(dvManualFileManagement, 'manual_file_management', dtcBOOL, @oxedAndroidSettings.Project.ManualFileManagement);
   oxedAndroidSettings.Project.dvg.Add(dvPackageName, 'package_name', dtcSTRING, @oxedAndroidSettings.Project.PackageName);

END.
