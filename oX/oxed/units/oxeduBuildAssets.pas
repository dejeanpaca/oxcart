{
   oxeduBuildAssets, oxed asset build system
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuildAssets;

INTERFACE

   USES
      oxeduAssets;

TYPE

   { oxedTBuildAssets }

   oxedTBuildAssets = record
      procedure Deploy();
   end;

VAR
   oxedBuildAssets: oxedTBuildAssets;

IMPLEMENTATION

{ oxedTBuildAssets }

procedure oxedTBuildAssets.Deploy();
begin

end;

END.
