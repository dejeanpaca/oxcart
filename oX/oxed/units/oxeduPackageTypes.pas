{
   oxeduPackageTypes, package types
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPackageTypes;

INTERFACE

   USES
      uStd, StringUtils;

TYPE
   oxedTPackageUnit = record
      Name,
      Path: StdString;
   end;

   oxedPPackagePath = ^oxedTPackagePath;

   { oxedTPackagePath }

   oxedTPackagePath = record
      Units: TSimpleStringList;
      Path: StdString;

      class procedure Initialize(out p: oxedTPackagePath); static;
   end;

   { oxedTPackagePathHelper }

   oxedTPackagePathHelper = record helper for oxedTPackagePath
      function Contains(const name: StdString): Boolean;
   end;

   { oxedTPackagePaths }

   oxedTPackagePaths = specialize TSimpleList<oxedTPackagePath>;

   { oxedTPackagePathsHelper }

   oxedTPackagePathsHelper = record helper for oxedTPackagePaths
      {add new path/unit from package unit}
      procedure AddUnit(const unitFile: oxedTPackageUnit);

      {add a new path}
      function Get(const p: StdString): oxedPPackagePath;
      {add a new path}
      function NewPath(const p: StdString): oxedPPackagePath;
      {find an existing path (if any)}
      function FindPackagePath(const p: StdString): oxedPPackagePath;

      procedure Destroy();
   end;

IMPLEMENTATION

{ oxedTPackagePath }

class procedure oxedTPackagePath.Initialize(out p: oxedTPackagePath);
begin
   ZeroOut(p, SizeOf(p));
   p.Units.InitializeValues(p.Units);
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
