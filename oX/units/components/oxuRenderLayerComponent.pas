{
   oxuRenderLayerComponent, render layer component
   Copyright (c) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRenderLayerComponent;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTransform, oxuEntity, oxuComponent, oxuComponentDescriptors, oxuSerialization;

TYPE

   { oxTRenderLayerComponent }

   oxTRenderLayerComponent = class(oxTComponent)
      public
      {name of the render layer}
      Name: StdString;

      constructor Create(); override;
      destructor Destroy(); override;

      {get the descriptor for this component}
      function GetDescriptor(): oxPComponentDescriptor; override;
   end;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;
   descriptor: oxTComponentDescriptor;

function instance(): TObject;
begin
   Result := oxTRenderLayerComponent.Create();
end;

{ oxTRenderLayerComponent }

constructor oxTRenderLayerComponent.Create();
begin
   inherited;
end;

destructor oxTRenderLayerComponent.Destroy();
begin
   inherited;
end;

function oxTRenderLayerComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

INITIALIZATION
   serialization := oxTSerialization.Create(oxTRenderLayerComponent, @instance);

   descriptor.Create('render_layer', oxTRenderLayerComponent);
   descriptor.Name := 'RenderLayer';

FINALIZATION
   FreeObject(serialization);

END.
