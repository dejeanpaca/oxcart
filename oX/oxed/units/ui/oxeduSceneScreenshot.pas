{
   oxeduSceneScreenshot, takes a screenshot of the currently active editor window
   Copyright (C) 2018. Dejan Boras

   Started On:    26.11.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneScreenshot;

INTERFACE

   USES
      sysutils, uLog, appuKeys, uFileUtils,
      uImage,
      {ox}
      oxuRunRoutines, oxuWindowTypes, oxuScreenshot, oxuGlobalKeys, oxeduSceneWindow,
      {ui}
      uiuWindowTypes, uiuWindow,
      {oxed}
      uOXED, oxeduProject;

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

   if(sceneWnd <> nil) and (sceneWnd.IsSelected()) then begin
      if(oxedProjectValid()) then begin
         path := oxedProject.Path + 'screenshots' + DirectorySeparator;

         FileUtils.CreateDirectory(path);
      end;

      name := DateTimeToStr(Now);
      path := path + name + '.tga';

      oxScreenshot.Make(image, oxTWindow(sceneWnd.oxwParent),
         sceneWnd.RPosition.x, sceneWnd.RPosition.y - sceneWnd.Dimensions.h + 1, sceneWnd.Dimensions.w, sceneWnd.Dimensions.h);

      if(oxScreenshot.Save(path, image) = 0) then
         log.v('Took screenshot from: ' + oxedSceneWindows.LastSelectedWindow.Title + ' into ' + path);
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
      Name: 'oxed.scene.screenshot'
   );

procedure initialize();
begin
   gkHandlerKey.Key := oxedSceneScreenshot.CaptureKey;

   oxGlobalKeys.Hook(gkHandlerKey);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxedSceneScreenshot.CaptureKey := gkHandlerKey.Key;

   oxed.Init.iAdd(initRoutines, 'scene_screenshot', @initialize);

END.
