{
   oxeduSceneWindow, oxed scene window
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneWindow;

INTERFACE

   USES
      uStd, vmVector,
      {app}
      appuKeys, appuMouse, appuActionEvents,
      {ox}
      oxuScene, oxuCamera, oxuCameraInput,
      oxuTimer, oxuEntity,
      {find a camera component}
      oxuCameraComponent,
      {ui}
      uiuTypes, uiuWindowTypes, uiuWindow, uiuWidget, uiWidgets,
      wdguLabel, wdguSceneRender,
      {oxed}
      uOXED, oxeduSettings, oxeduWindow, oxeduActions, oxeduProjectRunner,
      oxeduEntities;

TYPE

   { wdgTOXEDSceneWindowRender }

   wdgTOXEDSceneWindowRender = class(wdgTSceneRender)
      procedure OnSceneRenderEnd(); override;
      procedure DeInitialize(); override;
   end;

   { wdgTOXEDSceneWindowStateLabel }

   wdgTOXEDSceneWindowStateLabel = class(wdgTLabel)
      procedure DeInitialize(); override;
   end;

   { oxedTSceneWindow }

   oxedTSceneWindow = class(oxedTWindow)
      {does the window control the camera}
      ControlCamera,
      {is the camera in a rotate mode currently}
      CameraRotateMode,
      {should the state widget ever be enabled (e.g. not needed in edit windows)}
      StateWidgetEnabled: boolean;

      wdg: record
         State: wdgTLabel;
         SceneRender: wdgTSceneRender;
      end;

      constructor Create(); override;

      procedure Initialize(); override;
      procedure DeInitialize; override;

      function Key(var k: appTKeyEvent): boolean; override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      procedure Update(); override;

      procedure SceneRenderEnd(); virtual;
      procedure ResetCamera();
      procedure SceneChange(); virtual;

      procedure UpdateStateWidget();
      procedure PositionStateWidget();
      procedure UpdateSceneRenderWidget();

      procedure OnActivate(); override;

      protected
      procedure SizeChanged(); override;
   end;

   oxedTSimpleSceneWindowsList = specialize TSimpleList<oxedTSceneWindow>;

   oxedTSceneWindowsGlobal = record
      LastSelectedWindow: oxedTSceneWindow;
      List: oxedTSimpleSceneWindowsList;
   end;

VAR
   oxedSceneWindows: oxedTSceneWindowsGlobal;

   {control the camera via a cursor}
   CursorControl: oxTCameraCursorControl;

IMPLEMENTATION

{ wdgTOXEDSceneWindowRender }

procedure wdgTOXEDSceneWindowRender.OnSceneRenderEnd();
begin
   {call inherited scene render end}
   oxedTSceneWindow(wnd).SceneRenderEnd();
end;

procedure wdgTOXEDSceneWindowRender.DeInitialize();
begin
   inherited DeInitialize();

   oxedTSceneWindow(wnd).wdg.SceneRender := nil;
end;

{ wdgTOXEDSceneWindowStateLabel }

procedure wdgTOXEDSceneWindowStateLabel.DeInitialize();
begin
   inherited DeInitialize();

   oxedTSceneWindow(wnd).wdg.State := nil;
end;

{ oxedTSceneWindow }

constructor oxedTSceneWindow.Create();
begin
   inherited;

   ControlCamera := true;
   StateWidgetEnabled := true;
end;

procedure oxedTSceneWindow.Initialize();
begin
   inherited;

   Background.Typ := uiwBACKGROUND_NONE;
   oxedSceneWindows.List.Add(Self);

   uiWidget.Create.Instance := wdgTOXEDSceneWindowRender;
   wdg.SceneRender := wdgSceneRender.Add();
   wdg.SceneRender.Scene := oxScene;
   {we want pointer and key events to propagate to the game}
   Exclude(wdg.SceneRender.Properties, wdgpSELECTABLE);

   ResetCamera();
   UpdateSceneRenderWidget();
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

         if(oxedSettings.PointerCenterEnable) then
            SetPointerCentered();

         CursorControl.CursorAngleSpeed := oxedSettings.CameraAngleSpeed;
         CursorControl.Start();
      end else if (e.IsReleased()) then begin
         CameraRotateMode := false;
         UnlockPointer();
      end;
   end;

   if(CameraRotateMode) then
      CursorControl.Control(uiTWindow(self), wdg.SceneRender.Camera, oxedSettings.PointerCenterEnable);
end;

procedure oxedTSceneWindow.Update();
var
   distance: single = 1;
   interpolated: single = 0;
   camera: oxPCamera;

begin
   if(ControlCamera) and (IsSelected()) then begin
      if(appk.Control() or appk.Alt()) then
         exit;

      if(appk.Shift()) then
         distance := 5;

      camera := @wdg.SceneRender.Camera;
      distance := distance * oxedSettings.CameraSpeed * oxBaseTime.Flow;

      interpolated := appk.Interpolated(kcW, kcUP);
      if(interpolated <> 0) then {forward}
         camera^.MoveForward(distance * interpolated);

      interpolated := appk.Interpolated(kcS, kcDOWN);
      if(interpolated <> 0) then {back}
         camera^.MoveForward(-distance * interpolated);

      interpolated := appk.Interpolated(kcA, kcLEFT);
      if(interpolated <> 0) then {left}
         camera^.Strafe(-distance * interpolated);

      interpolated := appk.Interpolated(kcD, kcRIGHT);
      if(interpolated <> 0) then {right}
         camera^.Strafe(distance * interpolated);

      interpolated := appk.Interpolated(kcPGUP);
      if(interpolated <> 0) then {up}
         camera^.MoveVertical(distance * interpolated);

      interpolated := appk.Interpolated(kcPGDN);
      if(interpolated <> 0) then {down}
         camera^.MoveVertical(-distance * interpolated);
   end;
end;

procedure oxedTSceneWindow.SceneRenderEnd();
begin

end;

procedure oxedTSceneWindow.ResetCamera();
begin
   wdg.SceneRender.Camera.Reset();
   wdg.SceneRender.Camera.vPos.Assign(0, 0, 5);
end;

procedure oxedTSceneWindow.SceneChange();
begin
   if(wdg.SceneRender.SceneRenderer <> nil) then
      UpdateStateWidget();
end;

procedure oxedTSceneWindow.UpdateStateWidget();
var
   cam: oxTCameraComponent;
   state: StdString;

begin
   state := '';

   if(not StateWidgetEnabled) then
      exit;

   if(wdg.SceneRender.Scene <> nil) then begin
      cam := oxTCameraComponent(wdg.SceneRender.Scene.GetComponentInChildren('oxTCameraComponent'));

      if(cam = nil) then
         state := 'No camera in scene';
   end else
      state := 'No scene set for window';

   if(state <> '') then begin
      if(wdg.State = nil) then begin
         uiWidget.SetTarget(Self);
         uiWidget.Create.Instance := wdgTOXEDSceneWindowStateLabel;
         wdg.State := wdgLabel.Add('');
      end;

      wdg.State.SetCaption(state);
      wdg.State.SetVisible();

      PositionStateWidget();
   end else begin
      if(wdg.State <> nil) then
         wdg.State.Hide();
   end;
end;

procedure oxedTSceneWindow.PositionStateWidget();
begin
   if(wdg.State <> nil) then begin
      wdg.State.AutoSize();
      wdg.State.CenterVertically();
      wdg.State.CenterHorizontally();
   end;
end;

procedure oxedTSceneWindow.UpdateSceneRenderWidget();
begin
   wdg.SceneRender.Move(0, Dimensions.h - 1);
   wdg.SceneRender.Resize(Dimensions);
end;

procedure oxedTSceneWindow.OnActivate();
begin
   inherited OnActivate;

   oxedSceneWindows.LastSelectedWindow := Self;
end;

procedure oxedTSceneWindow.SizeChanged();
begin
   inherited SizeChanged;

   PositionStateWidget();
   UpdateSceneRenderWidget();
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
      oxedSceneWindows.List[i].wdg.SceneRender.Scene := oxScene;
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

   oxedSceneWindows.List.InitializeValues(oxedSceneWindows.List);

   oxedProjectRunner.OnStart.Add(@onStart);
   oxedProjectRunner.OnStop.Add(@onStop);

   oxedEntities.OnAdd.Add(@entityAdd);
   oxedEntities.OnRemove.Add(@entityRemove);

END.
