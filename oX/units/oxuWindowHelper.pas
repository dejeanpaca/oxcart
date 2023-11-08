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

      procedure Maximize();
      procedure Minimize();
      procedure Restore();

      {set a frame for the window}
      procedure SetFrame(fs: uiTWindowFrameStyle);

      procedure Fullscreen();
      procedure WindowedFullscreen();
      procedure LeaveFullscreen();
      procedure ToggleFullscreen();
      procedure ToggleWindowedFullscreen();

      procedure LostFocus();
      procedure RegainedFocus();
   end;

IMPLEMENTATION

{ oxTWindowHelper }

procedure oxTWindowHelper.Fullscreen();
begin
   if(not oxProperties.Fullscreen) then begin
      FullscreenPosition := Position;
      FullscreenDimensions := Dimensions;

      if(oxPlatform.Fullscreen(self)) then begin
         SetPosition(0, 0);

         if(oxProperties.WindowedFullscreen) then
            Maximize();

         oxPlatform.ShowWindow(self);
         oxProperties.Fullscreen := true;

         log.i('Entered fullscreen: ' + Title);
      end else
         log.e('Failed to enter fullscreen: ' + Title);
   end;
end;

procedure oxTWindowHelper.WindowedFullscreen();
begin
   if(oxProperties.Fullscreen) then
      exit;

   oxProperties.WindowedFullscreen := true;
   Fullscreen();
end;

procedure oxTWindowHelper.LeaveFullscreen();
begin
   if(oxProperties.Fullscreen) then begin
      if(oxPlatform.LeaveFullscreen(self)) then begin
         oxPlatform.ShowWindow(self);

         SetPosition(FullscreenPosition.x, FullscreenPosition.y);
         SetDimensions(FullscreenDimensions.w, FullscreenDimensions.h);

         oxProperties.Fullscreen := false;
         log.i('Left fullscreen: ' + Title);
      end else
         log.e('Failed to leave fullscreen: ' + Title);
   end;
end;

procedure oxTWindowHelper.ToggleFullscreen();
begin
   if(not oxProperties.Fullscreen) then
      Fullscreen()
   else
      LeaveFullscreen();
end;

procedure oxTWindowHelper.ToggleWindowedFullscreen();
begin
   if(not oxProperties.Fullscreen) then
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

procedure oxTWindowHelper.Maximize();
begin
   if(oxProperties.Fullscreen) then
      exit;

   if(oxUIHooks <> nil) then
      oxUIHooks.Maximize(Self);
end;

procedure oxTWindowHelper.Minimize();
begin
   if(oxProperties.Fullscreen) then
      exit;

   if(oxUIHooks <> nil) then
      oxUIHooks.Minimize(Self);
end;

procedure oxTWindowHelper.Restore();
begin
   if(oxProperties.Fullscreen) then begin
      LeaveFullscreen();
      exit;
   end;

   if(oxUIHooks <> nil) then
      oxUIHooks.Restore(Self);
end;

procedure oxTWindowHelper.SetFrame(fs: uiTWindowFrameStyle);
begin
   Frame := fs;

   {TODO: set the frame here for the system}
   if(oxProperties.Created) then;
end;

END.
