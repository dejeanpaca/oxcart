{
   oxeduSceneScreenshot, takes a screenshot of the currently active editor window
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduSceneScreenshot;

INTERFACE

   USES
      sysutils, uLog, appuKeys, uFileUtils,
      uImage,
      appuActionEvents,
      {ox}
      oxuRunRoutines, oxuWindowTypes, oxuScreenshot, oxuGlobalKeys, oxeduSceneWindow,
      {ui}
      uiuWindowTypes, uiuWindow,
      {oxed}
      uOXED, oxeduProject, oxeduActions;

TYPE
   oxedTSceneScreenshot = record
      Path: string;
      CaptureKey: appTKey;
   end;

VAR
   oxedSceneScreenshot: oxedTSceneScreenshot;

IMPLEMENTATION

procedure gkHandler({%H-}wnd: oxTWindow);
var
   name,
   path: string;
   sceneWnd: uiTWindow;
   image: imgTImage = nil;

begin
   sceneWnd := oxedSceneWindows.LastSelectedWindow;

   if(sceneWnd = nil) or (not oxedProjectValid()) then
      exit;

   path := oxedProject.Path + 'screenshots' + DirectorySeparator;
   FileUtils.CreateDirectory(path);

   name := oxScreenshot.GetScreenshotName();
   path := path + name + '.tga';

   oxScreenshot.Make(image, oxTWindow(sceneWnd.oxwParent),
      sceneWnd.RPosition.x, sceneWnd.RPosition.y - sceneWnd.Dimensions.h + 1, sceneWnd.Dimensions.w, sceneWnd.Dimensions.h);

   if(oxScreenshot.Save(path, image) = 0) then
      log.v('Took screenshot from: ' + oxedSceneWindows.LastSelectedWindow.Title + ' into ' + path);
end;

procedure takeScreenshot();
begin
   gkHandler(nil);
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
      Name: 'oxed.scene.screenshot'
   );

procedure initialize();
begin
   gkHandlerKey.Key := oxedSceneScreenshot.CaptureKey;
   oxedActions.SCENE_SCREENSHOT := appActionEvents.SetCallback(@takeScreenshot);

   oxGlobalKeys.Hook(gkHandlerKey);
end;

INITIALIZATION
   oxedSceneScreenshot.CaptureKey := gkHandlerKey.Key;

   oxed.Init.Add('scene_screenshot', @initialize);

END.
