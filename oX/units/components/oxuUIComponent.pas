{
   oxuUIComponent, ui component
   Copyright (c) 2019. Dejan Boras

   Started On:    14.11.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuUIComponent;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxuTransform, oxuProjectionType, oxuProjection,
      oxuCamera, oxuEntity, oxuSerialization,
      oxuComponent, oxuComponentDescriptors;

TYPE

   { oxTUIComponent }

   oxTUIComponent = class(oxTComponent)
      public
      Projection: oxTProjection;
      Camera: oxTCamera;

      UseSceneProjection: boolean;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure OnPositionChanged(); override;
      procedure OnRotationChanged(); override;

      procedure GetBoundingBox(out bbox: TBoundingBox); override;

      procedure OnAdd(); override;

      {get the descriptor for this component}
      function GetDescriptor(): oxPComponentDescriptor; override;

      {get projection used by this camera}
      function GetProjection(): oxPProjection;
   end;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;
   descriptor: oxTComponentDescriptor;

function instance(): TObject;
begin
   Result := oxTUIComponent.Create();
end;

{ oxTUIComponent }

constructor oxTUIComponent.Create();
begin
   inherited Create;

   Camera.Initialize();
   Projection.Initialize();
   UseSceneProjection := true;
end;

destructor oxTUIComponent.Destroy();
begin
   inherited Destroy();

   Camera.Dispose();
end;

procedure oxTUIComponent.OnPositionChanged();
begin
   Camera.vPos := oxTTransform(Parent).vPosition;
end;

procedure oxTUIComponent.OnRotationChanged();
begin
   Camera.vView := oxTTransform(Parent).GetForward();
   Camera.vUp := oxTTransform(Parent).GetUp();
   Camera.vRight := oxTTransform(Parent).GetRight();
end;

procedure oxTUIComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   bbox := vmBBoxUnit;
end;

procedure oxTUIComponent.OnAdd();
begin
   inherited OnAdd;

   oxTEntity(Parent).Renderable := false;
end;

function oxTUIComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

function oxTUIComponent.GetProjection(): oxPProjection;
begin
   Result := @Projection;

   if(UseSceneProjection) then
      Result := oxProjection;
end;

INITIALIZATION
   serialization := oxTSerialization.Create(oxTUIComponent, @instance);
   serialization.AddRecordProperty('Camera', @oxTUIComponent(nil).Camera, 'oxTCamera');
   serialization.AddRecordProperty('Projection', @oxTUIComponent(nil).Camera, 'oxTProjection');

   descriptor.Create('ui', oxTUIComponent);
   descriptor.Name := 'UI';

FINALIZATION
   FreeObject(serialization);

END.
