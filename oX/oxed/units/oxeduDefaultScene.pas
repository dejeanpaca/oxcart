{
   oxeduDefaultScene, creates a default scene
   Copyright (C) 2016. Dejan Boras

   Started On:    12.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduDefaultScene;

INTERFACE

   USES
      uStd,
      {ox}
      oxuEntity, oxuScene, oxuPrimitiveModelEntities, oxuCameraEntity,
      {oxed}
      uOXED;

TYPE

   { oxedTDefaultScene }

   oxedTDefaultScene = record
      procedure Create(scene: oxTScene);
      procedure Create();
   end;

VAR
   oxedDefaultScene: oxedTDefaultScene;

IMPLEMENTATION

{ oxedTDefaultScene }

procedure oxedTDefaultScene.Create(scene: oxTScene);
var
   cube: oxTEntity;
   camera: oxTEntity;

begin
   scene.Empty();

  if(scene.Name = '') then
      scene.Name := 'Scene';

   cube := oxPrimitiveModelEntities.Cube();

   camera := oxCameraEntity.Default();
   camera.Name := 'Main Camera';

   camera.SetPosition(0, 0, 5);
   camera.SetRotation(0, 180, 0);

   scene.Add(camera);
   scene.Add(cube);
end;

procedure oxedTDefaultScene.Create();
begin
   Create(oxScene);
end;

END.

