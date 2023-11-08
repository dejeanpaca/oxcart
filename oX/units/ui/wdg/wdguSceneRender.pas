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
      oxuTypes, oxuWindowTypes,
      oxuProjection, oxuCamera,
      oxuSceneRender, oxuScene,
      {ui}
      uiuWindowRender, uiuDraw,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase, wdguViewport;

TYPE

   { wdgTSceneRender }

   wdgTSceneRender = class(wdgTViewport)
      {a renderer for the scene}
      SceneRenderer: oxTSceneRenderer;
      {render a specific camera}
      Camera: oxTCamera;

      RenderSceneCameras: boolean;
      {render specified scene, but if set to nil render default scene}
      Scene: oxTScene;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure Render(); override;

      procedure OnSceneRenderEnd(); virtual;

      procedure CleanupRender();
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
   Projection.Initialize();
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
   SceneRenderer.Scene := Scene;

   if(not RenderSceneCameras) then begin
      oxTSceneRenderParameters.Init(params, @Projection, @Camera);
      SceneRenderer.RenderCamera(params);
   end else
      SceneRenderer.Render(Projection);

   OnSceneRenderEnd();

   CleanupRender();
end;

procedure wdgTSceneRender.OnSceneRenderEnd();
begin

end;

procedure wdgTSceneRender.CleanupRender();
begin
   oxTWindow(oxwParent).Projection.Apply(false);
   uiWindowRender.Prepare(oxTWIndow(oxwParent));

   uiDraw.Start();
end;

INITIALIZATION
   wdgSceneRender.Internal.Register('widget.scene_render', @init, @deinit);

END.
