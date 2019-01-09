{
   oxuLightComponent, light component
   Copyright (c) 2018. Dejan Boras

   Started On:    26.11.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuLightComponent;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxuTransform, oxuProjection, oxuLight, oxuEntity, oxuComponent, oxuComponentDescriptors, oxuSerialization;

TYPE

   { oxTLightComponent }

   oxTLightComponent = class(oxTComponent)
      public
      UseSceneProjection: boolean;

      Projection: oxTProjection;
      Light: oxTLight;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure GetBoundingBox(out bbox: TBoundingBox); override;

      procedure OnAdd(); override;

      {get the descriptor for this component}
      function GetDescriptor(): oxPComponentDescriptor; override;
   end;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;
   descriptor: oxTComponentDescriptor;


function instance(): TObject;
begin
   Result := oxTLightComponent.Create();
end;

{ oxTLightComponent }

constructor oxTLightComponent.Create();
begin
   inherited Create;

   UseSceneProjection := true;
   Light := oxTLight.Create();
end;

destructor oxTLightComponent.Destroy();
begin
   inherited Destroy;

   FreeObject(Light);
end;

procedure oxTLightComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   bbox := vmBBoxUnit;
end;

procedure oxTLightComponent.OnAdd();
begin
   inherited OnAdd;

   oxTEntity(Parent).Renderable := false;
end;

function oxTLightComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

INITIALIZATION
   serialization := oxTSerialization.Create(oxTLightComponent, @instance);
   serialization.AddObjectProperty('Light', @oxTLightComponent(nil).Light);

   descriptor.Create('light');
   descriptor.Name := 'Light';

FINALIZATION
   FreeObject(serialization);

END.
