{
   oxeduAndroidProjectFiles, android project files
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidProjectFiles;

INTERFACE

   USES
      uStd, uLog, uFileUtils, StringUtils, uBuild,
      {oxed}
      oxeduAndroidSettings;

TYPE
   { oxedTAndroidProjectFiles }

   oxedTAndroidProjectFiles = record
      {deploys project files to the configured project files path}
      procedure Deploy(const destination: StdString = '');
   end;

VAR
   oxedAndroidProjectFiles: oxedTAndroidProjectFiles;

IMPLEMENTATION

{ oxedTAndroidProjectFiles }

procedure oxedTAndroidProjectFiles.Deploy(const destination: StdString);
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

   FileUtils.CopyDirectory(source, path);
end;

END.
