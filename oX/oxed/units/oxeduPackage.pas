{
   oxeduPackage, oxed packages
   Copyright (C) 2020. Dejan Boras

   Started On:    13.01.2020.

   - If only a path is set for a package, without an Id, this is just an included path, not an actual package
   - Package identifier starting with @ means it's a path, not a package name
}

{$INCLUDE oxdefines.inc}
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
      Path,
      {evaluated path}
      EvaluatedPath: StdString;

      Units,
      IncludeFiles: oxedTPackageUnitList;

      function GetPath(): StdString;
      function GetIdentifier(): StdString;
      function GetDisplayName(): StdString;

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

procedure oxedTPackage.DisposeList();
begin
   Units.Dispose();
   IncludeFiles.Dispose();
end;

class procedure oxedTPackage.Init(out p: oxedTPackage);
begin
   ZeroOut(p, SizeOf(p));

   oxedTPackageUnitList.Initialize(p.Units);
   oxedTPackageUnitList.Initialize(p.IncludeFiles);
end;

END.
