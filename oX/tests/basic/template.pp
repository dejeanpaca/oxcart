{
   template, a test template program

   Started On:    14.05.2012.
}


{$INCLUDE oxdefines.inc}
PROGRAM template;

   USES uAppInfo,
      uTiming,
      {app}
      uApp, appuKeys,
      {oX}
      oX, oxuDefaults, oxuConstants, oxuTypes, oxuRun, oxuDo, oxuWindow, oxuWndTools, oxuKeyB,
      oxuWindows,
      {test}
      uTestTools;

procedure Render(var wnd: oxTWindow);
begin
end;

function Perform(a: longword): boolean;
begin
   result := true;

   case a of
      oxDO_INITIALIZE: begin
      end;
      oxDO_RUN: begin
      end;
      oxDO_DEINITIALIZE: begin
      end;
   end;
end;

procedure Keyz(var key: appTKey; var wnd: oxTWindow);
begin
   if(key.KeyCode = kcESC) then
      appcActive := false;
end;

procedure InitWindow();
begin
   oxSetupWindows(1);
   oxwSetDimensions(oxWindows[0], 320, 480);
end;

procedure InitializeTest();
begin
   appInfo.setName('Template Test');

   oxDoRoutine := @Perform;
   oxonRenderWindow := @Render;
   oxonCreateWindows := @InitWindow;
   oxKeyUpRoutine := @Keyz;
end;

BEGIN
   InitializeTest();

   oxRun.Go();
END.

