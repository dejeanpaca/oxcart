{
   oxuPrimitiveModelEntities, common primitive model entities
   Copyright (c) 2017. Dejan Boras

   Started On:    18.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuPrimitiveModelEntities;

INTERFACE

   USES uStd,
      oxuEntity, oxuPrimitiveModelComponent;

TYPE
   { oxTPrimitiveModelEntities }

   oxTPrimitiveModelEntities = record
      class function Cube(): oxTEntity; static;
      class function Sphere(): oxTEntity; static;
      class function Plane(): oxTEntity; static;
   end;

VAR
   oxPrimitiveModelEntities: oxTPrimitiveModelEntities;

IMPLEMENTATION

function getEntity(out component: oxTPrimitiveModelComponent): oxTEntity;
begin
   result := oxTEntity.Create();

   component := oxTPrimitiveModelComponent.Create();
   result.Add(component);
end;

{ oxTPrimitiveModelEntities }

class function oxTPrimitiveModelEntities.Cube(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   result := getEntity(component);
   result.Name := 'Cube';

   component.Cube();
end;

class function oxTPrimitiveModelEntities.Sphere(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   result := getEntity(component);
   result.Name := 'Sphere';

   component.Sphere();
end;

class function oxTPrimitiveModelEntities.Plane(): oxTEntity;
var
   component: oxTPrimitiveModelComponent;

begin
   result := getEntity(component);
   result.Name := 'Plane';

   component.Plane();
end;

END.
