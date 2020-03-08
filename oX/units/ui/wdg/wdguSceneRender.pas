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
      oxuProjection,
      oxuSceneRender, oxuScene,
      {ui}
      uiuWindowRender, uiuDraw,
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase, wdguViewport;

TYPE

   { wdgTSceneRender }

   wdgTSceneRender = class(wdgTViewport)
      {a renderer for the scene}
      SceneRenderer: oxTSceneRenderer;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure Render(); override;

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
end;

destructor wdgTSceneRender.Destroy();
begin
   inherited Destroy;

   if(SceneRenderer <> oxSceneRender.Default) then
      FreeObject(SceneRenderer);
end;

procedure wdgTSceneRender.Render();
begin
   if(oxScene = nil) then
      exit;

   SceneRenderer.Render(Projection);

   CleanupRender();
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
