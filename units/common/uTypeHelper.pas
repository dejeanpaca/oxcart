{
   uTiming, timing operations, timers & timing utilities
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$MODESWITCH TYPEHELPERS}
UNIT uTypeHelper;

INTERFACE

   USES
      typinfo, uStd;

function GetSetValues(const aSet: PTypeInfo; const separator: string = ','):string;

IMPLEMENTATION

function GetSetValues(const aSet: PTypeInfo; const separator: string = ','):string;
var
   data,
   range_data: PTypeData;

   i: loopint;

begin
   Result := '';

   if(aSet^.Kind = tkSet) then begin
      data := GetTypeData(aSet);
      range_data := GetTypeData(data^.CompType);

      for i := range_data^.MinValue to range_data^.MaxValue do begin
         if(i < range_data^.MaxValue) then
            Result := Result + GetEnumName(data^.CompType, i) + separator
         else
            Result := Result + GetEnumName(data^.CompType, i);
      end;
  end;
end;
END.
