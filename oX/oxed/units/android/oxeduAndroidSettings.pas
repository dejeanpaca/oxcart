{
   oxeduAndroidSettings, oxed android settings
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidSettings;

INTERFACE

   USES
      sysutils, uStd, udvars, uFile, StringUtils, uLog, uFileUtils,
      {oxed}
      uOXED, oxeduProject, oxeduProjectManagement,
      oxeduAndroid;

CONST
   {android 5.1 is our default target version}
   OXED_ANDROID_DEFAULT_TARGET_VERSION = 22;

TYPE
   { oxedTAndroidSettings }

   oxedTAndroidSettings = record
      dvg: TDVarGroup;

      SDKPath,
      UsedNDK,
      NDKPath: StdString;

      AvailableNDKs: TSimpleStringList;

      Project: record
         dvg: TDVarGroup;

         { PROJECT SETTINGS }

         {android package name}
         PackageName,
         {project files path when manual file management is enabled}
         ProjectFilesPath: StdString;
         {should you manage android files yourself}
         ManualFileManagement: boolean;

         {target android version}
         TargetVersion: loopint;

         {cpu type to use with the emulator}
         EmulatorCPUType: oxedTAndroidCPUType;
      end;

      procedure ProjectReset();
      procedure Validate();
      procedure Setup();

      {get the ndk path}
      function GetNDKPath(): StdString;
      {get the ndk installation path within the SDK}
      function GetNDKPathInSDK(): StdString;

      {get the project files path}
      function GetProjectFilesPath(): StdString;

      {get current cpu type}
      function GetCPUType(): oxedTAndroidCPUType;
   end;

VAR
   oxedAndroidSettings: oxedTAndroidSettings;

IMPLEMENTATION

VAR
   { project settings }

   dvTargetVersion,
   dvManualFileManagement,
   dvPackageName,
   dvEmulatorCPUType,
   dvProjectFilesPath,

   { general settings }

   dvSDKPath,
   dvNDKPath,
   dvUsedNDK: TDVar;

{ oxedTAndroidSettings }

procedure oxedTAndroidSettings.ProjectReset();
begin
   Project.PackageName := '';
   Project.ManualFileManagement := false;
   Project.ProjectFilesPath := '';
   Project.TargetVersion := OXED_ANDROID_DEFAULT_TARGET_VERSION;
end;

procedure oxedTAndroidSettings.Validate();
begin
   if(SDKPath = '') then
      log.w('android > SDK path not set')
   else begin
      if(UsedNDK = '') and (NDKPath = '') then
         log.w('android > NDK is not set');
   end;
end;

procedure oxedTAndroidSettings.Setup();
var
   i: loopint;
   list: TFileDescriptorList;
   basePath: StdString;

begin
   SDKPath := IncludeTrailingPathDelimiterNonEmpty(SDKPath);

   if(SDKPath = '') then
      exit;

   basePath := GetNDKPathInSDK();

   FileUtils.FindDirectories(basePath, 0, list);

   oxedAndroidSettings.AvailableNDKs.Dispose();

   if(list.n > 0) then begin
      FileUtils.SortDirectoriesFirst(list);

      for i := 0 to list.n - 1 do begin
         oxedAndroidSettings.AvailableNDKs.Add(list.List[i].Name);
         log.v('android > found ndk: ' + list.List[i].Name);
      end;
   end else
      log.w('android > No installed NDK found in SDK path: ' + basePath);

   {set an NDK for use}
   if(NDKPath = '') and (UsedNDK = '') then begin
      UsedNDK := oxedAndroidSettings.AvailableNDKs.List[oxedAndroidSettings.AvailableNDKs.n - 1];
      log.i('android > Auto set NDK path: ' + UsedNDK);
   end;
end;

function oxedTAndroidSettings.GetNDKPath(): StdString;
begin
   if(NDKPath <> '') then
      Result := NDKPath
   else
      Result := GetNDKPathInSDK() + UsedNDK;
end;

function oxedTAndroidSettings.GetNDKPathInSDK(): StdString;
begin
   Result := SDKPath + 'ndk' + DirectorySeparator;
end;

function oxedTAndroidSettings.GetProjectFilesPath(): StdString;
begin
   if(not Project.ManualFileManagement) then
      {TODO: Set the project files path from temporary project}
      Result := oxedProject.Path + Project.ProjectFilesPath
   else
      Result := oxedProject.Path + Project.ProjectFilesPath;
end;

function oxedTAndroidSettings.GetCPUType(): oxedTAndroidCPUType;
begin
   Result := oxedAndroidSettings.Project.EmulatorCPUType;
end;

procedure loadedProject();
begin
   {make sure cpu type is not set to a funky value in the config file}
   if(loopint(oxedAndroidSettings.Project.EmulatorCPUType) > loopint(high(oxedTAndroidCPUType))) then
      oxedAndroidSettings.Project.EmulatorCPUType := ANDROID_CPU_ARM;
end;

procedure preOpen();
begin
   oxedAndroidSettings.ProjectReset();
end;

INITIALIZATION
   oxedAndroidSettings.ProjectReset();
   oxedProjectManagement.OnPreOpen.Add(@preOpen);
   oxedProjectManagement.OnLoadedProject.Add(@loadedProject);

   dvar.Init(oxedAndroidSettings.dvg, 'android');
   dvar.Init(oxedAndroidSettings.Project.dvg, 'android');

   TSimpleStringList.Initialize(oxedAndroidSettings.AvailableNDKs);

   oxedAndroidSettings.Project.dvg.Add(dvManualFileManagement, 'manual_file_management', dtcBOOL, @oxedAndroidSettings.Project.ManualFileManagement);
   oxedAndroidSettings.Project.dvg.Add(dvPackageName, 'package_name', dtcSTRING, @oxedAndroidSettings.Project.PackageName);
   oxedAndroidSettings.Project.dvg.Add(dvEmulatorCPUType, 'emulator_cpu_type', dtcENUM, @oxedAndroidSettings.Project.EmulatorCPUType);
   oxedAndroidSettings.Project.dvg.Add(dvTargetVersion, 'target_version', dtcLOOPINT, @oxedAndroidSettings.Project.TargetVersion);
   oxedAndroidSettings.Project.dvg.Add(dvProjectFilesPath, 'project_files_path', dtcSTRING, @oxedAndroidSettings.Project.ProjectFilesPath);

   oxedAndroidSettings.dvg.Add(dvSDKPath, 'sdk_path', dtcSTRING, @oxedAndroidSettings.SDKPath);
   oxedAndroidSettings.dvg.Add(dvNDKPath, 'ndk_path', dtcSTRING, @oxedAndroidSettings.NDKPath);
   oxedAndroidSettings.dvg.Add(dvUsedNDK, 'used_ndk', dtcSTRING, @oxedAndroidSettings.UsedNDK);

END.
