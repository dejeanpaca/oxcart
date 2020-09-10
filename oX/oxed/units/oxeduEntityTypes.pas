{
   oxeduEntityTypes, per entity data
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduEntityTypes;

INTERFACE

   USES
      oxuEntity, oxuSerialization,
      oxeduThingies;

TYPE
   oxedTEntityData = class
      ComponentRenderers: oxedTThingieComponentPairs;
   end;

IMPLEMENTATION

END.
