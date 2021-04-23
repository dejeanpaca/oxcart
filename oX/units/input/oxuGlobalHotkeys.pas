{
   oxuGlobalHotkeys, command console front-end
   Copyright (c) 2020. Dejan Boras
}

UNIT oxuGlobalHotkeys;

INTERFACE

   USES
      uStd, appuKeys,
      {ox}
      oxuWindowTypes, oxuGlobalKeys, oxuWindowHelper, oxuWindows;

VAR
   oxGlobalHotkeys: record
      AllFullscreen: boolean;
   end;

IMPLEMENTATION

procedure toggleFullscreen(wnd: oxTWindow; goFull: boolean);
begin
   if(goFull) then
      wnd.EnterFullscreen()
   else
      wnd.LeaveFullscreen();
end;

procedure fullscreenHandler(wnd: oxTWindow);
var
   i: loopint;
   inFullscreen: boolean;

begin
   if(oxGlobalHotkeys.AllFullscreen) then begin
      {base toggle on the first window}
      inFullscreen := oxWindows.w[0].Fullscreen.Enabled;

      for i := 0 to oxWindows.n - 1 do begin
         toggleFullscreen(oxWindows.w[0], not inFullscreen);
      end;
   end else
      toggleFullscreen(wnd, not wnd.Fullscreen.Enabled);
end;

CONST
   gkFullscreenHandler: oxTGlobalKeyHandler = (
      Key: (
         Code: kcF11;
         State: 0;
      );
      Pressed: nil;
      Released: @fullscreenHandler;

      Name: 'fullscreen_toggle'
   );

INITIALIZATION
   oxGlobalHotkeys.AllFullscreen := true;
   oxGlobalKeys.Hook(gkFullscreenHandler);

END.
