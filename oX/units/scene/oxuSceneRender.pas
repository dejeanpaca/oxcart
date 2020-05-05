{
   oxuSceneRender, scene rendering
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuSceneRender;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      uOX,
      oxuProjectionType, oxuProjection, oxuViewportType, oxuViewport,
      oxuWindowTypes, oxuCamera, oxuRender, oxuTransform, oxuWindows, oxuSerialization,
      oxuMaterial, oxuGlobalInstances,
      oxuScene, oxuEntity, oxuSceneManagement, oxuRenderLayerComponent,
      oxuComponent, oxuCameraComponent, oxuRenderComponent;

TYPE

   { oxTSceneRenderParameters }

   oxTSceneRenderParameters = record
      Scene: oxTScene;
      Viewport: oxPViewport;
      Projection: oxPProjection;
      Camera: oxPCamera;
      Entity: oxTEntity;

      class procedure Init(out p: oxTSceneRenderParameters;
         setProjection: oxPProjection = nil; setCamera: oxPCamera = nil); static;
   end;

   { oxTSceneRenderer }
   oxTSceneRenderer = class
      procedure RenderLayer(layer: oxTRenderLayerComponent; var params: oxTSceneRenderParameters; const cameras: oxTComponentsList);

      procedure RenderCamera(var params: oxTSceneRenderParameters; camera: oxTCameraComponent; entity: oxTEntity = nil);
      procedure RenderCamera(var params: oxTSceneRenderParameters; entity: oxTEntity = nil);
      procedure Render(var params: oxTSceneRenderParameters);

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

      constructor Create(); virtual;
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

   if(setProjection <> nil) then
      p.Viewport := setProjection^.Viewport;

   if(p.Viewport = nil) then
      p.Viewport := oxViewport;

   p.Projection := setProjection;
   p.Camera := setCamera;
end;

{ oxTSceneRender }

constructor oxTSceneRender.Create();
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
      entity := params.Scene;

   if(not entity.Enabled) or (not camera.IsEnabled()) then
      exit;

   params.Camera := @camera.Camera;
   params.Projection := @camera.Projection;
   params.Projection^.Viewport := params.Viewport;
   params.Projection^.UpdateViewport();

   RenderCamera(params, entity);
end;

procedure oxTSceneRenderer.RenderCamera(var params: oxTSceneRenderParameters; entity: oxTEntity);
begin
   if(entity = nil) then
      entity := params.Scene;

   params.Viewport^.ClearColor := params.Scene.World.ClearColor;
   params.Viewport^.Apply();

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

procedure oxTSceneRenderer.Render(var params: oxTSceneRenderParameters);
var
   i: longint;
   cameras: oxTComponentsList;
   layers: oxTComponentsList;

begin
   if(params.Scene = nil) then
      exit;

   OnBegin();

   cameras.Initialize(cameras);
   layers.Initialize(layers);

   {$IFNDEF OX_LIBRARY}
   params.Scene.GetComponentsInChildren(oxTCameraComponent, cameras);
   params.Scene.GetComponents(oxTRenderLayerComponent, layers);
   {$ELSE}
   params.Scene.GetComponentsInChildren('oxTCameraComponent', cameras);
   params.Scene.GetComponents('oxTRenderLayerComponent', layers);
   {$ENDIF}

   if(layers.n > 0) then begin
      for i := 0 to layers.n - 1 do begin
         RenderLayer(oxTRenderLayerComponent(layers.List[i]), params, cameras);
      end;
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
      Matrix := params.Camera^.Matrix;

      {apply entity matrix to cam matrix}
      params.Camera^.Matrix := params.Camera^.Matrix * params.Entity.Matrix;

      for i := 0 to (params.Entity.Components.n - 1) do begin
         component := params.Entity.Components.List[i];

         if(oxTSerializable.IsClass(component.ClassParent, oxTRenderComponent)) then begin
            params.Camera^.Apply();
            oxTRenderComponent(component).Render();
         end;
      end;

      RenderEntities(params.Entity.Children, params);

      {restore cam matrix}
      params.Camera^.Matrix := Matrix;
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
   params: oxTSceneRenderParameters;

begin
   if(not oxSceneRender.RenderAutomatically) then
      exit;

   sceneWindow := oxSceneRender.Scenes[wnd.Index];
   renderer := sceneWindow.Renderer;

   if(renderer = nil) then
      renderer := oxSceneRender.Default;

   if(sceneWindow.Scene <> nil) then begin
      oxTSceneRenderParameters.Init(params);
      params.Scene := sceneWindow.Scene;

      renderer.Render(params);
   end;
end;

procedure init();
begin
   oxSceneRender.Default := oxTSceneRenderer.Create();

   if(oxSceneManagement.Enabled) and (oxSceneRender.RenderAutomatically) then
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
