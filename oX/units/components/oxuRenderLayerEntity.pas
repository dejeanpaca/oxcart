{
   oxuLightEntity, common light entities
   Copyright (c) 2019. Dejan Boras

   Started On:    14.11.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuRenderLayerEntity;

INTERFACE

   USES
      uStd,
      {ox}
      oxuEntity, oxuRenderLayerComponent;

TYPE
   { oxTRenderLayerEntity }

   oxTRenderLayerEntity = record
      class function Default(): oxTEntity; static;
   end;

VAR
   oxRenderLayerEntity: oxTRenderLayerEntity;

IMPLEMENTATION

function getEntity(out component: oxTRenderLayerComponent): oxTEntity;
begin
   component := oxTRenderLayerComponent.Create();

   Result := oxEntity.New('RenderLayer', component);
end;

{ oxTRenderLayerEntity }

class function oxTRenderLayerEntity.Default(): oxTEntity;
var
   component: oxTRenderLayerComponent;

begin
   Result := getEntity(component);
end;

END.
