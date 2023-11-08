{
   oxuPrimitiveModelComponent, primitive model component
   Copyright (c) 2017. Dejan Boras

   Started On:    17.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuPrimitiveModelComponent;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      oxumPrimitive, oxuComponent, oxuRenderComponent, oxuSerialization;

TYPE

   { oxTPrimitiveModelComponent }

   oxTPrimitiveModelComponent = class(oxTRenderComponent)
      public
      Model: oxTPrimitiveModel;

      constructor Create(); override;

      procedure Render; override;

      procedure GetBoundingBox(out bbox: TBoundingBox); override;

      procedure Cube();
      procedure Sphere();
      procedure Plane();

      procedure Deserialized; override;

      function GetDescriptor(): oxPComponentDescriptor; override;
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

procedure oxTPrimitiveModelComponent.Render;
begin
   Model.Render();
end;

procedure oxTPrimitiveModelComponent.GetBoundingBox(out bbox: TBoundingBox);
begin
   Model.Mesh.GetBoundingBox(bbox);
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

procedure oxTPrimitiveModelComponent.Deserialized;
begin
   inherited Deserialized;

   Model.FromType();
   OnChange();
end;

function oxTPrimitiveModelComponent.GetDescriptor(): oxPComponentDescriptor;
begin
   Result := @descriptor;
end;

function instance(): TObject;
begin
   Result := oxTPrimitiveModelComponent.Create();
end;

INITIALIZATION
   serializer := oxTSerialization.Create(oxTPrimitiveModelComponent, @instance);
   serializer.AddProperty('primitiveType', @oxTPrimitiveModelComponent(nil).Model.primitiveType, oxSerialization.Types.Enum, TypeInfo(oxTPrimitiveModelType));

   descriptor.Create('primitive_model');
   descriptor.Name := 'Primitive Model';

FINALIZATION
   FreeObject(serializer);

END.
