{
   oxeduAndroidSettings, oxed android settings
   Copyright (C) 2019. Dejan Boras

   Started On:    17.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidSettings;

INTERFACE

   USES
      uStd, udvars, uFile, StringUtils, uLog,
      {oxed}
      uOXED, oxeduProjectManagement;

TYPE
   { oxedTAndroidSettingss }

   oxedTAndroidSettings = record
      dvg: TDVarGroup;

      SDKPath,
      UsedNDK,
      NDKPath: StdString;

      Project: record
         dvg: TDVarGroup;

         { PROJECT SETTINGS }

         {android package name}
         PackageName: StdString;
         {should you manage android files yourself}
         ManualFileManagement: boolean;
      end;

      procedure ProjectReset();
      procedure Validate();

      {get the ndk path}
      function GetNDKPath(): StdString;
   end;

VAR
   oxedAndroidSettings: oxedTAndroidSettings;

IMPLEMENTATION

VAR
   dvManualFileManagement,
   dvPackageName,
   dvSDKPath: TDVar;

{ oxedTAndroidSettings }

procedure oxedTAndroidSettings.ProjectReset();
begin
  Project.PackageName := '';
  Project.ManualFileManagement := false;
end;

procedure oxedTAndroidSettings.Validate();
begin
   SDKPath := IncludeTrailingPathDelimiterNonEmpty(SDKPath);

   if(SDKPath = '') then
      log.w('Android SDK path not set')
   else begin
      if(UsedNDK = '') and (NDKPath = '') then
         log.w('Android NDK is not set');
   end;
end;

function oxedTAndroidSettings.GetNDKPath(): StdString;
begin
   if(NDKPath <> '') then
      Result := NDKPath
   else
      Result := SDKPath + UsedNDK;
end;

procedure preOpen();
begin
   oxedAndroidSettings.ProjectReset();
end;

INITIALIZATION
   oxedAndroidSettings.ProjectReset();
   oxedProjectManagement.OnPreOpen.Add(@preOpen);

   dvar.Init(oxedAndroidSettings.dvg, 'android');
   dvar.Init(oxedAndroidSettings.Project.dvg, 'android');

   oxedAndroidSettings.Project.dvg.Add(dvManualFileManagement, 'manual_file_management', dtcBOOL, @oxedAndroidSettings.Project.ManualFileManagement);
   oxedAndroidSettings.Project.dvg.Add(dvPackageName, 'package_name', dtcSTRING, @oxedAndroidSettings.Project.PackageName);

   oxedAndroidSettings.dvg.Add(dvSDKPath, 'sdk_path', dtcSTRING, @oxedAndroidSettings.SDKPath);

END.
