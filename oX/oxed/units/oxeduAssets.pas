{
   oxeduAssets, oxed asset management
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAssets;

INTERFACE

   USES
      uStd;

TYPE
   oxedTAssets = record
      {ignore these file types when building (don't copy over)}
      IgnoreFileTypes: TSimpleStringList;
   end;

IMPLEMENTATION

END.
