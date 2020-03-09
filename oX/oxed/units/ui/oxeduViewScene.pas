{
   oxeduViewScene, scene view controls
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduViewScene;

INTERFACE

   USES
      vmVector, appuActionEvents,
      {ox}
      oxuCamera,
      {oxed}
      oxeduActions, oxeduSceneWindow;

IMPLEMENTATION

procedure view(pview: TVector3f);
var
   wnd: oxedTSceneWindow;
   distance: single;

begin
   wnd := oxedSceneWindows.LastSelectedWindow;

   if(wnd <> nil) and (wnd.ControlCamera) then begin
      distance := wnd.wdg.SceneRender.Camera.vPos.Distance(vmvZero3f);

      wnd.wdg.SceneRender.Camera.PitchYaw(pview[0], pview[1]);

      wnd.wdg.SceneRender.Camera.vPos := wnd.wdg.SceneRender.Camera.vView * -distance;
   end;
end;

procedure viewBack();
begin
   view(vmCreate(0, 0, 0.0));
end;

procedure viewFront();
begin
   view(vmCreate(180, 180, 0.0));
end;
procedure viewLeft();
begin
   view(vmCreate(0, 90, 0.0));
end;
procedure viewRight();
begin
   view(vmCreate(0, -90, 0.0));
end;

procedure viewUp();
var
   wnd: oxedTSceneWindow;

begin
   wnd := oxedSceneWindows.LastSelectedWindow;

   if(wnd <> nil) and (wnd.ControlCamera) then begin
      view(vmCreate(-90, 0, 0.0));
   end;
end;

procedure viewDown();
begin
   view(vmCreate(90, 0, 0.0));
end;

INITIALIZATION
   oxedActions.VIEW_BACK := appActionEvents.SetCallback(@viewBack);
   oxedActions.VIEW_FRONT := appActionEvents.SetCallback(@viewFront);
   oxedActions.VIEW_LEFT := appActionEvents.SetCallback(@viewLeft);
   oxedActions.VIEW_RIGHT := appActionEvents.SetCallback(@viewRight);
   oxedActions.VIEW_UP := appActionEvents.SetCallback(@viewUp);
   oxedActions.VIEW_DOWN := appActionEvents.SetCallback(@viewDown);

END.
