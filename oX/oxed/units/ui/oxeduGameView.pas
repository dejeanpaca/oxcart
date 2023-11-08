{
   oxeduGameView, oxed scene view window
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduGameView;

INTERFACE

   USES
      uStd, uLog,
      {app}
      appuKeys, appuMouse,
      {ox}
      oxuWindows, oxuWindow, oxuWindowHelper,
      oxuKeyboardControl, oxuPointerControl, oxuGlobalKeys,
      oxuSceneRender,
      {ui}
      uiuTypes, uiuWindow, oxuUI,
      {oxed}
      uOXED, oxeduSettings, oxeduSceneWindow, oxeduMenubar, oxeduWindow, oxeduProjectRunner, oxeduLib;

TYPE
   { oxedTGameViewWindow }

   oxedTGameViewWindow = class(oxedTSceneWindow)
      procedure Render(); override;

      function Key(var k: appTKeyEvent): boolean; override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      procedure Hover(x, y: longint; {%H-}what: uiTHoverEvent); override;

      procedure Initialize(); override;

      procedure OnActivate(); override;
      procedure OnDeactivate(); override;

      protected
         procedure RPositionChanged(); override;
         procedure PositionChanged(); override;
         procedure SizeChanged(); override;
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

procedure oxedTGameViewWindow.Render();
begin
   {we don't render anything, as the game will render itself}
   if(oxedTProjectRunner.CanRender()) then begin
      wdg.SceneRender.ProjectionStart();

      oxedLib.oxWindowRender^.All();

      wdg.SceneRender.CleanupRender();
   end else
      wdg.SceneRender.PerformRender();
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
         Result := projectKey.Handle(nil, newK);
   end;
end;

procedure GetMouseEvent(var m: appTMouseEvent; x, y: longint);
begin
   m.x := x;
   m.y := y;

   {TODO: Find the library window attached to this wnd and set it to the event}
end;

procedure oxedTGameViewWindow.Point(var e: appTMouseEvent; x, y: longint);
var
   newM: appTMouseEvent;

begin
   if(projectPointer <> nil) then begin
      newM := e; {use copy so the original is not modified}
      GetMouseEvent(newM, x, y);
      projectPointer.Handle(nil, newM);
   end;
end;

procedure oxedTGameViewWindow.Hover(x, y: longint; what: uiTHoverEvent);
var
   newM: appTMouseEvent;

begin
   if(projectPointer <> nil) then begin
      appm.Init(newM);
      newM.Action := appmcMOVED;
      GetMouseEvent(newM, x, y);
      projectPointer.Handle(nil, newM);
   end;
end;

procedure oxedTGameViewWindow.Initialize();
begin
   inherited;

   oxWindows.ExternalWindows.Dispose();
   oxWindows.ExternalWindows.Add(Self);

   {don't use scene widget or apply its viewport (project applies its own)}
   wdg.SceneRender.Enable(false);
end;

procedure oxedTGameViewWindow.OnActivate();
begin
   inherited;

   if(oxedLib.Settings <> nil) then
      oxedLib.Settings^.Focused := true;

   if(oxedLib.oxWindows <> nil) then
      oxedLib.oxWindows^.w[0].RegainedFocus();
end;

procedure oxedTGameViewWindow.OnDeactivate();
begin
   inherited;

   if(oxedLib.Settings <> nil) then
      oxedLib.Settings^.Focused := false;

   if(oxedLib.oxWindows <> nil) then
      oxedLib.oxWindows^.w[0].LostFocus();
end;

procedure oxedTGameViewWindow.RPositionChanged();
begin
   inherited;

   if(oxedLib.oxWindows <> nil) then
      oxedLib.oxWindows^.w[0].SetupViewport();
end;

procedure oxedTGameViewWindow.PositionChanged();
begin
   inherited;

   if(oxedLib.oxWindows <> nil) then
      oxedLib.oxWindows^.w[0].SetupViewport();
end;

procedure oxedTGameViewWindow.SizeChanged();
begin
   inherited;

   if(oxedLib.oxWindows <> nil) then begin
      oxedLib.oxWindows^.w[0].SetDimensions(Dimensions.w, Dimensions.h, false);
      oxedLib.oxWindows^.w[0].SetupViewport();
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

procedure onStart();
begin
   projectKey := oxTKeyGlobal(oxLibReferences^.FindInstance('oxTKeyGlobal'));
   projectPointer := oxTPointerGlobal(oxLibReferences^.FindInstance('oxTPointerGlobal'));

   {set ox lib to focused if any of our windows is selected}
   if(oxedGameView.Instance <> nil) then
      oxedLib.Settings^.Focused := oxedGameView.Instance.IsSelected();
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
   oxedProjectRunner.OnStart.Add(@onStart);
   oxedProjectRunner.OnStop.Add(@projectStop);

END.
