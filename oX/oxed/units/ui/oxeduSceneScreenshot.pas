{
   oxeduSceneScreenshot, takes a screenshot of the currently active editor window
   Copyright (C) 2018. Dejan Boras

   Started On:    26.11.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneScreenshot;

INTERFACE

   USES
      uLog, appuKeys,
      {ox}
      oxuWindowTypes, oxuScreenshot, oxuGlobalKeys, oxeduSceneWindow,
      {oxed}
      uOXED;

TYPE
   oxedTSceneScreenshot = record
      CaptureKey: appTKey;
   end;

VAR
   oxedSceneScreenshot: oxedTSceneScreenshot;

IMPLEMENTATION

procedure gkHandler({%H-}wnd: oxTWindow);
begin
   if(oxedSceneWindows.LastSelectedWindow <> nil) then begin
      log.v('Taking screenshot from: ' + oxedSceneWindows.LastSelectedWindow.Title);
   end;
end;

CONST
   {global key to capture screenshots}
   gkHandlerKey: oxTGlobalKeyHandler = (
      Key: (
         Code: kcF12;
         State: kmCONTROL;
      );
      Pressed: nil;
      Released: @gkHandler;
      Name: 'ox.screenshot'
   );

procedure initialize();
begin

end;

INITIALIZATION
   oxedSceneScreenshot.CaptureKey := gkHandlerKey.Key;

   oxed.Init.iAdd('screenshot', @initialize);

END.
