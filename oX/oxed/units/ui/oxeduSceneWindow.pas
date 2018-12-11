{
   oxeduSceneWindow, oxed scene window
   Copyright (C) 2016. Dejan Boras

   Started On:    26.12.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneWindow;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {app}
      appuKeys, appuMouse, appuActionEvents,
      {ox}
      oxuTypes, oxuScene, oxuCamera, oxuProjection, oxuWindowTypes,
      oxuRender, oxuRenderer, oxuSceneRender, oxuTimer, oxuEntity,
      {find a camera component}
      oxuCameraComponent,
      {ui}
      uiuTypes, uiuWindowTypes, uiuWindow, uiuDraw, uiWidgets,
      wdguLabel,
      {oxed}
      uOXED, oxeduSettings, oxeduWindow, oxeduMenubar, oxeduActions, oxeduProjectRunner, oxeduProject, oxeduSceneClone,
      oxeduEntities;

TYPE

   { wdgTOXEDSceneWindowStateLabel }

   wdgTOXEDSceneWindowStateLabel = class(wdgTLabel)
      procedure DeInitialize(); override;
   end;

   { oxedTSceneWindow }

   oxedTSceneWindow = class(oxedTWindow)
      {the scene we view in this window}
      Scene: oxTScene;
      {window projection}
      Projection: oxTProjection;
      {window camera}
      Camera: oxTCamera;

      {shouls we render all cameras}
      RenderAllCameras: boolean;
      {does the window control the camera}
      ControlCamera,
      {is the camera in a rotate mode currently}
      CameraRotateMode,
      {should the state widget ever be enabled (e.g. not needed in edit windows)}
      StateWidgetEnabled: boolean;

      {a renderer for the scene}
      SceneRenderer: oxTSceneRenderer;

      wdgState: wdgTLabel;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure Initialize(); override;
      procedure DeInitialize; override;

      procedure Render; override;
      procedure CleanupRender();
      function Key(var k: appTKeyEvent): boolean; override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      procedure SetupProjection();
      procedure Update(); override;

      procedure SceneRenderEnd(); virtual;
      procedure ResetCamera();
      procedure SceneChange(); virtual;

      procedure UpdateStateWidget();
      procedure PositionStateWidget();

      procedure OnActivate; override;

      protected
      procedure SizeChanged(); override;
      procedure RPositionChanged; override;
   end;

   oxedTPreallocatedSceneWindowsList = specialize TPreallocatedArrayList<oxedTSceneWindow>;

   oxedTSceneWindowsGlobal = record
      LastSelectedWindow: oxedTSceneWindow;
      List: oxedTPreallocatedSceneWindowsList;
   end;

VAR
   oxedSceneWindows: oxedTSceneWindowsGlobal;

   {control the camera via a cursor}
   CursorControl: oxTCameraCursorControl;

IMPLEMENTATION

{ wdgTOXEDSceneWindowStateLabel }

procedure wdgTOXEDSceneWindowStateLabel.DeInitialize();
begin
   inherited DeInitialize();

   oxedTSceneWindow(wnd).wdgState := nil;
end;

{ oxedTSceneWindow }

constructor oxedTSceneWindow.Create();
begin
   inherited;

   Projection := oxTProjection.Create();

   {use the global scene by default}
   Scene := oxScene;

   {create our own camera}
   Camera := oxTCamera.Create();
   Camera.Style := oxCAMERA_STYLE_FPS;

   ResetCamera();
   ControlCamera := true;
   StateWidgetEnabled := true;
end;

destructor oxedTSceneWindow.Destroy();
begin
   inherited;

   FreeObject(Camera);
   FreeObject(Projection);

   if(SceneRenderer <> oxSceneRender.Default) then
      FreeObject(SceneRenderer);
end;

procedure oxedTSceneWindow.Initialize();
begin
   inherited Initialize;

   Background.Typ := uiwBACKGROUND_NONE;
   oxedSceneWindows.List.Add(Self);
end;

procedure oxedTSceneWindow.DeInitialize;
var
   index: loopint;

begin
   inherited DeInitialize;

   index := oxedSceneWindows.List.Find(Self);
   if(index > -1) then
      oxedSceneWindows.List.Remove(index);
end;

procedure oxedTSceneWindow.Render;
var
   params: oxTSceneRenderParameters;

begin
   inherited;

   if(oxedProject = nil) then
      exit;

   if(not RenderAllCameras) then begin
      oxTSceneRenderParameters.Init(params, Projection, Camera);
      SceneRenderer.RenderCamera(params);
   end else
      SceneRenderer.Render(Projection);

   SceneRenderEnd();

   CleanupRender();
end;

procedure oxedTSceneWindow.CleanupRender();
begin
   oxTProjection(oxTWindow(oxwParent).Projection).Apply(false);
   uiWindow.RenderPrepare(oxTWIndow(oxwParent));

   uiDraw.Start();
end;

function oxedTSceneWindow.Key(var k: appTKeyEvent): boolean;
begin
   Result := false;


   if(ControlCamera) and (not k.Key.HasModifiers()) then begin
      Result := true;

      if(k.Key.Equal(kcESC)) then begin
      end else if(k.Key.Equal(kcF)) then begin
         {TODO: Focus camera on selected object}
      end else if(k.Key.Equal(kcR)) then begin
         {TODO: Rotate mode}
      end else if(k.Key.Equal(kcT)) then begin
         {TODO: Translate mode}
      end else if(k.Key.Equal(kcV)) then begin
         {TODO: Scale mode}
      end else
         Result := false;
   end;
end;

procedure oxedTSceneWindow.Point(var e: appTMouseEvent; x, y: longint);
begin
   if(e.Button.IsSet(appmcRIGHT)) then begin
      if(e.IsPressed()) then begin
         CameraRotateMode := true;
         LockPointer();
         SetPointerCentered();

         CursorControl.CursorAngleSpeed := oxedSettings.CameraAngleSpeed;
         CursorControl.Start();
      end else if (e.IsReleased()) then begin
         CameraRotateMode := false;
         UnlockPointer();
      end;
   end;

   if(CameraRotateMode) then
      CursorControl.Control(uiTWindow(self), Camera, oxedSettings.PointerCenterEnable);
end;

procedure oxedTSceneWindow.SetupProjection();
begin
   Projection.SetViewport(RPosition, Dimensions);
end;

procedure oxedTSceneWindow.Update();
var
   distance: single = 1;

begin
   if(ControlCamera) and (IsSelected()) then begin
      if(appk.Control() or appk.Alt()) then
         exit;

      if(appk.Shift()) then
         distance := 5;

      distance := distance * oxedSettings.CameraSpeed * oxMainTimeFlow;

      if(appk.Pressed[kcW] or appk.Pressed[kcUP]) then {forward}
         Camera.MoveForward(distance);

      if(appk.Pressed[kcS] or appk.Pressed[kcDOWN]) then {back}
         Camera.MoveForward(-distance);

      if(appk.Pressed[kcA] or appk.Pressed[kcLEFT]) then {left}
         Camera.Strafe(-distance);

      if(appk.Pressed[kcD] or appk.Pressed[kcRIGHT]) then {right}
         Camera.Strafe(distance);

      if(appk.Pressed[kcPGUP]) then {up}
         Camera.MoveVertical(distance);

      if(appk.Pressed[kcPGDN]) then {down}
         Camera.MoveVertical(-distance);
   end;
end;

procedure oxedTSceneWindow.SceneRenderEnd();
begin

end;

procedure oxedTSceneWindow.ResetCamera();
begin
   Camera.vPos.Assign(0, 0, 5);
   Camera.vView.Assign(0, 0, -1);
   Camera.vView.Normalize();
   Camera.SetupAngles();
end;

procedure oxedTSceneWindow.SceneChange();
begin
   if(SceneRenderer <> nil) then begin
      SceneRenderer.Scene := Scene;

      UpdateStateWidget();
   end;
end;

procedure oxedTSceneWindow.UpdateStateWidget();
var
   cam: oxTCameraComponent;
   state: string;

begin
   state := '';

   if(not StateWidgetEnabled) then
      exit;

   if(Scene <> nil) then begin
      cam := oxTCameraComponent(Scene.GetComponentInChildren('oxTCameraComponent'));

      if(cam = nil) then
         state := 'No camera in scene';
   end else
      state := 'No scene set for window';

   if(state <> '') then begin
      if(wdgState = nil) then begin
         uiWidget.SetTarget(Self);
         uiWidget.Create.Instance := wdgTOXEDSceneWindowStateLabel;
         wdgState := wdgLabel.Add('');
      end;

      wdgState.SetCaption(state);
      wdgState.SetVisible();

      PositionStateWidget();
   end else begin
      if(wdgState <> nil) then
         wdgState.Hide();
   end;
end;

procedure oxedTSceneWindow.PositionStateWidget();
begin
   if(wdgState <> nil) then begin
      wdgState.AutoSize();
      wdgState.CenterVertically();
      wdgState.CenterHorizontally();
   end;
end;

procedure oxedTSceneWindow.OnActivate;
begin
   inherited OnActivate;

   oxedSceneWindows.LastSelectedWindow := Self;
end;

procedure oxedTSceneWindow.SizeChanged();
begin
   inherited SizeChanged;

   SetupProjection();
   PositionStateWidget();
end;

procedure oxedTSceneWindow.RPositionChanged;
begin
   inherited RPositionChanged;

   SetupProjection();
end;

procedure resetCamera();
begin
   if(oxedSceneWindows.LastSelectedWindow <> nil) then
      oxedSceneWindows.LastSelectedWindow.ResetCamera();
end;

procedure updateScene();
var
   i: loopint;

begin
   for i := 0 to oxedSceneWindows.List.n - 1 do begin
      oxedSceneWindows.List[i].Scene := oxScene;
      oxedSceneWindows.List[i].SceneChange();
   end;
end;

procedure updateCamera();
var
   i: loopint;

begin
   for i := 0 to oxedSceneWindows.List.n - 1 do begin
      oxedSceneWindows.List[i].UpdateStateWidget();
   end;
end;

procedure onStart();
begin
   updateScene();
end;

procedure onStop();
begin
   updateScene();
end;

procedure entityAdd(entity: oxTEntity);
begin
   if(entity.GetComponent('oxTCameraComponent') <> nil) then
      updateCamera();
end;

procedure entityRemove(entity: oxTEntity);
begin
   if(entity.GetComponent('oxTCameraComponent') <> nil) then
      updateCamera();
end;

INITIALIZATION
   oxedActions.RESET_CAMERA := appActionEvents.SetCallback(@resetCamera);

   oxedSceneWindows.List.Initialize(oxedSceneWindows.List);

   oxedProjectRunner.OnStart.Add(@onStart);
   oxedProjectRunner.OnStop.Add(@onStop);

   oxedEntities.OnAdd.Add(@entityAdd);
   oxedEntities.OnRemove.Add(@entityRemove);

END.

