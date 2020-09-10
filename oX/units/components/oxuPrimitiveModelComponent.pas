{
   oxuPrimitiveModelComponent, primitive model component
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuPrimitiveModelComponent;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxuComponent, oxuComponentDescriptors, oxuRenderComponent, oxuEntity,
      oxumPrimitive, oxuSerialization;

TYPE

   { oxTPrimitiveModelComponent }

   oxTPrimitiveModelComponent = class(oxTRenderComponent)
      public
      Model: oxTPrimitiveModel;

      constructor Create(); override;

      procedure Render(); override;

      procedure GetBoundingBox(out bbox: TBoundingBox); override;

      procedure Empty();
      procedure Cube();
      procedure Sphere();
      procedure Plane();
      procedure Circle();
      procedure Disk();
      procedure Cylinder();
      procedure Torus();
      procedure Cone();

      procedure Deserialized(); override;

      function GetDescriptor(): oxPComponentDescriptor; override;

      class function GetEntity(out component: oxTPrimitiveModelComponent): oxTEntity; static;
   end;

IMPLEMENTATION

VAR
   serializer: oxTSerialization;
   descriptor: oxTComponentDescriptor;

{ oxTPrimitiveModelComponent }

constructor oxTPrimitiveModelComponent.Create();
begin
   inherited Create;

   oxmPrimitive.Init(Model);
end;

procedure oxTPrimitiveModelComponent.Render();
begin
   Model.Render();
end;

procedure oxTPrimitiveModelComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   Model.Mesh.GetBoundingBox(bbox);
end;

procedure oxTPrimitiveModelComponent.Empty();
begin
   Model.Dispose();
end;

procedure oxTPrimitiveModelComponent.Cube();
begin
   Model.Dispose();
   Model.Cube();
end;

procedure oxTPrimitiveModelComponent.Sphere();
begin
   Model.Dispose();
   Model.Sphere(oxmPRIMITIVE_SPHERE_METHOD_ENHANCED);
end;

procedure oxTPrimitiveModelComponent.Plane();
begin
   Model.Dispose();
   Model.Quad();
end;

procedure oxTPrimitiveModelComponent.Circle();
begin
   Model.Dispose();
   Model.Circle();
end;

procedure oxTPrimitiveModelComponent.Disk();
begin
   Model.Dispose();
   Model.Disk();
end;

procedure oxTPrimitiveModelComponent.Cylinder();
begin
   Model.Dispose();
   Model.Cylinder();
end;

procedure oxTPrimitiveModelComponent.Torus();
begin
   Model.Dispose();
   Model.Torus();
end;

procedure oxTPrimitiveModelComponent.Cone();
begin
   Model.Dispose();
   Model.Cone();
end;

procedure oxTPrimitiveModelComponent.Deserialized();
begin
   inherited Deserialized;

   Model.FromType();
   OnChange();
end;

function oxTPrimitiveModelComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

class function oxTPrimitiveModelComponent.GetEntity(out component: oxTPrimitiveModelComponent): oxTEntity;
begin
   component := oxTPrimitiveModelComponent.Create();
   Result := oxEntity.New('Primitive', component);
end;

function instance(): TObject;
begin
   Result := oxTPrimitiveModelComponent.Create();
end;

INITIALIZATION
   serializer := oxTSerialization.Create(oxTPrimitiveModelComponent, @instance);
   serializer.AddProperty('primitiveType', @oxTPrimitiveModelComponent(nil).Model.primitiveType, oxSerialization.Types.Enum, TypeInfo(oxTPrimitiveModelType));

   descriptor.Create('primitive_model', oxTPrimitiveModelComponent);
   descriptor.Name := 'Primitive Model';

FINALIZATION
   FreeObject(serializer);

END.
