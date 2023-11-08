{
   oxuCameraInput, camera input control
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuCameraInput;

INTERFACE

   USES
      uStd, vmVector,
      {app}
      appuMouse,
      {ox}
      oxuCamera,
      {ui}
      uiuWindowTypes, uiuWindow;

TYPE
   { oxTCameraCursorControl }

   oxTCameraCursorControl = record
      {last pointer position}
      LastPointerPosition: TVector2f;
      {cursor angle spedd}
      CursorAngleSpeed: Single;

      {start cursor control}
      procedure Start();
      {cursor control}
      procedure GetPointerMovement(wnd: uiTWindow; out mx, my: single; center: boolean = true);
      {cursor control}
      procedure Control(wnd: uiTWindow; var camera: oxTCamera; center: boolean = true);
      {cursor control}
      procedure OrbitControl(wnd: uiTWindow; var camera: oxTCamera; center: boolean = true);
   end;


IMPLEMENTATION

procedure oxTCameraCursorControl.Start();
begin
   appm.GetPosition(nil, LastPointerPosition[0], LastPointerPosition[1]);
end;

procedure oxTCameraCursorControl.GetPointerMovement(wnd: uiTWindow; out mx, my: single; center: boolean);
var
   ox,
   oy,
   nx,
   ny: single;

begin
   mx := 0;
   my := 0;

   ox := 0;
   oy := 0;

   if(center) then
      appm.GetPosition(nil, ox, oy);

   if(ox <> LastPointerPosition[0]) or (oy <> LastPointerPosition[1]) then begin
      if(center) then
         wnd.SetPointerCentered()
      else begin
         ox := LastPointerPosition[0];
         oy := LastPointerPosition[1];
      end;

      appm.GetPosition(nil, nx, ny);
      if(center) then begin
         mx := ox - nx;
         my := ny - oy;
      end else begin
         mx := nx - ox;
         my := oy - ny;
      end;

      LastPointerPosition[0] := nx;
      LastPointerPosition[1] := ny;
   end;
end;

procedure oxTCameraCursorControl.Control(wnd: uiTWindow; var camera: oxTCamera; center: boolean);
var
   mx,
   my: single;

begin
   GetPointerMovement(wnd, mx, my, center);

   if(mx <> 0) or (my <> 0) then begin
      Camera.IncPitchYaw(my / CursorAngleSpeed, mx / CursorAngleSpeed);
   end;
end;

procedure oxTCameraCursorControl.OrbitControl(wnd: uiTWindow; var camera: oxTCamera; center: boolean);
var
   mx,
   my: single;

begin
   GetPointerMovement(wnd, mx, my, center);

   if(mx <> 0) or (my <> 0) then begin
      vmRotateAroundPoint(mx / CursorAngleSpeed / 3.14, 0, 1, 0, vmvZero3f, Camera.vPos);
      vmRotateAroundPoint(my / CursorAngleSpeed / 3.14, 1, 0, 0, vmvZero3f, Camera.vPos);

      vmRotateAroundPoint(mx / CursorAngleSpeed / 3.14, 0, 1, 0, vmvZero3f, Camera.vUp);
      vmRotateAroundPoint(my / CursorAngleSpeed / 3.14, 1, 0, 0, vmvZero3f, Camera.vUp);
      Camera.vUp.Normalize();

      Camera.vView := (vmvZero3f - Camera.vPos);
      Camera.vView.Normalize();

      Camera.vRight := Camera.vView.Cross(Camera.vUp);
   end;
end;

END.
