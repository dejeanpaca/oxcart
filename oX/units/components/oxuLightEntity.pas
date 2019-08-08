{
   oxuLightEntity, common light entities
   Copyright (c) 2017. Dejan Boras

   Started On:    18.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuLightEntity;

INTERFACE

   USES
      uStd,
      {ox}
      oxuEntity, oxuLightComponent;

TYPE
   { oxTLightEntity }

   oxTLightEntity = record
      class function Default(): oxTEntity; static;
   end;

VAR
   oxLightEntity: oxTLightEntity;

IMPLEMENTATION

function getEntity(out component: oxTLightComponent): oxTEntity;
begin
   Result := oxEntity.New('Light', oxTLightComponent.Create());
end;

{ oxTLightEntity }

class function oxTLightEntity.Default(): oxTEntity;
var
   component: oxTLightComponent;

begin
   result := getEntity(component);
end;

END.
