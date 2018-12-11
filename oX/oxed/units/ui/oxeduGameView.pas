{
   oxeduGameView, oxed scene view window
   Copyright (C) 2016. Dejan Boras

   Started On:    19.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduGameView;

INTERFACE

   USES
      uStd, uInit, uLog,
      {app}
      appuKeys, appuMouse,
      {ox}
      oxuScene, oxuSceneRender, oxuWindows, oxuRenderer, oxuWindow,
      oxuGlobalInstances, oxuKeyboardControl, oxuPointerControl, oxuGlobalKeys,
      {ui}
      uiuTypes, uiuWindow, uiuWindowTypes,
      {oxed}
      uOXED, oxeduSettings, oxeduSceneWindow, oxeduMenubar, oxeduWindow, oxeduProjectRunner, oxeduLib;

TYPE
   { oxedTGameViewWindow }

   oxedTGameViewWindow = class(oxedTSceneWindow)
      constructor Create; override;

      procedure Render; override;

      function Key(var k: appTKeyEvent): boolean; override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      procedure Hover(x, y: longint; {%H-}what: uiTHoverEvent); override;

      procedure Initialize; override;

      protected
         procedure RPositionChanged; override;
         procedure PositionChanged; override;
         procedure SizeChanged; override;
   end;

   oxedTGameView = class(oxedTWindowClass)
   end;

VAR
   oxedGameView: oxedTGameView;

IMPLEMENTATION

VAR
   projectKey: oxTKeyGlobal;
   projectPointer: oxTPointerGlobal;


procedure openGameView();
begin
   oxedGameView.CreateWindow();
end;

procedure init();
begin
   oxedGameView := oxedTGameView.Create('Game', oxedTGameViewWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem('Game View', @openGameView);
end;

procedure deinit();
begin
   FreeObject(oxedGameView);
end;

{ oxedTSceneViewWindow }

constructor oxedTGameViewWindow.Create;
begin
   inherited Create;

   RenderAllCameras := true;
end;

procedure oxedTGameViewWindow.Render;
begin
   {we don't render anything, as the game will render itself}
   if(oxedTProjectRunner.CanRender()) then begin
      oxedLib.oxWindows.Render();

      CleanupRender();
   end;
end;

function oxedTGameViewWindow.Key(var k: appTKeyEvent): boolean;
var
   newK: appTKeyEvent;

begin
   Result := false;

   if(projectKey <> nil) then begin
      newK := k; {use copy so the original is not modified}

      {we don't pass our own global keys to the project}
      if(oxGlobalKeys.Find(k.Key) = -1) then
         Result := projectKey.Handle(newK);
   end;
end;

procedure GetMouseEvent(wnd: uiTWindow; var m: appTMouseEvent; x, y: longint);
begin
   m.x := x;
   m.y := wnd.Dimensions.h - y;
   {TODO: Find the library window attached to this wnd and set it to the event}
end;

procedure oxedTGameViewWindow.Point(var e: appTMouseEvent; x, y: longint);
var
   newM: appTMouseEvent;

begin
   if(projectPointer <> nil) then begin
      newM := e; {use copy so the original is not modified}
      GetMouseEvent(Self, newM, x, y);
      projectPointer.Handle(newM);
   end;
end;

procedure oxedTGameViewWindow.Hover(x, y: longint; what: uiTHoverEvent);
var
   newM: appTMouseEvent;

begin
   if(projectPointer <> nil) then begin
      appm.Init(newM);
      newM.Action := appmcMOVED;
      GetMouseEvent(Self, newM, x, y);
      projectPointer.Handle(newM);
   end;
end;

procedure oxedTGameViewWindow.Initialize;
begin
   inherited Initialize;

   oxWindows.ExternalWindows.Dispose();
   oxWindows.ExternalWindows.Add(Self);

   SceneRenderer := oxSceneRender.Default;
   SceneRenderer.Scene := Scene;
end;

procedure oxedTGameViewWindow.RPositionChanged;
begin
   inherited RPositionChanged;

   if(oxedLib.oxWindows <> nil) then
      oxedLib.oxWindows.w[0].SetupProjection();
end;

procedure oxedTGameViewWindow.PositionChanged;
begin
   inherited PositionChanged;

   if(oxedLib.oxWindows <> nil) then
      oxedLib.oxWindows.w[0].SetupProjection();
end;

procedure oxedTGameViewWindow.SizeChanged;
begin
   inherited SizeChanged;

   if(oxedLib.oxWindows <> nil) then begin
      oxedLib.oxWindows.w[0].SetDimensions(Dimensions.w, Dimensions.h, false);
      oxedLib.oxWindows.w[0].SetupProjection();
   end;
end;

procedure beforeProjectStart();
begin
   if(oxedGameView.Instance = nil) then
      oxedGameView.CreateWindow()
   else begin
      if(oxedSettings.FocusGameViewOnStart) then
         oxedGameView.Instance.Select();
   end;
end;

procedure afterProjectInitialize();
begin
   projectKey := oxTKeyGlobal(oxLibReferences.FindInstance('oxTKeyGlobal'));
   if(projectKey = nil) then
      log.e('Failed to get project global keys reference');

   projectPointer := oxTPointerGlobal(oxLibReferences.FindInstance('oxTPointerGlobal'));
   if(projectPointer = nil) then
      log.e('Failed to get project global pointer reference');
end;

procedure projectStop();
begin
   projectKey := nil;
   projectPointer := nil;
end;

INITIALIZATION
   oxed.Init.Add('scene.game', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedProjectRunner.OnBeforeStart.Add(@beforeProjectStart);
   oxedProjectRunner.OnStart.Add(@afterProjectInitialize);
   oxedProjectRunner.OnStop.Add(@projectStop);

END.

