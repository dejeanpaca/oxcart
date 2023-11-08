{
   oxuCameraEntity, common camera entities
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
   component := oxTCameraComponent.Create();
   Result := oxEntity.New('Camera', component);
end;

{ oxTCameraEntity }

class function oxTCameraEntity.Default(): oxTEntity;
var
   component: oxTCameraComponent;

begin
   Result := GetEntity(component);
end;

class function oxTCameraEntity.CreateInScene(): oxTCameraComponent;
begin
   oxScene.Add(GetEntity(Result));
end;

END.
