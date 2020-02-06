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
      uStd, StringUtils;

TYPE
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

      function GetPath(): StdString;
      function GetIdentifier(): StdString;
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
   else
      Result := '@' + Path;
end;

END.
