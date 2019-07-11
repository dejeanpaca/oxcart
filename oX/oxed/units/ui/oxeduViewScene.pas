{
   oxeduViewScene, scene view controls
   Copyright (C) 2017. Dejan Boras

   Started On:    04.11.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduViewScene;

INTERFACE

   USES
      vmVector, appuActionEvents,
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
      distance := wnd.Camera.vPos.Distance(vmvZero3f);

      wnd.Camera.vPos := vmvZero3f + (pview * -distance);

      wnd.Camera.vView := pview;
      wnd.Camera.vView.Normalize();

      wnd.Camera.SetupRotation();
      wnd.Camera.UpFromView();

      {NOTE: This hack allows for proper rendering when using an UP or DOWN camera view}
      wnd.Camera.PitchYaw();
   end;
end;

procedure viewBack();
begin
   view(vmCreate(0, 0, 1.0));
end;

procedure viewFront();
begin
   view(vmCreate(0, 0, -1.0));
end;
procedure viewLeft();
begin
   view(vmCreate(1.0, 0, 0));
end;
procedure viewRight();
begin
   view(vmCreate(-1.0, 0, 0));
end;

procedure viewUp();
begin
   view(vmCreate(0, -1.0, 0));
end;

procedure viewDown();
begin
   view(vmCreate(0, 1.0, 0));
end;

INITIALIZATION
   oxedActions.VIEW_BACK := appActionEvents.SetCallback(@viewBack);
   oxedActions.VIEW_FRONT := appActionEvents.SetCallback(@viewFront);
   oxedActions.VIEW_LEFT := appActionEvents.SetCallback(@viewLeft);
   oxedActions.VIEW_RIGHT := appActionEvents.SetCallback(@viewRight);
   oxedActions.VIEW_UP := appActionEvents.SetCallback(@viewUp);
   oxedActions.VIEW_DOWN := appActionEvents.SetCallback(@viewDown);

END.
