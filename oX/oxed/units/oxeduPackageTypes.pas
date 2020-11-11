{
   oxeduPackageTypes, package types
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduPackageTypes;

INTERFACE

   USES
      uStd, StringUtils, uFileUtils, uSimpleParser,
      oxuFeatures;

CONST
   OX_PACKAGE_PROPS_FILE_NAME = '.oxpackage';

TYPE
   oxedTPackageUnit = record
      Name,
      Path: StdString;
   end;

   oxedPPackagePath = ^oxedTPackagePath;

   { oxedTPackagePath }

   oxedTPackagePath = record
      Units,
      IncludeFiles: TSimpleStringList;
      Path: StdString;

      Platforms: oxTFeaturePlatforms;
      {this part of the package is optional (must be included explicitly)}
      Optional,
      {have we loaded package properties already}
      LoadedProperties: boolean;
      {parent package path}
      Parent: oxedPPackagePath;

      class procedure Initialize(out p: oxedTPackagePath); static;

      {check if this package path is supported on provided platform}
      function IsSupported(const platform: StdString; isLibrary: boolean = false): boolean;

      {loads path properties from .package file if any is present}
      procedure LoadPathProperties();
   end;

   { oxedTPackagePathHelper }

   oxedTPackagePathHelper = record helper for oxedTPackagePath
      {does this package path contain a unit/include with the given name}
      function Contains(const name: StdString): Boolean;
   end;

   { oxedTPackagePaths }

   oxedTPackagePaths = specialize TSimpleList<oxedTPackagePath>;

   { oxedTPackagePathsHelper }

   oxedTPackagePathsHelper = record helper for oxedTPackagePaths
      {add new path/unit to package units list}
      procedure AddUnit(const unitFile: oxedTPackageUnit);
      {add new path/unit to package includes list}
      procedure AddInclude(const unitFile: oxedTPackageUnit);

      {add a new path}
      function Get(const p: StdString): oxedPPackagePath;
      {add a new path}
      function NewPath(const p: StdString): oxedPPackagePath;
      {find an existing path (if any)}
      function FindPackagePath(const p: StdString): oxedPPackagePath;
      {find unit path (if any)}
      function FindPackageUnit(const p: StdString): oxedPPackagePath;

      {dispose of all the paths}
      procedure Destroy();
   end;

IMPLEMENTATION

{ oxedTPackagePath }

class procedure oxedTPackagePath.Initialize(out p: oxedTPackagePath);
begin
   ZeroOut(p, SizeOf(p));

   TSimpleStringList.InitializeValues(p.Units);
   TSimpleStringList.InitializeValues(p.IncludeFiles);
end;

function oxedTPackagePath.IsSupported(const platform: StdString; isLibrary: boolean): boolean;
begin
   Result := Platforms.IsSupported(platform, isLibrary);
end;

procedure oxedTPackagePath.LoadPathProperties();
var
   fn: StdString;
   kv: TStringPairs;
   key,
   value: StdString;

   i: loopint;
   values: TStringArray;

begin
   if(LoadedProperties) then
      exit;

   LoadedProperties := true;

   fn := IncludeTrailingPathDelimiterNonEmpty(Path) + OX_PACKAGE_PROPS_FILE_NAME;
   TStringPairs.Initialize(kv);

   if(FileUtils.Exists(fn) > 0) then begin
      SimpleParser.LoadKeyValues(fn, kv);

      for i := 0 to kv.n - 1 do begin
         key := kv.List[i][0];
         value := kv.List[i][1];

         if(key = 'include') then begin
            values := strExplode(value, ',');

            if(Length(values) > 0) then
               Platforms.SetIncluded(values);
         end else if (key = 'exclude') then begin
            values := strExplode(value, ',');

            if(Length(values) > 0) then
               Platforms.SetExcluded(values);
         end else if (key = 'optional') then begin
            Optional := true;
         end;
      end;
   end;
end;

{ oxedTPackagePathHelper }

function oxedTPackagePathHelper.Contains(const name: StdString): Boolean;
var
   i: loopint;
   lName: StdString;

begin
   if(Units.n > 0) then begin
      lName := LowerCase(name);

      for i := 0 to Units.n - 1 do begin
         if(lName = LowerCase(Units.List[i])) then
            exit(true);
      end;
   end;

   Result := false;
end;

{ oxedTPackagePathsHelper }

procedure oxedTPackagePathsHelper.AddUnit(const unitFile: oxedTPackageUnit);
var
   unitPath: StdString;
   p: oxedPPackagePath;

begin
   unitPath := ExtractFilePath(unitFile.Path);

   p := Get(unitPath);
   p^.Units.Add(unitFile.Name);
end;

procedure oxedTPackagePathsHelper.AddInclude(const unitFile: oxedTPackageUnit);
var
   includePath: StdString;
   p: oxedPPackagePath;

begin
   includePath := ExtractFilePath(unitFile.Path);

   p := Get(includePath);
   p^.IncludeFiles.Add(unitFile.Name);
end;

function oxedTPackagePathsHelper.Get(const p: StdString): oxedPPackagePath;
begin
   Result := FindPackagePath(p);

   if(Result = nil) then
      Result := NewPath(p);
end;

function oxedTPackagePathsHelper.NewPath(const p: StdString): oxedPPackagePath;
var
   units: oxedTPackagePath;

begin
   oxedTPackagePath.Initialize(units);
   units.Path := p;

   Add(units);
   Result := GetLast();

   Result^.LoadPathProperties();
end;

function oxedTPackagePathsHelper.FindPackagePath(const p: StdString): oxedPPackagePath;
var
   i: loopint;

begin
   if(n > 0) then begin
      for i := 0 to n - 1 do begin
         if(List[i].Path = p) then
            exit(@List[i]);
      end;
   end;

   Result := nil;
end;

function oxedTPackagePathsHelper.FindPackageUnit(const p: StdString): oxedPPackagePath;
var
   i,
   j: loopint;
   path: oxedPPackagePath;

begin
   if(n > 0) then begin
      for i := 0 to n - 1 do begin
         path := @List[i];

         for j := 0 to path^.Units.n - 1 do begin
            if(path^.Units.List[j] = p) then
               exit(path);
         end;
      end;
   end;

   Result := nil;
end;

procedure oxedTPackagePathsHelper.Destroy();
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i].Units.Dispose();
   end;

   Dispose();
end;

END.
