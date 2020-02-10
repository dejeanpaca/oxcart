{
   oxeduProject, project for oxed
   Copyright (C) 2016. Dejan Boras

   Started On:    13.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProject;

INTERFACE

   USES
      sysutils, uStd, uLog, uFileUtils, StringUtils, uBuild,
      {oxed}
      uOXED, oxeduSettings, oxeduPackage, oxeduPackageTypes;

TYPE
   oxedTProjectSymbols = TSimpleStringList;

   oxedPProjectBuildMode = ^oxedTProjectBuildMode;
   oxedTProjectBuildMode = record
      Name: StdString;
      Symbols: oxedTProjectSymbols;
   end;

   oxedTProjectBuildModes = specialize TSimpleList<oxedTProjectBuildMode>;

   { oxedTProject }

   oxedTProject = class
      {is the project currently running}
      Running,
      {is the project currently paused}
      Paused: boolean;

      {project name}
      Name,
      ShortName,
      {project identifier}
      Identifier,
      {path to the project directory}
      Path,
      {path to the project configuration directory}
      ConfigPath,
      {path to the current scene directory}
      ScenePath,
      {path to the temporary directory}
      TempPath,
      {last used scene}
      LastScene,
      {project organization}
      Organization,
      OrganizationShort,
      {line ending type}
      LineEndings: StdString;

      {has the project been modified}
      Modified: boolean;

      MainPackage: oxedTPackage;

      Packages: oxedTPackagesList;

      Symbols: oxedTProjectSymbols;
      BuildModes: oxedTProjectBuildModes;

      {command line parameters to be used when a project is run}
      RunParameters: TSimpleStringList;
      {project features}
      Features: TSimpleStringList;

      {main unit uses, if specified will be the only unit included by default in project}
      MainUnit: StdString;

      {called when the project is modified}
      OnProjectModified: TProcedures; static;

      Session: record
         {include third party units in our project}
         IncludeThirdPartyUnits,
         {have we built third party units and dependencies yet}
         ThirdPartyBuilt,
         {have we done an initial build on startup}
         InitialBuildDone,
         {have we done an initial scan}
         InitialScanDone,
         {debug ox resources}
         DebugResources,
         {should the in-engine console be enabled for the project}
         EnableConsole: boolean;
      end;

      constructor Create();

      procedure SetPath(const newPath: StdString);
      procedure SetIdentifier(const newIdentifier: StdString);
      class function NormalizedIdentifier(const unnormalized: StdString): StdString; static;

      function HasPath(): boolean;
      function GetLibraryPath(includePath: boolean = true): StdString;

      procedure RecreateTempDirectory();

      {set the last scene path}
      procedure SetLastScene(const newPath: StdString);

      {mark the project as modified}
      procedure MarkModified(newModified: boolean = true);

      {is the project valid}
      function Valid(): boolean;

      function GetConfigFilePath(const fn: StdString): StdString;
      function GetTempFilePath(const fn: StdString): StdString;

      procedure AddPackage(const packageId: string);
      procedure AddPackagePath(const packagePath: string);

      function GetPackagePath(const package: oxedTPackage): StdString;
   end;

VAR
   oxedProject: oxedTProject;

function oxedProjectValid(): boolean;

IMPLEMENTATION

function oxedProjectValid(): boolean;
begin
   Result := (oxedProject <> nil) and (oxedProject.HasPath());
end;

{ oxedTProject }

constructor oxedTProject.Create();
begin
   Name := 'Project';
   SetIdentifier(Name);
   Session.IncludeThirdPartyUnits := true;
   Session.EnableConsole := true;
   LineEndings := oxedSettings.LineEndings;

   oxedTPackage.Init(MainPackage);

   RunParameters.Initialize(RunParameters);
   BuildModes.Initialize(BuildModes);
   Symbols.Initialize(Symbols);
   Packages.Initialize(Packages);
end;

procedure oxedTProject.SetPath(const newPath: StdString);
begin
   Path := IncludeTrailingPathDelimiter(newPath);
   MainPackage.Path := Path;
   log.v('Project path set to: ' + Path);
   ConfigPath := IncludeTrailingPathDelimiter(Path + oxPROJECT_DIRECTORY);
   TempPath := IncludeTrailingPathDelimiter(Path + oxPROJECT_TEMP_DIRECTORY);
end;

procedure oxedTProject.SetIdentifier(const newIdentifier: StdString);
begin
   Identifier := NormalizedIdentifier(newIdentifier);
   MarkModified();
end;

class function oxedTProject.NormalizedIdentifier(const unnormalized: StdString): StdString;
begin
   Result := unnormalized;
   EliminateWhiteSpace(Result);
end;

function oxedTProject.HasPath(): boolean;
begin
   Result := Path <> '';
end;

function oxedTProject.GetLibraryPath(includePath: boolean): StdString;
begin
   if(includePath) then
      Result := TempPath
   else
      Result := '';

   Result := Result + build.GetExecutableName(oxPROJECT_LIBRARY_NAME, true);
end;

procedure oxedTProject.RecreateTempDirectory();
begin
  if(not FileUtils.DirectoryExists(oxedProject.TempPath)) then
     CreateDir(oxedProject.TempPath);
end;

procedure oxedTProject.SetLastScene(const newPath: StdString);
begin
   if(LastScene <> newPath) then
      MarkModified();

   LastScene := newPath;
end;

procedure oxedTProject.MarkModified(newModified: boolean);
begin
   Modified := newModified;

   oxedTProject.OnProjectModified.Call();
end;

function oxedTProject.Valid(): boolean;
begin
   Result := (Name <> '') and (Identifier <> '');
end;

function oxedTProject.GetConfigFilePath(const fn: StdString): StdString;
begin
   Result := ConfigPath + fn;
end;

function oxedTProject.GetTempFilePath(const fn: StdString): StdString;
begin
   Result := oxedProject.TempPath + fn;
end;

procedure oxedTProject.AddPackage(const packageId: string);
var
   p: oxedTPackage;

begin
   oxedTPackage.Init(p);
   p.Id := packageId;

   Packages.Add(p);
end;

procedure oxedTProject.AddPackagePath(const packagePath: string);
var
   p: oxedTPackage;

begin
   oxedTPackage.Init(p);
   p.Path := packagePath;

   Packages.Add(p);
end;

function oxedTProject.GetPackagePath(const package: oxedTPackage): StdString;
begin
   if(package.Id = '') then
      exit(ExpandFileName(package.Path));

   Result := package.Path;
end;

INITIALIZATION
   TProcedures.InitializeValues(oxedTProject.OnProjectModified);

END.
