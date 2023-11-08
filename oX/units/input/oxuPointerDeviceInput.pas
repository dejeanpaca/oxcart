{
   oxuPointerDeviceInput, pointer device input
   Copyright (c) 2012. Dejan Boras

   Started On:    26.08.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuPointerDeviceInput;

INTERFACE

   USES
      {oX}
      oxuTypes, oxuWindows, oxuCamera, oxuPointer;

CONST
   oxcPointerDeviceDivider: single = 200.0;

TYPE
   oxPPointerDeviceSettings = ^oxTPointerDeviceSettings;
   oxTPointerDeviceSettings = record
      sensitivityX,
      sensitivityY: single;
      wnd: oxTWindow;
   end;

   oxTPointerDeviceInfo = record
      settings: oxPPointerDeviceSettings;

      x, y: single;
   end;

CONST
   oxDefaultPointerDeviceSettings: oxTPointerDeviceSettings = (
      sensitivityX: 1.0; sensitivityY: 1.0; wnd: Nil
   );
   oxDefaultPointerDeviceInfo: oxTPointerDeviceInfo = (
      settings: @oxDefaultPointerDeviceSettings; x: 0; y: 0
   );

function oxGetPointerDeviceWnd(var data: oxTPointerDeviceInfo): oxTWindow;
procedure oxPointerDeviceGet(var data: oxTPointerDeviceInfo);
procedure oxPointerDeviceCam(var data: oxTPointerDeviceInfo; var cam: oxTCamera);
procedure oxPointerDeviceControl(var data: oxTPointerDeviceInfo);

IMPLEMENTATION

function oxGetPointerDeviceWnd(var data: oxTPointerDeviceInfo): oxTWindow;
var
   pwnd: oxTWindow = nil;

begin
   if(data.settings <> nil) then
      pwnd := data.settings^.wnd;

   if(pwnd = nil) then
      if(oxWindows.n > 0) then
         pwnd := oxWindows.w[0];

   result := pwnd;
end;

procedure oxPointerDeviceGet(var data: oxTPointerDeviceInfo);
var
   centerx,
   centery: longint;

   mouseX,
   mouseY,
   mx,
   my: single;

   pwnd: oxTWindow;

begin
   pwnd := oxGetPointerDeviceWnd(data);

   if(pwnd <> nil) then begin
      centerx  := pwnd^.w.dim.w div 2;
      centery  := pwnd^.w.dim.h div 2;

      oxGetPointerPosition(pwnd^, mx, my);

      mouseX   := centerx - mx;
      mouseY   := centery - my;

      data.x   := (mouseY / oxcPointerDeviceDivider);
      data.y   := (mouseX / oxcPointerDeviceDivider);
   end;
end;

procedure oxPointerDeviceCam(var data: oxTPointerDeviceInfo; var cam: oxTCamera);
begin
   if(data.x <> 0) or (data.y <> 0) then
      oxcamView(cam, data.x, data.y);
end;

procedure oxPointerDeviceControl(var data: oxTPointerDeviceInfo);
var
   centerx, centery: longint;
   pwnd: oxTWindow;

begin
   pwnd := oxGetPointerDeviceWnd(data);

   if(pwnd <> nil) then begin
      {center the pointer}
      centerx  := pwnd^.w.dim.w div 2;
      centery  := pwnd^.w.dim.h div 2;

      if(data.x <> 0) or (data.y <> 0) then
         oxSetPointerPosition(pwnd^, round(centerx), round(centery));

      data.x   := 0;
      data.y   := 0;
   end;
end;

END.
