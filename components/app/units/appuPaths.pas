{
   appuPaths, handling of common file paths
   Copyright (C) 2011. Dejan Boras

   Started On:    30.04.2011.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuPaths;

INTERFACE

   USES
      {$IFDEF UNIX}BaseUnix,{$ENDIF}
      {$IFDEF WINDOWS}uStd, windows,{$ENDIF}
      sysutils, uFileUtils, StringUtils,
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
      Path: string;
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
         Preset: string;
      end;

      {return path for a specified constant, or nothing if not found}
      function Get(c: appTPathType): string;
      {creates the configuration directory}
      function HomeConfigurationDir(const dir: string): string;
      {creates the configuration directory}
      function CreateConfiguration(): boolean;
      {get the executable path}
      function GetExecutablePath(): string;

      {get a list of system paths}
      function GetSystemPaths(): appTSystemPaths;
   end;

VAR
   appPath: appTPath;

IMPLEMENTATION

function appTPath.Get(c: appTPathType): string;
var
   path: string = '';  
   
begin
   {check for preset path}
   if(c = appPATH_CONFIG) and (Configuration.Preset <> '') then
      exit(Configuration.Preset);

   {$IFDEF WINDOWS}
   if(c = appPATH_CONFIG) then
      path := GetEnvironmentVariable('APPDATA')
   else if(c = appPATH_HOME) then
      path := GetEnvironmentVariable('USERPROFILE')
   else if(c = appPATH_CONFIG_SHARED) then
      path := GetEnvironmentVariable('ALLUSERSPROFILE')
   else if(c = appPATH_DOCUMENTS) then
      path := IncludeTrailingPathDelimiterNonEmpty(GetEnvironmentVariable('USERPROFILE')) + 'Documents';
   {$ENDIF}

   {$IFDEF UNIX} {also includes darwin}
   if(c = appPATH_CONFIG) or (c = appPATH_HOME) or (c = appPATH_CONFIG_SHARED) then
      path := GetEnvironmentVariable('HOME')
   else if(c = appPATH_DOCUMENTS) then
      path := IncludeTrailingPathDelimiterNonEmpty(GetEnvironmentVariable('HOME')) + 'Documents';
   {$ENDIF}

   if(c = appPATH_TEMP) then
      path := GetEnvironmentVariable('TEMP');

   {add a directory separator to the end if the path is not empty}
   path := IncludeTrailingPathDelimiterNonEmpty(path);

   {return path}
   result := path;
end;

function appTPath.HomeConfigurationDir(const dir: string): string;
var
   createdPath: string;

begin
   createdPath := appPath.Get(appPATH_CONFIG) + dir + DirectorySeparator;

   CreateDir(createdPath);

   result := createdPath;
end;

{create the configuration directory}
function appTPath.CreateConfiguration(): boolean;
var
   createdPath,
   name: string;

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

         if(IsConsole) then
            writeln('Failed to create configuration directory: ', Configuration.Path);
      end else begin
         if(IsConsole) then
            writeln('Created configuration directory: ', Configuration.Path);
      end;
   end;

   result := Configuration.Created;
end;

{$IFDEF DARWIN}
function proc_pidpath(pid: longint; buffer: pbyte; bufferSize: longword): longint; cdecl; external 'libproc.dylib' name 'proc_pidpath';
{$ENDIF}

function appTPath.GetExecutablePath(): string;
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
     Result := ExtractFilePath(fpReadLink('/proc/self/exe'));
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
   app.InitializationProcs.iAdd(initRoutines, 'configuration', @initialize);

END.
