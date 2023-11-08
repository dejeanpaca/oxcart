{
   oxeduSceneView, oxed scene view window
   Copyright (C) 2016. Dejan Boras

   Started On:    26.12.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneView;

INTERFACE

   USES
      uStd,
      {ox}
      oxuSceneRender,
      {oxed}
      uOXED, oxeduMenubar, oxeduWindow, oxeduSceneWindow;

TYPE

   { oxedTSceneViewWindow }

   oxedTSceneViewWindow = class(oxedTSceneWindow)
      procedure Initialize; override;
   end;

   oxedTSceneView = class(oxedTWindowClass)
   end;

VAR
   oxedSceneView: oxedTSceneView;

IMPLEMENTATION

procedure openSceneView();
begin
   oxedSceneView.CreateWindow();
end;

procedure init();
begin
   oxedSceneView := oxedTSceneView.Create('View', oxedTSceneViewWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem('Scene View', @openSceneView);
end;

procedure deinit();
begin
   FreeObject(oxedSceneView);
end;

{ oxedTSceneViewWindow }

procedure oxedTSceneViewWindow.Initialize;
begin
   inherited Initialize;

   SceneRenderer := oxSceneRender.Default;
   SceneRenderer.Scene := Scene;
end;

INITIALIZATION
   oxed.Init.Add('scene.view', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

END.

