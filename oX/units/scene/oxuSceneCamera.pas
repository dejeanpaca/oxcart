{
   oxuSceneCamera, oX scene camera management
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSceneCamera;

INTERFACE

   USES
     {oX}
     oxuCamera, oxuScene;

TYPE
   {camera rendering clear mode}
   oxTSceneCameraClearMode = (
      oxSCENE_CAMERA_CLEAR_NONE,
      oxSCENE_CAMERA_CLEAR_COLOR,
      oxSCENE_CAMERA_CLEAR_SKYBOX
   );

   { oxTSceneCamera }

   oxTSceneCamera = class(oxTCamera)
      ClearMode: oxTSceneCameraClearMode;
      ClearDepth: boolean;

      constructor Create; override;
      {render a scene}
      procedure Render(scene: oxTScene);
   end;

IMPLEMENTATION

{ oxTSceneCamera }

constructor oxTSceneCamera.Create;
begin
   inherited Create;

   ClearMode := oxSCENE_CAMERA_CLEAR_COLOR;
   ClearDepth := true;
end;

procedure oxTSceneCamera.Render(scene: oxTScene);
begin

end;

END.
