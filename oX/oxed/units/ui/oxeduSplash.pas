{
   oxeduSplash, recents list for oxed
   Copyright (C) 2016. Dejan Boras

   Started On:    16.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSplash;

INTERFACE

   USES uStd, oxeduRecents,
      {oX}
      oxuTypes, oxuwndSplash,
      {ui}
      oxuUI, uiuContextMenu, uiuWidget,
      {widgets}
      wdguButton,
      {oxed}
      oxeduMenubar, oxeduProjectManagement, oxeduActions, oxeduProject;

IMPLEMENTATION

VAR
   splashMenu: uiTContextMenu;
   wdgRecents: wdgTButton;

procedure openQuick();
begin
   splashMenu.Show(wdgRecents);
end;

procedure openRecent({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem);
var
   recent: string;

begin
   recent := oxedRecents.List.List[item^.Index];
   oxedProjectManagement.Open(recent);
end;

procedure openLastSession();
begin
   oxedProjectManagement.Open(oxedRecents.LastOpen);
end;

procedure InitSplash();
var
   i: longint;
   templates: uiTContextMenu;
   dimensions: oxTDimensions;
   item: uiPContextMenuItem;
   button: wdgTButton;

begin
   if(splashMenu = nil) then begin
      splashMenu := uiTContextMenu.Create('Splash');

      splashMenu.AddItem('Open project', oxedActions.OPEN_PROJECT);
      templates := splashMenu.AddSub('Templates');
      templates.AddItem('Empty project (New)', oxedActions.NEW_PROJECT);
      templates.AddItem('Test level');

      splashMenu.AddSeparator();

      if(oxedRecents.List.n > 0) then  begin
         for i := 0 to (oxedRecents.List.n - 1) do begin
            item := splashMenu.AddItem(oxedRecents.List.List[i], 0, @openRecent);
            item^.Index := i;
         end;
      end else
         splashMenu.AddItem('No recents');
   end;

   dimensions.Assign(160, 25);

   wdgRecents := wdgButton.Add('Quick', oxPoint(5, oxwndSplash.SplashImageEnd), dimensions, @openQuick);
   button := wdgButton.Add('Open Last Session', oxPoint(5, oxwndSplash.SplashImageEnd - dimensions.h - wdgDEFAULT_SPACING), dimensions, @openLastSession);

   if((oxedProject <> nil) and (oxedProject.Path = oxedRecents.LastOpen)) or (oxedRecents.LastOpen = '') then
      button.Enable(false);
end;

procedure InitMenu();
begin
   oxedMenubar.Help.AddSeparator();
   oxedMenubar.Help.AddItem('Show Splash Screen', @oxwndSplash.Open);
end;

procedure DeInitialize();
begin
   FreeObject(splashMenu);
end;

procedure projectOpen();
begin
   if(oxwndSplash <> nil) then
      oxwndSplash.Close();
end;

INITIALIZATION
   oxwndSplash.OnInit.Add(@InitSplash);
   oxwndSplash.ShowBuildInformation := true;
   oxui.initializationProcs.dAdd('oxed.splash', @DeInitialize);
   oxedMenubar.OnInit.Add(@initMenu);
   oxedProjectManagement.OnProjectOpen.Add(@projectOpen);
   oxedProjectManagement.OnNewProject.Add(@projectOpen);

END.

