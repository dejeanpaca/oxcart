{
   oxuLightEntity, common light entities
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderLayerEntity;

INTERFACE

   USES
      uStd,
      {ox}
      oxuEntity, oxuRenderLayerComponent;

TYPE
   { oxTRenderLayerEntity }

   oxTRenderLayerEntity = record
      class function Default(const renderLayer: StdString; const name: StdString = ''): oxTEntity; static;
   end;

VAR
   oxRenderLayerEntity: oxTRenderLayerEntity;

IMPLEMENTATION

function getEntity(const renderLayer: StdString; out component: oxTRenderLayerComponent): oxTEntity;
begin
   component := oxTRenderLayerComponent.Create();
   component.Name := renderLayer;

   Result := oxEntity.New('RenderLayer', component);
end;

{ oxTRenderLayerEntity }

class function oxTRenderLayerEntity.Default(const renderLayer: StdString; const name: StdString): oxTEntity;
var
   component: oxTRenderLayerComponent;

begin
   Result := getEntity(renderLayer, component);
   Result.Name := name;
end;

END.
