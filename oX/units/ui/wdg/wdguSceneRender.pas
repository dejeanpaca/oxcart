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
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase, wdguViewport;

TYPE
   wdgTSceneRender = class(wdgTViewport)
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

INITIALIZATION
   wdgSceneRender.Internal.Register('widget.scene_render', @init, @deinit);

END.
