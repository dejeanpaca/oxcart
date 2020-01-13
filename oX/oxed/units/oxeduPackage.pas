{
   oxeduPackage, oxed packages
   Copyright (C) 2020. Dejan Boras

   Started On:    13.01.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPackage;

INTERFACE

   USES
      uStd, StringUtils;

TYPE
   { oxedTPackage }

   oxedTPackage = record
      {name}
      Name,
      {path to package}
      Path,
      {evaluated path}
      EvaluatedPath: StdString;

      function GetPath(): string;
   end;

   oxedTPackagesList = specialize TSimpleList<oxedTPackage>;

   oxedTPackages = record
      Path: string;
   end;

VAR
   oxedPackages: oxedTPackages;

IMPLEMENTATION

{ oxedTPackage }

function oxedTPackage.GetPath(): string;
begin
   if(Path <> '') then
      Result := Path
   else
      Result :=  IncludeTrailingPathDelimiterNonEmpty(Path) + Name;
end;

END.
