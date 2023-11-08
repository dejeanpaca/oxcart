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
      {is this package path optional (true if path and any parent is optional too)}
      function IsOptional(): boolean;

      {loads path properties from .package file if any is present}
      procedure LoadPathProperties(const basePath: StdString);
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

      {find closes package path for given path}
      function FindClosest(const path: StdString; excludeSelf: boolean = false): oxedPPackagePath;
      {find parent path}
      procedure AssociateParent(var p: oxedTPackagePath);

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

function oxedTPackagePath.IsOptional(): boolean;
var
   current: oxedPPackagePath;

begin
   Result := Optional;

   {if current path is not optional, check if parent paths are}
   if(not Result) then begin
      current := Parent;

      if(current <> Nil) then repeat
         if(current^.Optional) then
            exit(True);

         current := current^.Parent;
      until current = nil;
   end;
end;

procedure oxedTPackagePath.LoadPathProperties(const basePath: StdString);
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

   fn := basePath + Path + OX_PACKAGE_PROPS_FILE_NAME;
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
var
   pp: StdString;

begin
   pp := IncludeTrailingPathDelimiterNonEmpty(p);
   Result := FindPackagePath(pp);

   if(Result = nil) then
      Result := NewPath(pp);
end;

function oxedTPackagePathsHelper.NewPath(const p: StdString): oxedPPackagePath;
var
   path: oxedTPackagePath;

begin
   oxedTPackagePath.Initialize(path);
   path.Path := IncludeTrailingPathDelimiterNonEmpty(p);

   Add(path);
   Result := GetLast();
   AssociateParent(Result^);
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

function oxedTPackagePathsHelper.FindClosest(const path: StdString; excludeSelf: boolean): oxedPPackagePath;
var
   i: loopint;
   potentialParent: oxedPPackagePath;
   p: StdString;

begin
   Result := nil;
   potentialParent := nil;

   p := IncludeTrailingPathDelimiterNonEmpty(path);

   {find parent with longest path (means closest to our package path)}

   for i := 0 to n - 1 do begin
      if(excludeSelf) and (p = List[i].Path) then
         continue;

      {do we have the parent path in our path}
      if(pos(List[i].Path, p) = 1) then begin
         if(potentialParent <> nil) then begin
            {whichever parent is closer to our path}
            if(Length(potentialParent^.Path) < Length(List[i].Path)) then
               potentialParent := @List[i];
         end else
            potentialParent := @List[i];
      end;
   end;

   Result := potentialParent;
end;

procedure oxedTPackagePathsHelper.AssociateParent(var p: oxedTPackagePath);
begin
   p.Parent := FindClosest(p.Path, true);
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
