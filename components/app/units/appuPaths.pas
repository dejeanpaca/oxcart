{
   appuPaths, handling of common file paths
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuPaths;

INTERFACE

   USES
      uStd, uLog,
      {$IFDEF UNIX}BaseUnix,{$ENDIF}
      {$IFDEF WINDOWS}uBitSet, windows,{$ENDIF}
      {$IFDEF ANDROID}uAndroidApp,{$ENDIF}
      sysutils, uFileUtils, StringUtils, ConsoleUtils,
      uAppInfo, uApp,
      oxuRunRoutines;

TYPE
   appTPathType = (
      appPATH_CONFIG, {configuration path}
      appPATH_CONFIG_SHARED, {shared configuration for all users}
      appPATH_HOME, {user profile home}
      appPATH_TEMP, {temporary files directory}
      {NOTE: local is applicable to windows mostly due to the distinction of roaming and local profile}
      appPATH_LOCAL, {local configuration path (should house non-critical things, which aren't quite temporary (logs, caches))}
      appPATH_DOCUMENTS {documents directory}
   );

   appTSystemPath = record
      Name,
      Path: StdString;
   end;

   appTSystemPaths = array of appTSystemPath;

   { appTPathConfiguration }

   appTPathConfiguration = record
      {will the organization name be used for configuration directory}
      UseOrganization,
      {use a local configuration directory}
      UseLocal,
      {has the configuration directory been created}
      Created,
      {will not initialize the application}
      SkipInit: boolean;

      {configuration path}
      Path,
      {local configuration path}
      Local,
      {preset configuration path}
      Preset,
      {preset local configuration path}
      PresetLocal: StdString;

      {get local configuration path}
      function GetLocal(): StdString;
   end;

   { appTPath }

   appTPath = record
      Configuration: appTPathConfiguration;

      {return path for a specified constant, or nothing if not found}
      function Get(c: appTPathType): StdString;
      {creates the configuration directory}
      function HomeConfigurationDir(const dir: StdString; {%H-}local: boolean = false): StdString;
      {creates the configuration directory}
      function GetConfigurationPath(const info: appTInfo; local: boolean = false): StdString;
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

{ appTPathConfiguration }

function appTPathConfiguration.GetLocal(): StdString;
begin
   if(UseLocal) and (Local <> '') then
      Result := Local
   else
      Result := Path;
end;

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
   else if(c = appPATH_LOCAL) then begin
      path := GetUTF8EnvironmentVariable('LOCALAPPDATA');

      if(path = '') then
         path := GetUTF8EnvironmentVariable('USERPROFILE') + DirSep + 'Local Settings\Application Data';

      writeln('LOCAL!: ', path);
   end else if(c = appPATH_HOME) then
      path := GetUTF8EnvironmentVariable('USERPROFILE')
   else if(c = appPATH_CONFIG_SHARED) then
      path := GetUTF8EnvironmentVariable('ALLUSERSPROFILE')
   else if(c = appPATH_DOCUMENTS) then
      path := IncludeTrailingPathDelimiterNonEmpty(GetUTF8EnvironmentVariable('USERPROFILE')) + 'Documents';
   {$ENDIF}

   {$IF DEFINED(ANDROID)}
   if(c = appPATH_CONFIG) or (c = appPATH_HOME) or (c = appPATH_CONFIG_SHARED) or (c = appPATH_LOCAL) or
      (c = appPATH_DOCUMENTS) or (c = appPATH_TEMP) then
      path := androidGetInternalStorage();
   {$ELSEIF DEFINED(UNIX)} {also includes darwin}
   if(c = appPATH_CONFIG) or (c = appPATH_HOME) or (c = appPATH_CONFIG_SHARED) or (c = appPATH_LOCAL) then
      path := GetUTF8EnvironmentVariable('HOME')
   else if(c = appPATH_DOCUMENTS) then
      path := IncludeTrailingPathDelimiterNonEmpty(GetUTF8EnvironmentVariable('HOME')) + 'Documents';
   {$ENDIF}

   {$IFNDEF ANDROID}
   if(c = appPATH_TEMP) then
      path := GetUTF8EnvironmentVariable('TEMP');
   {$ENDIF}

   {add a directory separator to the end if the path is not empty}
   Result := IncludeTrailingPathDelimiterNonEmpty(path);
end;

function appTPath.HomeConfigurationDir(const dir: StdString; local: boolean): StdString;
{$IFNDEF ANDROID}
var
   basePath,
   createdPath: StdString;
{$ENDIF}

begin
   {$IFDEF ANDROID}
   exit(androidGetInternalStorage());
   {$ELSE}
      {$IF DEFINED(WINDOWS)}
      if(not local) then
         basePath := appPath.Get(appPATH_CONFIG)
      else
         basePath := appPath.Get(appPATH_LOCAL);
      {$ELSE}
      basePath := appPath.Get(appPATH_CONFIG) + 'local' + DirectorySeparator;
      {$ENDIF}

      createdPath := basePath + dir + DirectorySeparator;
      CreateDir(createdPath);

      Result := createdPath;
   {$ENDIF}
end;

function appTPath.GetConfigurationPath(const info: appTInfo; local: boolean): StdString;
var
   name: StdString;

begin
   name := '.';

   if(Configuration.UseOrganization and (appInfo.OrgShort <> '')) then
      name := name + info.OrgShort + DirectorySeparator + info.NameShort
   else
      name := name + info.NameShort;

   {determine configuration createdPath}
   {$IF DEFINED(WINDOWS)}
   if(not local) then
      Result := appPath.Get(appPATH_CONFIG) + name
   else
      Result := appPath.Get(appPATH_LOCAL) + name;
   {$ELSEIF DEFINED(ANDROID)}
   Result := androidGetInternalStorage();
   {$ELSE}
   if(not local) then
      Result := appPath.Get(appPATH_CONFIG) + name
   else
      Result := apppath.Get(appPATH_LOCAL) + 'local' + DirectorySeparator + name;
   {$ENDIF}
end;

function createConfigDirectory(const Preset: StdString; local: boolean; out Path: StdString): boolean;
var
   createdPath: StdString;

begin
   Result := true;

   if(Preset = '') then begin
      {determine name of the configuration directory from app info}
      createdPath := appPath.GetConfigurationPath(appInfo, local)
   end else
      createdPath := Preset;

   Path := IncludeTrailingPathDelimiter(createdPath);

   {create the local configuration directory}
   if(Path <> '') then begin
     if(not FileUtils.DirectoryExists(Path)) then begin
        if(not ForceDirectories(Path)) then begin
           console.e('Failed to create configuration directory: ' + Path);
           Result := false;
        end;
      end;
   end else
      Result := false;
end;

{create the configuration directory}
function appTPath.CreateConfiguration(): boolean;
begin
   if(not Configuration.Created) then begin
      if(Configuration.UseLocal) then
         createConfigDirectory(Configuration.PresetLocal, true, Configuration.Local);

      Configuration.Created := createConfigDirectory(Configuration.Preset, false, Configuration.Path);

      if(not Configuration.Created) then
         Configuration.Path := ''
      else
         console.i('Created configuration directory: ' + Configuration.Path);
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
     Result := ExtractFilePath(StdString(pchar(path)));
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
               Result[offset].Name := '(' + chr(ord('A') + i) + ':) ' + PChar(lpVolumeName);

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

INITIALIZATION
   appPath.Configuration.UseOrganization := true;
   appPath.Configuration.UseLocal := true;
   app.InitializationProcs.Add('configuration', @initialize);

END.
