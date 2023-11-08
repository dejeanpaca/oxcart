{
   oxuSceneRender, scene rendering
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSceneRender;

INTERFACE

   USES
      uStd, vmVector,
      {ox}
      uOX,
      oxuProjectionType, oxuProjection, oxuViewportType, oxuViewport,
      oxuWindowTypes, oxuCamera,
      oxuRender, oxuRenderingContext, oxuSurfaceRender,
      oxuTransform, oxuWindows, oxuSerialization,
      oxuMaterial, oxuGlobalInstances,
      {scene}
      oxuScene, oxuEntity, oxuSceneManagement,
      {components}
      oxuRenderLayerComponent, oxuComponent, oxuCameraComponent, oxuRenderComponent;

TYPE
   oxTSceneRenderOrderEntry = record
      Name: StdString;
      Index: loopint;
   end;

   oxTSceneRenderOrderEntryList = specialize TSimpleList<oxTSceneRenderOrderEntry>;

   oxPSceneRenderOrder = ^oxTSceneRenderOrder;

   { oxTSceneRenderOrder }

   oxTSceneRenderOrder = record
      List: oxTSceneRenderOrderEntryList;

      class procedure Initialize(out order: oxTSceneRenderOrder); static;

      {sort entries in this order by index}
      procedure Sort();
      {add an entry to this order}
      procedure Add(const name: StdString);
      {clear all entries in this order}
      procedure Clear();
   end;

   { oxTSceneRenderParameters }

   oxTSceneRenderParameters = record
      Scene: oxTScene;
      Viewport: oxPViewport;
      Projection: oxPProjection;
      Camera: oxPCamera;
      Entity: oxTEntity;

      RenderOrder: oxPSceneRenderOrder;

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

   oxPSceneRender = ^oxTSceneRender;

   oxTSceneRender = object
      public
      RenderAutomatically: boolean;
      {automatically apply scene change}
      AutoApplyChange: boolean;

      Default: oxTSceneRenderer;

      {scenes set to automatically render per window}
      Scenes: array[0..oxcMAX_WINDOW] of oxTSceneRenderWindow;

      RenderOrder: oxTSceneRenderOrder;
      SurfaceRenderer: oxTSurfaceRenderer; static;

      constructor Create();
   end;

VAR
   {scene rendering}
   oxSceneRender: oxTSceneRender;

IMPLEMENTATION

procedure render(var context: oxTRenderingContext);
var
   sceneWindow: oxTSceneRenderWindow;
   renderer: oxTSceneRenderer;
   params: oxTSceneRenderParameters;
   wnd: oxTWindow;

begin

   if(not oxSceneManagement.Enabled) or (not oxSceneRender.RenderAutomatically) then
      exit;

   wnd := context.Window;

   {TODO: Allow rendering any surface instead of these hacks}
   if(wnd = nil) then
      exit;

   sceneWindow := oxSceneRender.Scenes[wnd.Index];
   renderer := sceneWindow.Renderer;

   if(renderer = nil) then
      renderer := oxSceneRender.Default;

   if(sceneWindow.Scene <> nil) then begin
      oxTSceneRenderParameters.Init(params);
      params.Scene := sceneWindow.Scene;
      params.RenderOrder := @oxSceneRender.RenderOrder;

      renderer.Render(params);
   end;
end;

{ oxTSceneRenderOrder }

class procedure oxTSceneRenderOrder.Initialize(out order: oxTSceneRenderOrder);
begin
   ZeroOut(order, SizeOf(order));
   oxTSceneRenderOrderEntryList.InitializeValues(order.List, 64);
end;

procedure oxTSceneRenderOrder.Sort();
begin
   {TODO: Implement sorting}
end;

procedure oxTSceneRenderOrder.Add(const name: StdString);
var
   entry: oxTSceneRenderOrderEntry;

begin
   entry.Index := List.n;
   entry.Name := name;

   List.Add(entry);
end;

procedure oxTSceneRenderOrder.Clear();
begin
   List.Dispose();
end;

{ oxTSceneRenderParameters }

class procedure oxTSceneRenderParameters.Init(out p: oxTSceneRenderParameters;
   setProjection: oxPProjection; setCamera: oxPCamera);
begin
   ZeroOut(p, SizeOf(p));

   if(setProjection <> nil) then
      p.Viewport := setProjection^.Viewport;

   if(p.Viewport = nil) then
      p.Viewport := oxRenderingContext.Viewport;

   p.Projection := setProjection;
   p.Camera := setCamera;
end;

{ oxTSceneRender }

constructor oxTSceneRender.Create();
begin
   RenderAutomatically := true;

   oxTSceneRenderOrder.Initialize(RenderOrder);

   RenderOrder.Add('skybox');
   RenderOrder.Add('scene');
   RenderOrder.Add('post-process');
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
      if(params.RenderOrder <> nil) then begin
         {TODO: Render layers by given params.RenderOrder}
      end else begin
         for i := 0 to layers.n - 1 do begin
            RenderLayer(oxTRenderLayerComponent(layers.List[i]), params, cameras);
         end;
      end;
   end else begin
      for i := 0 to (cameras.n - 1) do begin
         RenderCamera(params, oxTCameraComponent(cameras.List[i]));
      end;
   end;

   layers.Dispose();
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

procedure init();
begin
   oxSceneRender.Default := oxTSceneRenderer.Create();
end;

procedure deinit();
begin
   FreeObject(oxSceneRender.Default);
end;

procedure change();
begin
   if(oxSceneRender.AutoApplyChange) then
      oxSceneRender.Scenes[0].Scene := oxScene;
end;

INITIALIZATION
   oxSceneRender.Create();
   oxGlobalInstances.Add('oxTSceneRender', @oxSceneRender);

   ox.Init.Add('ox.scene_render', @init, @deinit);
   oxSceneManagement.OnSceneChange.Add(@change);

   {$IFDEF OX_LIBRARY}
   oxSceneRender.AutoApplyChange := true;
   {$ENDIF}

   oxSurfaceRender.Get(oxTSceneRender.SurfaceRenderer, @render);
   oxTSceneRender.SurfaceRenderer.Name := 'scene';

END.
