{
   oxeduAndroidProjectFiles, android project files
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduAndroidProjectFiles;

INTERFACE

   USES
      uStd, uLog, uFileUtils, uDirectoryCopier, StringUtils, uBuild,
      {oxed}
      oxeduProject, oxeduAndroidSettings;

TYPE
   { oxedTAndroidProjectFiles }

   oxedTAndroidProjectFiles = record
      procedure Deploy(const destination: StdString = '');

      {deploys project files to the configured project files path}
      procedure DeployTemplate(const destination: StdString = '');
      {replace values in files with project values}
      procedure UpdateValues(const destination: StdString = '');
   end;

VAR
   oxedAndroidProjectFiles: oxedTAndroidProjectFiles;

IMPLEMENTATION

{ oxedTAndroidProjectFiles }

procedure oxedTAndroidProjectFiles.Deploy(const destination: StdString);
begin
   if(oxedAndroidSettings.Project.PackageName = '') then begin
      log.e('android > No package name set. Cannot deploy project.');
      exit;
   end;

   oxedAndroidProjectFiles.DeployTemplate(destination);
   oxedAndroidProjectFiles.UpdateValues(destination);
end;

procedure oxedTAndroidProjectFiles.DeployTemplate(const destination: StdString);
var
   path,
   source: StdString;

begin
   if(destination <> '') then
      path := IncludeTrailingPathDelimiterNonEmpty(destination)
   else
      path := oxedAndroidSettings.GetProjectFilesPath();

   source := build.RootPath + 'android' + DirectorySeparator + 'project';

   if(not FileUtils.DirectoryExists(source)) then begin
      log.e('Cannot find android project files template directory in: ' + source);
      exit;
   end;

   if(FileUtils.DirectoryExists(path)) then begin
      log.e('Cannot copy android project files. Target directory already exists: ' + path);
      exit;
   end;

   log.v('Android project files template source: ' + source);
   log.i('Deploying android project files to: ' + path);

   CopyDirectory(source, path);
end;

procedure oxedTAndroidProjectFiles.UpdateValues(const destination: StdString);
var
   dest: StdString;
   kv: array[0..2] of TStringPair;

begin
   dest := IncludeTrailingPathDelimiterNonEmpty(destination);

   ZeroOut(kv, SizeOf(kv));

   kv[0].Assign('$APP_NAME', oxedProject.Name);
   kv[1].Assign('$PACKAGE_ID', oxedAndroidSettings.Project.PackageName);
   kv[2].Assign('$TARGET_SDK_VERSION', sf(oxedAndroidSettings.Project.TargetVersion));

   FileUtils.ReplaceInFile(dest + 'settings.gradle', kv);
   FileUtils.ReplaceInFile(dest + 'app' + DirSep + 'build.gradle', kv);
   FileUtils.ReplaceInFile(dest + ReplaceDirSeparatorsf('app\src\main\AndroidManifest.xml'), kv);
   FileUtils.ReplaceInFile(dest + ReplaceDirSeparatorsf('app\src\main\res\values\strings.xml'), kv);
end;

END.
