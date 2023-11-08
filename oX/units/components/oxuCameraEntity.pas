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
      oxuScene, oxuEntity, oxuCameraComponent;

TYPE
   { oxTCameraEntity }

   oxTCameraEntity = record
      class function GetEntity(out component: oxTCameraComponent): oxTEntity; static;
      class function Default(): oxTEntity; static;
      class function CreateInScene(): oxTCameraComponent; static;
   end;

VAR
   oxCameraEntity: oxTCameraEntity;

IMPLEMENTATION

class function oxTCameraEntity.GetEntity(out component: oxTCameraComponent): oxTEntity;
begin
   Result := oxTEntity.Create();

   component := oxTCameraComponent.Create();
   Result.Name := 'Camera';
   Result.Add(component);
end;

{ oxTCameraEntity }

class function oxTCameraEntity.Default(): oxTEntity;
var
   component: oxTCameraComponent;

begin
   Result := getEntity(component);
end;

class function oxTCameraEntity.CreateInScene(): oxTCameraComponent;
var
   entity: oxTEntity;

begin
   entity := GetEntity(Result);

   oxScene.Add(entity);
end;

END.
