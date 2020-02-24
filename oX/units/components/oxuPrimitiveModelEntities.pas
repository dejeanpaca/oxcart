{
   oxuPrimitiveModelEntities, common primitive model entities
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuPrimitiveModelEntities;

INTERFACE

   USES uStd,
      oxuEntity, oxuPrimitiveModelComponent;

TYPE
   { oxTPrimitiveModelEntities }

   oxTPrimitiveModelEntities = record
      class function Empty(): oxTEntity; static;
      class function Cube(): oxTEntity; static;
      class function Sphere(): oxTEntity; static;
      class function Plane(): oxTEntity; static;
      class function Circle(): oxTEntity; static;
      class function Disk(): oxTEntity; static;
      class function Cylinder(): oxTEntity; static;
      class function Torus(): oxTEntity; static;
      class function Cone(): oxTEntity; static;
   end;

VAR
   oxPrimitiveModelEntities: oxTPrimitiveModelEntities;

IMPLEMENTATION

function getEntity(const name: StdString; out component: oxTPrimitiveModelComponent): oxTEntity;
begin
   component := oxTPrimitiveModelComponent.Create();

   Result := oxEntity.New(name, component);
end;

{ oxTPrimitiveModelEntities }

class function oxTPrimitiveModelEntities.Empty(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Empty', component);
   component.Empty();
end;

class function oxTPrimitiveModelEntities.Cube(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Cube', component);
   component.Cube();
end;

class function oxTPrimitiveModelEntities.Sphere(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Sphere', component);
   component.Sphere();
end;

class function oxTPrimitiveModelEntities.Plane(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Plane', component);
   component.Plane();
end;

class function oxTPrimitiveModelEntities.Circle(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Circle', component);
   component.Circle();
end;

class function oxTPrimitiveModelEntities.Disk(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Disk', component);
   component.Disk();
end;

class function oxTPrimitiveModelEntities.Cylinder(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Cylinder', component);
   component.Cylinder();
end;

class function oxTPrimitiveModelEntities.Torus(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Torus', component);
   component.Torus();
end;

class function oxTPrimitiveModelEntities.Cone(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   Result := getEntity('Cone', component);
   component.Cone();
end;

END.
