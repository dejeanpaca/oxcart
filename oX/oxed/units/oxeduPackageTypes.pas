{
   oxeduPackageTypes, package types
   Copyright (C) 2020. Dejan Boras

   Started On:    10.02.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPackageTypes;

INTERFACE

   USES
      uStd;

TYPE
   oxedPPackageUnit = ^oxedTPackageUnit;
   oxedTPackageUnit = record
      {name of the unit/include file}
      Name,
      {path to the file}
      Path: StdString;
   end;

   oxedTPackageUnitList = specialize TSimpleList<oxedTPackageUnit>;

   { oxedTPackageUnitListHelper }

   oxedTPackageUnitListHelper = record helper for oxedTPackageUnitList
      function Find(const name: StdString): oxedPPackageUnit;
   end;

IMPLEMENTATION

{ oxedTPackageUnitListHelper }

function oxedTPackageUnitListHelper.Find(const name: StdString): oxedPPackageUnit;
var
   i: loopint;
   lName: StdString;

begin
   if(n > 0) then begin
      lName := LowerCase(name);

      for i := 0 to n - 1 do begin
         if(lName = LowerCase(List[i].Name)) then
            exit(@List[i]);
      end;
   end;

   Result := nil;
end;

END.
