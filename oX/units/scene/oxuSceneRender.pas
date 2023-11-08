{
   oxuSceneRender, scene rendering
   Copyright (c) 2017. Dejan Boras

   Started On:    16.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuSceneRender;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      uOX,
      oxuProjectionType, oxuProjection,
      oxuWindowTypes, oxuCamera, oxuRender, oxuTransform, oxuWindows, oxuSerialization,
      oxuMaterial, oxuGlobalInstances,
      oxuScene, oxuEntity, oxuSceneManagement, oxuRenderLayerComponent,
      oxuComponent, oxuCameraComponent, oxuRenderComponent;

TYPE

   { oxTSceneRenderParameters }

   oxTSceneRenderParameters = record
      Projection: oxPProjection;
      Camera: oxPCamera;
      Entity: oxTEntity;

      class procedure Init(out p: oxTSceneRenderParameters;
         setProjection: oxPProjection = nil; setCamera: oxPCamera = nil); static;
   end;

   { oxTSceneRenderer }
   oxTSceneRenderer = class
      Scene: oxTScene;

      procedure RenderLayer(layer: oxTRenderLayerComponent; var params: oxTSceneRenderParameters; const cameras: oxTComponentsList);

      procedure RenderCamera(var params: oxTSceneRenderParameters; camera: oxTCameraComponent; entity: oxTEntity = nil);
      procedure RenderCamera(var params: oxTSceneRenderParameters; entity: oxTEntity = nil);
      procedure Render(const projection: oxTProjection);

      procedure RenderEntities(const entities: oxTEntities; var params: oxTSceneRenderParameters);
      procedure RenderEntity(var params: oxTSceneRenderParameters); virtual;

      procedure CameraBegin(var {%H-}params: oxTSceneRenderParameters); virtual;
      procedure CameraEnd(var {%H-}params: oxTSceneRenderParameters); virtual;

      procedure OnBegin(); virtual;
      procedure OnEnd(); virtual;
   end;

   oxTSceneRenderWindow = record
      Scene: oxTScene;
      Renderer: oxTSceneRenderer;
   end;

TYPE
   oxTSceneRender = class
      public
      RenderAutomatically: boolean;
      {automatically apply scene change}
      AutoApplyChange: boolean; static;

      Default: oxTSceneRenderer; static;

      {scenes set to automatically render per window}
      Scenes: array[0..oxcMAX_WINDOW] of oxTSceneRenderWindow;

      constructor Create; virtual;
   end;

VAR
   {scene rendering}
   oxSceneRender: oxTSceneRender;

IMPLEMENTATION

{ oxTSceneRenderParameters }

class procedure oxTSceneRenderParameters.Init(out p: oxTSceneRenderParameters;
   setProjection: oxPProjection; setCamera: oxPCamera);
begin
   ZeroOut(p, SizeOf(p));

   p.Projection := setProjection;
   p.Camera := setCamera;
end;

{ oxTSceneRender }

constructor oxTSceneRender.Create;
begin
   RenderAutomatically := true;
end;

{ oxTSceneRenderer }

procedure oxTSceneRenderer.RenderLayer(layer: oxTRenderLayerComponent; var params: oxTSceneRenderParameters; const cameras: oxTComponentsList);
var
   i: loopint;

begin
   for i := 0 to cameras.n - 1 do begin
      RenderCamera(params, oxTCameraComponent(cameras.List[i]), oxTEntity(layer.Parent));
   end;
end;

procedure oxTSceneRenderer.RenderCamera(var params: oxTSceneRenderParameters; camera: oxTCameraComponent; entity: oxTEntity);
begin
   if(entity = nil) then
      entity := Scene;

   if(not entity.Enabled) or (not camera.IsEnabled()) then
      exit;

   params.Camera := @camera.Camera;

   if(camera.UseSceneProjection) then
      params.Projection := params.Projection
   else
      params.Projection := @camera.Projection;

   RenderCamera(params, entity);
end;

procedure oxTSceneRenderer.RenderCamera(var params: oxTSceneRenderParameters; entity: oxTEntity);
begin
   if(entity = nil) then
      entity := Scene;

   params.Projection^.ClearColor := Scene.World.ClearColor;

   params.Projection^.Apply();
   params.Camera^.LookAt();

   oxTransform.Identity();
   oxTransform.Apply();

   oxRender.DepthDefault();

   oxMaterial.Default.Apply();

   CameraBegin(params);
   RenderEntities(entity.Children, params);
   CameraEnd(params);
end;

procedure oxTSceneRenderer.Render(const projection: oxTProjection);
var
   i: longint;
   cameras: oxTComponentsList;
   params: oxTSceneRenderParameters;

   layers: oxTComponentsList;

begin
   if(Scene = nil) then
      exit;

   OnBegin();

   cameras.Initialize(cameras);
   layers.Initialize(layers);

   {$IFNDEF OX_LIBRARY}
   Scene.GetComponentsInChildren(oxTCameraComponent, cameras);
   Scene.GetComponents(oxTRenderLayerComponent, layers);
   {$ELSE}
   Scene.GetComponentsInChildren('oxTCameraComponent', cameras);
   Scene.GetComponents('oxTRenderLayerComponent', layers);
   {$ENDIF}

   oxTSceneRenderParameters.Init(params);
   params.Projection := @projection;

   if(layers.n > 0) then begin
      for i := 0 to layers.n - 1 do begin
         params.Projection := @projection;
         RenderLayer(oxTRenderLayerComponent(layers.List[i]), params, cameras);
      end;
      writeln('Can haz layers');
   end;

   for i := 0 to (cameras.n - 1) do begin
      RenderCamera(params, oxTCameraComponent(cameras.List[i]));
   end;

   cameras.Dispose();

   OnEnd();
end;

procedure oxTSceneRenderer.RenderEntities(const entities: oxTEntities; var params: oxTSceneRenderParameters);
var
   i: loopint;

begin
   for i := 0 to entities.n - 1 do begin
      params.Entity := oxTEntity(entities.List[i]);

      if(not params.Entity.Enabled) then
         continue;

      RenderEntity(params);
   end;
end;

procedure oxTSceneRenderer.RenderEntity(var params: oxTSceneRenderParameters);
var
   i: loopint;
   component: oxTComponent;
   Matrix: TMatrix4f;

begin
   if(params.Entity.Renderable) then begin
      {backup matrix}
      Matrix := params.Camera^.Transform.Matrix;

      {apply entity matrix to cam matrix}
      params.Camera^.Transform.Matrix := params.Camera^.Transform.Matrix * params.Entity.Matrix;

      for i := 0 to (params.Entity.Components.n - 1) do begin
         component := params.Entity.Components.List[i];

         if(oxTSerializable.IsClass(component.ClassParent, oxTRenderComponent)) then begin
            params.Camera^.Transform.Apply();
            oxTRenderComponent(component).Render();
         end;
      end;

      RenderEntities(params.Entity.Children, params);

      {restore cam matrix}
      params.Camera^.Transform.Matrix := Matrix;
   end;
end;

procedure oxTSceneRenderer.CameraBegin(var params: oxTSceneRenderParameters);
begin

end;

procedure oxTSceneRenderer.CameraEnd(var params: oxTSceneRenderParameters);
begin
end;

procedure oxTSceneRenderer.OnBegin();
begin
end;

procedure oxTSceneRenderer.OnEnd();
begin
end;

procedure render(wnd: oxTWindow);
var
   sceneWindow: oxTSceneRenderWindow;
   renderer: oxTSceneRenderer;

begin
   sceneWindow := oxSceneRender.Scenes[wnd.Index];
   renderer := sceneWindow.Renderer;

   if(renderer = nil) then
      renderer := oxSceneRender.Default;

   if(sceneWindow.Scene <> nil) then begin
      renderer.Scene := sceneWindow.Scene;
      renderer.Render(wnd.Projection);
   end;
end;

procedure init();
begin
   oxSceneRender.Default := oxTSceneRenderer.Create();

   if(oxSceneManagement.Enabled) then
      oxWindows.OnRender.Add(@render);
end;

procedure deinit();
begin
   FreeObject(oxSceneRender.Default);
end;

function instanceGlobal(): TObject;
begin
   Result := oxTSceneRender.Create();
end;

procedure change();
begin
   if(oxSceneRender.AutoApplyChange) then
      oxSceneRender.Scenes[0].Scene := oxScene;
end;

INITIALIZATION
   oxGlobalInstances.Add(oxTSceneRender, @oxSceneRender, @instanceGlobal);

   ox.Init.Add('ox.scene_render', @init, @deinit);
   oxSceneManagement.OnSceneChange.Add(@change);

   {$IFDEF OX_LIBRARY}
   oxSceneRender.AutoApplyChange := true;
   {$ENDIF}

END.
