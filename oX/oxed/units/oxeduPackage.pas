{
   oxeduPackage, oxed packages
   Copyright (C) 2020. Dejan Boras

   - If only a path is set for a package, without an Id, this is just an included path, not an actual package
   - Package identifier starting with @ means it's a path, not a package name
}

{$INCLUDE oxheader.inc}
UNIT oxeduPackage;

INTERFACE

   USES
      uStd, StringUtils, oxeduPackageTypes;

TYPE
   oxedPPackage = ^oxedTPackage;

   { oxedTPackage }

   oxedTPackage = record
      {identifier}
      Id,
      {display name}
      Name,
      {path to package}
      Path: StdString;

      Units,
      IncludeFiles: oxedTPackagePaths;

      function GetPath(): StdString;
      function GetIdentifier(): StdString;
      function GetDisplayName(): StdString;

      {do we have any source in package}
      function IsEmpty(): boolean;

      procedure DisposeList();

      class procedure Init(out p: oxedTPackage); static;
   end;

   oxedTPackagesList = specialize TSimpleList<oxedTPackage>;

   oxedTPackages = record
      Path: StdString;
   end;

VAR
   oxedPackages: oxedTPackages;

IMPLEMENTATION

{ oxedTPackage }

function oxedTPackage.GetPath(): StdString;
begin
   if(Path <> '') then
      Result := Path
   else
      Result :=  IncludeTrailingPathDelimiterNonEmpty(Path) + Name;
end;

function oxedTPackage.GetIdentifier(): StdString;
begin
   if(Id <> '') then
      Result := Id
   else if(Path <> '') then
      Result := '@' + Path
   else
      Result := '';
end;

function oxedTPackage.GetDisplayName(): StdString;
begin
   if(Id <> '') then begin
      if(Name <> '') then
         Result := Name + '(' + Id + ')'
      else
         Result := Id;
   end else
      Result := Path;
end;

function oxedTPackage.IsEmpty(): boolean;
begin
   Result := (Units.n = 0) and (IncludeFiles.n = 0);
end;

procedure oxedTPackage.DisposeList();
begin
   Units.Destroy();
   IncludeFiles.Destroy();
end;

class procedure oxedTPackage.Init(out p: oxedTPackage);
begin
   ZeroOut(p, SizeOf(p));

   oxedTPackagePaths.InitializeValues(p.Units);
   oxedTPackagePaths.InitializeValues(p.IncludeFiles);
end;

END.
