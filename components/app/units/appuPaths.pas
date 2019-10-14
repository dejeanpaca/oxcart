{
   appuPaths, handling of common file paths
   Copyright (C) 2011. Dejan Boras

   Started On:    30.04.2011.
}

{$INCLUDE oxdefines.inc}
UNIT appuPaths;

INTERFACE

   USES
      uStd,
      {$IFDEF UNIX}BaseUnix,{$ENDIF}
      {$IFDEF WINDOWS}windows,{$ENDIF}
      sysutils, uFileUtils, StringUtils, ConsoleUtils,
      uAppInfo, uApp,
      oxuRunRoutines;

TYPE
   appTPathType = (
      appPATH_CONFIG, {configuration path}
      appPATH_CONFIG_SHARED, {shared configuration for all users}
      appPATH_HOME, {user profile home}
      appPATH_TEMP, {temporary files directory}
      appPATH_DOCUMENTS {documents directory}
   );

   appTSystemPath = record
      Name,
      Path: StdString;
   end;

   appTSystemPaths = array of appTSystemPath;

   { appTPath }

   appTPath = record
      Configuration: record
         {will the organization name be used for configuration directory}
         UseOrganization,
         {has the configuration directory been created}
         Created,
         {will not initialize the application}
         SkipInit: boolean;

         {configuration prefix directory}
         Prefix,
         {configuration path}
         Path,
         {preset configuration path}
         Preset: StdString;
      end;

      {return path for a specified constant, or nothing if not found}
      function Get(c: appTPathType): StdString;
      {creates the configuration directory}
      function HomeConfigurationDir(const dir: StdString): StdString;
      {creates the configuration directory}
      function CreateConfiguration(): boolean;
      {get the executable path}
      function GetExecutablePath(): StdString;

      {get a list of system paths}
      function GetSystemPaths(): appTSystemPaths;
   end;

VAR
   appPath: appTPath;

IMPLEMENTATION

function appTPath.Get(c: appTPathType): StdString;
var
   path: StdString = '';
   
begin
   {check for preset path}
   if(c = appPATH_CONFIG) and (Configuration.Preset <> '') then
      exit(Configuration.Preset);

   {$IFDEF WINDOWS}
   if(c = appPATH_CONFIG) then
      path := GetUTF8EnvironmentVariable('APPDATA')
   else if(c = appPATH_HOME) then
      path := GetUTF8EnvironmentVariable('USERPROFILE')
   else if(c = appPATH_CONFIG_SHARED) then
      path := GetUTF8EnvironmentVariable('ALLUSERSPROFILE')
   else if(c = appPATH_DOCUMENTS) then
      path := IncludeTrailingPathDelimiterNonEmpty(GetUTF8EnvironmentVariable('USERPROFILE')) + 'Documents'
   else if(c = appPATH_TEMP) then
      path := GetUTF8EnvironmentVariable('TEMP');
   {$ENDIF}

   {$IFDEF UNIX} {also includes darwin}
   if(c = appPATH_CONFIG) or (c = appPATH_HOME) or (c = appPATH_CONFIG_SHARED) then
      path := GetUTF8EnvironmentVariable('HOME')
   else if(c = appPATH_DOCUMENTS) then
      path := IncludeTrailingPathDelimiterNonEmpty(GetUTF8EnvironmentVariable('HOME')) + 'Documents';
   {$ENDIF}

   {$IFNDEF WINDOWS}
   if(c = appPATH_TEMP) then
      path := GetUTF8EnvironmentVariable('TEMP');
   {$ENDIF}

   {add a directory separator to the end if the path is not empty}
   path := IncludeTrailingPathDelimiterNonEmpty(path);

   {return path}
   Result := path;
end;

function appTPath.HomeConfigurationDir(const dir: StdString): StdString;
var
   createdPath: StdString;

begin
   createdPath := appPath.Get(appPATH_CONFIG) + dir + DirectorySeparator;

   CreateDir(createdPath);

   Result := createdPath;
end;

{create the configuration directory}
function appTPath.CreateConfiguration(): boolean;
var
   createdPath,
   name: StdString;

