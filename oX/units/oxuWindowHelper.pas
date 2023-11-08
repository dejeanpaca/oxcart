{
   oxuWindowHelper, oX window helpers
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuWindowHelper;

INTERFACE

   USES
      uStd, uLog, uAppInfo,
      {oX}
      uOX, oxuTypes, oxuViewport,
      oxuWindowTypes, oxuPlatform, oxuUIHooks,
      {ui}
      uiuWindowTypes, uiuTypes;

TYPE
   { oxTWindowHelper }

   oxTWindowHelper = class helper for oxTWindow
      {set position and dimensions of a window}
      procedure SetPosition(x, y: longint; system: boolean = true);
      procedure SetDimensions(w, h: longint; system: boolean = true);

      procedure SetupViewport();
      procedure SetViewportOffset();

      procedure Maximize(fromSystem: boolean = false);
      procedure Minimize(fromSystem: boolean = false);
      procedure Restore(fromSystem: boolean = false);

      {set a frame for the window}
      procedure SetFrame(fs: uiTWindowFrameStyle);

      procedure EnterFullscreen();
      procedure WindowedFullscreen();
      procedure LeaveFullscreen();
      procedure ToggleFullscreen();
      procedure ToggleWindowedFullscreen();

      procedure LostFocus();
      procedure RegainedFocus();
   end;

IMPLEMENTATION

{ oxTWindowHelper }

procedure oxTWindowHelper.EnterFullscreen();
var
   ok: boolean;

begin
   if(not Fullscreen.Enabled) then begin
      Fullscreen.Position := Position;
      Fullscreen.Dimensions := Dimensions;

      ok := true;

      if(not Fullscreen.Windowed) then
         ok := oxPlatform.Fullscreen(self);

      if(ok) then begin
         SetPosition(0, 0);

         if(Fullscreen.Windowed) then
            Maximize();

         oxPlatform.ShowWindow(self);
         Fullscreen.Enabled := true;

         log.i('Entered fullscreen: ' + Title);
      end else begin
         log.e('Failed to enter fullscreen: ' + Title + ' ' + Dimensions.ToString());

         {restore if failed for non windowed mode}
         if(not Fullscreen.Windowed) then begin
            Fullscreen.Enabled := true;
            LeaveFullscreen();
         end;
      end;
   end;
end;

procedure oxTWindowHelper.WindowedFullscreen();
begin
   if(Fullscreen.Enabled) then
      exit;

   Fullscreen.Windowed := true;
   EnterFullscreen();
end;

procedure oxTWindowHelper.LeaveFullscreen();
begin
   if(Fullscreen.Enabled) then begin
      if(oxPlatform.LeaveFullscreen(self)) then begin
         oxPlatform.ShowWindow(self);

         SetPosition(Fullscreen.Position.x, Fullscreen.Position.y);
         SetDimensions(Fullscreen.Dimensions.w, Fullscreen.Dimensions.h);

         Fullscreen.Enabled := false;
         log.i('Left fullscreen: ' + Title);
      end else
         log.e('Failed to leave fullscreen: ' + Title);
   end;
end;

procedure oxTWindowHelper.ToggleFullscreen();
begin
   if(not Fullscreen.Enabled) then
      EnterFullscreen()
   else
      LeaveFullscreen();
end;

procedure oxTWindowHelper.ToggleWindowedFullscreen();
begin
   if(not Fullscreen.Enabled) then
      WindowedFullscreen()
   else
      LeaveFullscreen();
end;

procedure oxTWindowHelper.LostFocus();
begin

end;

procedure oxTWindowHelper.RegainedFocus();
begin

end;

procedure oxTWindowHelper.SetPosition(x, y: longint; system: boolean);
begin
   if(Position.x = x) and (Position.y = y) then
      exit;

   Position.x := x;
   Position.y := y;

   if(not oxProperties.Context) then begin
      if(system) and (oxProperties.Created) then
         oxPlatform.Move(self, x, y);

      oxUIHooks.SetPosition(self, oxPoint(x, y));

      SetupViewport();
   end;
end;

procedure oxTWindowHelper.SetDimensions(w, h: longint; system: boolean);
begin
   if(Dimensions.w = w) and (Dimensions.h = h) then
      exit;

   Dimensions.w := w;
   Dimensions.h := h;

   if(oxProperties.Context) then
      exit;

   if(system) and (oxProperties.Created) then
      oxPlatform.Resize(self, w, h);

   oxUIHooks.SetDimensions(self, oxTDimensions.Make(w, h));
   Viewport.Changed := true;
end;

procedure oxTWindowHelper.SetupViewport();
begin
   Viewport.SetViewport(Dimensions.w, Dimensions.h);
   SetViewportOffset();
end;

procedure oxTWindowHelper.SetViewportOffset();
begin
   if(ExternalWindow <> nil) then
      Viewport.SetOffset(ExternalWindow.RPosition.x, ExternalWindow.RPosition.y - (ExternalWindow.Dimensions.h - 1))
   else
      Viewport.SetOffset(0, 0);
end;

procedure oxTWindowHelper.Maximize(fromSystem: boolean);
begin
   if(Fullscreen.Enabled) then
      exit;

   if(oxUIHooks <> nil) then
      oxUIHooks.Maximize(Self, fromSystem);
end;

procedure oxTWindowHelper.Minimize(fromSystem: boolean);
begin
   if(Fullscreen.Enabled) then
      exit;

   if(oxUIHooks <> nil) then
      oxUIHooks.Minimize(Self, fromSystem);
end;

procedure oxTWindowHelper.Restore(fromSystem: boolean);
begin
   if(Fullscreen.Enabled) then begin
      LeaveFullscreen();
      exit;
   end;

   if(oxUIHooks <> nil) then
      oxUIHooks.Restore(Self, fromSystem);
end;

procedure oxTWindowHelper.SetFrame(fs: uiTWindowFrameStyle);
begin
   Frame := fs;

   {TODO: set the frame here for the system}
   if(oxProperties.Created) then;
end;

END.
