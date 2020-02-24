{
   appuRegional, handling of regional formats/settings
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuRegional;

INTERFACE

   USES sysutils;

CONST
   appNUMERICAL_CHARS = ['+', '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
   appFLOAT_CHARS = ['+', '-', 'E', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

TYPE

   { appTRegional }

   appTRegional = record
      class function IsFloatCharacter(c: char): boolean; static;
   end;

VAR
   appRegional: appTRegional;

IMPLEMENTATION

{ appTRegional }

class function appTRegional.IsFloatCharacter(c: char): boolean;
begin
   Result := (c = FormatSettings.DecimalSeparator) or (c in appFLOAT_CHARS);
end;

END.
