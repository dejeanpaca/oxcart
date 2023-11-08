{
   wdguSceneRender, scene renderer widget
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT wdguSceneRender;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      oxuProjection, oxuProjectionType, oxuCamera,
      oxuSceneRender, oxuScene,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase, wdguViewport;

TYPE

   { wdgTSceneRender }

   wdgTSceneRender = class(wdgTViewport)
      {a renderer for the scene}
      SceneRenderer: oxTSceneRenderer;
      {scene projection}
      Projection: oxTProjection;
      {render a specific camera}
      Camera: oxTCamera;

      RenderSceneCameras: boolean;
      {render specified scene, but if set to nil render default scene}
      Scene: oxTScene;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure Render(); override;

      procedure OnSceneRenderEnd(); virtual;
   end;

   wdgTSceneRenderGlobal = class(specialize wdgTBase<wdgTSceneRender>)
      Internal: uiTWidgetClass; static;
   end;

VAR
   wdgSceneRender: wdgTSceneRenderGlobal;

IMPLEMENTATION

procedure init();
begin
   wdgSceneRender.internal.Done(wdgTSceneRender);

   wdgSceneRender := wdgTSceneRenderGlobal.Create(wdgSceneRender.Internal);
end;

procedure deinit();
begin
   FreeObject(wdgSceneRender);
end;

{ wdgTSceneRender }

constructor wdgTSceneRender.Create();
begin
   inherited;

   SceneRenderer := oxSceneRender.Default;
   RenderSceneCameras := true;
   oxTProjection.Create(Projection);
   Camera.Initialize();
end;

destructor wdgTSceneRender.Destroy();
begin
   inherited Destroy;

   Camera.Dispose();

   if(SceneRenderer <> oxSceneRender.Default) then
      FreeObject(SceneRenderer);
end;

procedure wdgTSceneRender.Render();
var
   params: oxTSceneRenderParameters;

begin
   ProjectionStart();

   SceneRenderer.Scene := Scene;

   if(not RenderSceneCameras) then begin
      oxTSceneRenderParameters.Init(params, @Projection, @Camera);
      SceneRenderer.RenderCamera(params);
   end else begin
      SceneRenderer.Render(Projection);
   end;

   OnSceneRenderEnd();

   CleanupRender();
end;

procedure wdgTSceneRender.OnSceneRenderEnd();
begin

end;

INITIALIZATION
   wdgSceneRender.Internal.Register('widget.scene_render', @init, @deinit);

END.
