{
   oxeduEntityTypes, per entity data
   Copyright (C) 2017. Dejan Boras

   Started On:    20.05.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduEntityTypes;

INTERFACE

   USES
      oxuEntity, oxuSerialization,
      oxeduEditRenderers;

TYPE
   oxedTEntityData = class
      ComponentRenderers: oxedTEditRendererComponentPairs;
   end;

IMPLEMENTATION

END.
