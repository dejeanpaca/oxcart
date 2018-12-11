{
   oxuBuild, various build utilities
   Copyright (C) 2017. Dejan Boras

   Started On:    04.09.2017.
}

{$INCLUDE oxdefines.inc}{$I-}
UNIT oxuBuild;

INTERFACE


TYPE

   { oxTBuild }

   oxTBuild = record
      function GetLibrarySource(): string;
   end;

VAR
   oxBuild: oxTBuild;

IMPLEMENTATION

{ oxTBuild }

function oxTBuild.GetLibrarySource: string;
begin
   Result := 'libraries' + DirectorySeparator;
end;

END.

