{
   oxuCameraEntity, common camera entities
   Copyright (c) 2017. Dejan Boras

   Started On:    18.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuCameraEntity;

INTERFACE

   USES
      uStd,
      {ox}
      oxuEntity, oxuCameraComponent;

TYPE
   { oxTCameraEntity }

   oxTCameraEntity = record
      class function Default(): oxTEntity; static;
   end;

VAR
   oxCameraEntity: oxTCameraEntity;

IMPLEMENTATION

function getEntity(out component: oxTCameraComponent): oxTEntity;
begin
   result := oxTEntity.Create();

   component := oxTCameraComponent.Create();
   result.Name := 'Camera';
   result.Add(component);
end;

{ oxTCameraEntity }

class function oxTCameraEntity.Default(): oxTEntity;
var
   component: oxTCameraComponent;

begin
   result := getEntity(component);
end;

END.
