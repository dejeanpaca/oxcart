{
   oxuCameraComponent, camera component
   Copyright (c) 2017. Dejan Boras

   Started On:    18.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuCameraComponent;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxuTransform, oxuProjectionType, oxuProjection,
      oxuCamera, oxuEntity, oxuComponent, oxuComponentDescriptors, oxuSerialization;

TYPE

   { oxTCameraComponent }

   oxTCameraComponent = class(oxTComponent)
      public
      Projection: oxTProjection;
      Camera: oxTCamera;

      UseSceneProjection: boolean;

      constructor Create(); override;

      procedure OnPositionChanged(); override;
      procedure OnRotationChanged(); override;

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
   Result := oxTCameraComponent.Create();
end;

{ oxTCameraComponent }

constructor oxTCameraComponent.Create();
begin
   inherited Create;

   Camera.Initialize();
   Projection.Initialize();
   UseSceneProjection := true;
end;

procedure oxTCameraComponent.OnPositionChanged();
begin
   Camera.vPos := oxTTransform(Parent).vPosition;
end;

procedure oxTCameraComponent.OnRotationChanged();
begin
   Camera.vView := oxTTransform(Parent).GetForward();
   Camera.vUp := oxTTransform(Parent).GetUp();
   Camera.vRight := oxTTransform(Parent).GetRight();
end;

procedure oxTCameraComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   bbox := vmBBoxUnit;
end;

procedure oxTCameraComponent.OnAdd();
begin
   inherited OnAdd;

   oxTEntity(Parent).Renderable := false;
end;

function oxTCameraComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

INITIALIZATION
   serialization := oxTSerialization.Create(oxTCameraComponent, @instance);
   serialization.AddRecordProperty('Camera', @oxTCameraComponent(nil).Camera, 'oxTCamera');
   serialization.AddRecordProperty('Projection', @oxTCameraComponent(nil).Camera, 'oxTProjection');

   descriptor.Create('camera', oxTCameraComponent);
   descriptor.Name := 'Camera';

FINALIZATION
   FreeObject(serialization);

END.