begin
   if(not Configuration.Created) then begin
      if(Configuration.Preset = '') then begin
         {determine name of the configuration directory}
         if(Configuration.Path = '') then begin
            name := '.';

            if(configuration.prefix <> '') then
               name := name + Configuration.Prefix + DirectorySeparator;

            if(Configuration.UseOrganization and (appInfo.OrgShort <> '')) then
               name := name + appInfo.OrgShort + DirectorySeparator + appInfo.NameShort
            else
               name := name + appInfo.NameShort;
         end else
            name := Configuration.Path;

         {determine configuration createdPath}
         createdPath := appPath.Get(appPATH_CONFIG) + name;
      end else
         createdPath := Configuration.Preset;

      Configuration.Path := IncludeTrailingPathDelimiter(createdPath);

      {create the configuration directory}
      if(not FileUtils.DirectoryExists(createdPath)) then begin
         if(ForceDirectories(createdPath)) then
            Configuration.Created := true
      end else
         Configuration.Created := true;

      if(not Configuration.Created) then begin
         Configuration.Path := '';

         console.i('Failed to create configuration directory: ' + Configuration.Path);
      end else begin
         console.i('Created configuration directory: ' + Configuration.Path);
      end;
   end;

   Result := Configuration.Created;
end;

{$IFDEF DARWIN}
function proc_pidpath(pid: longint; buffer: pbyte; bufferSize: longword): longint; cdecl; external 'libproc.dylib' name 'proc_pidpath';
{$ENDIF}

function appTPath.GetExecutablePath(): StdString;
{$IFDEF DARWIN}
var
   path: array[0..4095] of char;
{$ENDIF}

begin
   {$IFDEF UNIX}
     {$IFDEF DARWIN}
     proc_pidpath(FpGetpid(), @path[0], length(path));
     Result := ExtractFilePath(pchar(path));
     {$ELSE}
     Result := ExtractFilePath(UTF8String(fpReadLink('/proc/self/exe')));
     {$ENDIF}
   {$ELSE}
      {$IFDEF WINDOWS}
      Result := ExtractFilePath(ParamStr(0));
      {$ELSE}
      Result := '';
      {$ENDIF}
   {$ENDIF}
end;

function appTPath.GetSystemPaths(): appTSystemPaths;
{$IFDEF WINDOWS}
var
   logicalDrives: windows.DWORD;
   i,
   driveCount,
   offset: loopint;
   lpVolumeName: array[0..1023] of char;
   lpFileSystemFlags,
   lpMaximumComponentLength: windows.DWORD;
{$ENDIF}

begin
   Result := nil;

   {$IFDEF WINDOWS}
   lpFileSystemFlags := 0;
   lpMaximumComponentLength := 0;

   logicalDrives := windows.GetLogicalDrives();

   driveCount := 0;
   for i := 0 to 31 do begin
      if(GetBit(logicalDrives, i)) then
         inc(driveCount);
   end;


   if(driveCount > 0) then begin
      SetLength(Result, driveCount);
      lpVolumeName[0] := #0;

      offset := 0;

      for i := 0 to 31 do begin
         if(GetBit(logicalDrives, i)) then begin
            Result[offset].Path := chr(ord('A') + i) + ':\';

            windows.GetVolumeInformation(PChar(Result[offset].Path),
               lpVolumeName, 1024, nil, lpMaximumComponentLength, lpFileSystemFlags, nil, 0);

            if(pChar(lpVolumeName) = '') then
               Result[offset].Name := '(' + chr(ord('A') + i) + ':)'
            else
               Result[offset].Name := PChar(lpVolumeName) + ' (' + chr(ord('A') + i) + ':)';

            inc(offset);
         end;
      end;
   end;
   {$ENDIF}
end;

procedure Initialize();
begin
   if(not appPath.Configuration.SkipInit) then
      appPath.CreateConfiguration();
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   appPath.Configuration.UseOrganization := true;
   app.InitializationProcs.Add(initRoutines, 'configuration', @initialize);

END.
