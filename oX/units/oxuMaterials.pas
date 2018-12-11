{
   oxuMaterials, oX materials
   Copyright (C) 2017. Dejan Boras

   Started On:    16.10.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuMaterials;

INTERFACE

   USES
      {oX}
      oxuResourcePool;

TYPE
   oxTMaterialPool = class(oxTResourcePool)
   end;

VAR
   oxMaterialPool: oxTMaterialPool;

IMPLEMENTATION

END.
