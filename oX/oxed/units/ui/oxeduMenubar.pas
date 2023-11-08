{
   oxeduMenubar, menu bar setup for oxed
   Copyright (C) 2016. Dejan Boras

   Started On:    16.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduMenubar;

INTERFACE

   USES
      uStd, uLog,
      {events}
      appuActionEvents, appuEvents,
      {oX}
      oxuWindows, oxuTexture, oxuScene, oxuThreadTask, oxuFont, oxuFreetypeFonts,
      {ui}
      uiuContextMenu, oxuwndAbout, oxuwndSettings, oxuwndResourceInspector,
      {widgets}
      uiWidgets, wdguMenubar, uiuWidget,
      {oxed}
      uOXED, oxeduActions, oxeduRecents, oxeduIcons, oxeduBuild, oxeduPlatform, oxuwndDVarEditor, oxeduTasks,
      oxeduProject, oxeduProjectManagement, oxeduProjectSettingsWindow, oxeduRunSettingsWindow, oxeduProjectRunner,
      oxeduSettings;

TYPE

   { oxedTMenubarGlobal }

   oxedTMenubarGlobal = record
      Bar: wdgTMenubar;

      Windows,
      Help,
      Editor,
      Project,
      FileMenu,
      Entities,
      ObjectMenu,
      SceneMenu: uiTContextMenu;

      Recents: uiTContextMenu;

      Items: record
         Recents,
         ClearMessagesOnStart,
         FocusGameViewOnStart,
         IncludeThirdPartyUnits: uiPContextMenuItem;
      end;

      OpenWindows,
      Build: uiTContextMenu;

      OnInit,
      OnDeinit,
      OnResize: TProcedures;

      UPDATE_RECENTS_EVENT,
      CLEAR_RECENTS_EVENT: TEventID;

      procedure Initialize();
      procedure Deinitialize();
      procedure UpdateRecents();
      procedure SetupWindowsMenu();
   end;

VAR
   oxedMenubar: oxedTMenubarGlobal;

IMPLEMENTATION

TYPE
   { wdgTOXEDMenubar }

   wdgTOXEDMenubar = class(wdgTMenubar)
      procedure SizeChanged; override;
      procedure DeInitialize; override;
   end;

procedure openAbout();
begin
   oxwndAbout.Open();
end;

procedure clearMessagesOnStartToggle();
begin
   oxedSettings.ClearMessagesOnStart := oxedMenubar.Items.ClearMessagesOnStart^.IsChecked();
end;

procedure focusGameViewOnStartToggle();
begin
   oxedSettings.FocusGameViewOnStart := oxedMenubar.Items.FocusGameViewOnStart^.IsChecked();
end;

procedure CreateRecents(menu: uiTContextMenu);
begin
   oxedMenubar.Recents := menu.AddSub('Recents');
   oxedMenubar.Items.Recents := menu.GetSub(oxedMenubar.Recents);
   oxedIcons.Create(oxedMenubar.Items.Recents, $f0c5);

   oxedMenubar.UpdateRecents();
end;

procedure oxedTMenubarGlobal.Initialize();
var
   menu,
   context: uiTContextMenu;
   item: uiPContextMenuItem;

begin
   OpenWindows := uiTContextMenu.Create('Open Windows');

   uiWidget.Create.Instance := wdgTOXEDMenubar;
   Bar := wdgMenubar.Add(oxWindows.w[0]);

   { FILES }

   FileMenu := Bar.Add('File');
   item := FileMenu.AddItem('New Project', oxedActions.NEW_PROJECT);
   oxedIcons.Create(item, $f15b);
   item := FileMenu.AddItem('Open Project', oxedActions.OPEN_PROJECT);
   oxedIcons.Create(item, $f07c);
   item := FileMenu.AddItem('Save Project', oxedActions.SAVE_PROJECT);
   oxedIcons.Create(item, $f0c7);
   item := FileMenu.AddItem('Close Project', oxedActions.CLOSE_PROJECT);
   oxedIcons.Create(item, $f00d);
   FileMenu.AddSeparator();
   item := FileMenu.AddItem('New Scene', oxedActions.NEW_SCENE);
   oxedIcons.Create(item, $f15b);
   item := FileMenu.AddItem('Open Scene', oxedActions.OPEN_SCENE);
   oxedIcons.Create(item, $f07c);
   item := FileMenu.AddItem('Save Scene', oxedActions.SAVE_SCENE);
   oxedIcons.Create(item, $f0c7);
   FileMenu.AddSeparator();
   CreateRecents(FileMenu);
   FileMenu.AddSeparator();
   item := FileMenu.AddItem('Quit', appACTION_QUIT);
   oxedIcons.Create(item, $f011);

   { EDITOR }

   Editor := Bar.Add('Editor');
   item := Editor.AddItem('Open config directory', @oxed.OpenConfigDirectory);
   oxedIcons.Create(item, $f07b);
   item := Editor.AddItem('Open logs', @oxed.OpenLogs);
   oxedIcons.Create(item, $f03a);
   Editor.AddItem('DVar Editor', oxwndDVarEditor.OpenWindowAction);
   Editor.AddItem('Resource Inspector', oxwndResourceInspector.OpenWindowAction);
   Editor.AddSeparator();

   Items.ClearMessagesOnStart := Editor.AddCheckbox('Clear messages on start', oxedSettings.ClearMessagesOnStart);
   Items.ClearMessagesOnStart^.Callbacks.Use(@clearMessagesOnStartToggle);

   Items.FocusGameViewOnStart := Editor.AddCheckbox('Focus game view on start', oxedSettings.FocusGameViewOnStart);
   Items.FocusGameViewOnStart^.Callbacks.Use(@focusGameViewOnStartToggle);

   Editor.AddSeparator();
   item := Editor.AddItem('Settings', oxwndSettings.OpenWindowAction);
   oxedIcons.Create(item, $f013);

   { SCENE }

   SceneMenu := Bar.Add('Scene');
   context := SceneMenu.AddSub('Predefined');
   context.AddItem('Clear scene', oxedActions.SCENE_CLEAR);
   context.AddItem('Default scene', oxedActions.SCENE_DEFAULT);
   SceneMenu.AddItem('Screenshot', oxedActions.SCENE_SCREENSHOT);

   { ENTITIES }

   Entities := Bar.Add('Entities');
   context := Entities.AddSub('Simple');
   context.AddItem('Empty');
   context.AddItem('Cube');
   context.AddItem('Plane');

   ObjectMenu := Bar.Add('Object');
   ObjectMenu.AddItem('Focus', oxedActions.FOCUS_SELECTED);
   ObjectMenu.AddSeparator();
   item := ObjectMenu.AddItem('Reset Camera', oxedActions.RESET_CAMERA);
   oxedIcons.Create(item, $f03d);

   { PROJECT }

   Project := Bar.Add('Project');

   item := Project.AddItem('Recode', oxedActions.RECODE);

   if(oxedPlatform.GlyphCode <> 0) then
      oxedIcons.Create(item, oxedPlatform.GlyphCode, oxedPlatform.GlyphName);

   item := Project.AddItem('Rebuild', oxedActions.BUILD);

   if(oxedPlatform.GlyphCode <> 0) then
      oxedIcons.Create(item, oxedPlatform.GlyphCode, oxedPlatform.GlyphName);

   Project.AddItem('Cleanup', oxedActions.CLEANUP);
   Project.AddItem('Rescan', oxedActions.RESCAN);
   Project.AddSeparator();

   item := Project.AddItem('Play (Run)', oxedActions.RUN_PLAY);
   oxedIcons.Create(item, $f04b);
   item := Project.AddItem('Pause', oxedActions.RUN_PAUSE);
   oxedIcons.Create(item, $f04c);
   item := Project.AddItem('Stop', oxedActions.RUN_STOP);
   oxedIcons.Create(item, $f04d);
   Project.AddSeparator();
   Build := Project.AddSub('Build');
   Project.AddItem('Run Settings', oxedwndRunSettings.OpenWindowAction);
   Project.AddSeparator();
   Items.IncludeThirdPartyUnits := Project.AddCheckbox('Include third party units', false);
   Project.AddItem('Rebuild third party units', oxedActions.REBUILD_THIRD_PARTY);
   Project.AddSeparator();
   item := Project.AddItem('Settings', oxedwndProjectSettings.OpenWindowAction);
   oxedIcons.Create(item, $f013);
   item := Project.AddItem('Open Lazarus', oxedActions.OPEN_LAZARUS);
   oxedIcons.Create(item, $f1b0);
   item := Project.AddItem('Open Project Directory', oxedActions.OPEN_PROJECT_DIRECTORY);
   oxedIcons.Create(item, $f07b);
   item := Project.AddItem('Open Project Configuration', oxedActions.OPEN_PROJECT_CONFIGURATION);
   oxedIcons.Create(item, $f07b);

   { WINDOWS }

   Windows := Bar.Add('Windows');

   { HELP }

   menu := Bar.Add('Help');
   item := menu.AddItem('About', @openAbout);
   oxedIcons.Create(item, $f129);

   Help := menu;

   Bar.SetTarget();

   OnInit.Call();
end;

procedure oxedTMenubarGlobal.Deinitialize();
begin
   OnDeinit.Call();
end;

procedure clearRecents();
begin
   oxedRecents.List.Dispose();
   oxedMenubar.UpdateRecents();
end;

procedure updateRecents();
begin
   oxedMenubar.UpdateRecents();
end;

{ wdgTOXEDMenubar }

procedure wdgTOXEDMenubar.SizeChanged;
begin
   inherited SizeChanged;

   oxedMenubar.OnResize.Call();
end;

procedure wdgTOXEDMenubar.DeInitialize;
begin
   inherited DeInitialize;

   oxedMenubar.Bar := nil;
end;

procedure openRecentCallback({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem);
begin
   if(item^.Index < oxedRecents.List.n) then begin
      oxedProjectManagement.Open(oxedRecents.List.List[item^.Index]);
   end;
end;

{ oxedTMenubarGlobal }

procedure oxedTMenubarGlobal.UpdateRecents();
var
   i: longint;
   item: uiPContextMenuItem;

begin
   Recents.RemoveAll();

   if(oxedRecents.List.n > 0) then begin
      for i := 0 to (oxedRecents.List.n - 1) do begin
         item := Recents.AddItem(oxedRecents.List.List[i], 0, @openRecentCallback);
         item^.Index := i;
      end;

      Recents.AddSeparator();
      Recents.AddItem('Clear all', CLEAR_RECENTS_EVENT);
   end else
      Recents.Disable();
end;

procedure oxedTMenubarGlobal.SetupWindowsMenu();
begin
   Windows.AddSub('Open', OpenWindows);
   Windows.AddItem('Reset Layout', oxedActions.RESET_WINDOW_LAYOUT);
end;

procedure OnProjectChange();
var
   running,
   enableRun: boolean;

begin
   running := oxedProjectRunner.IsRunning();

   enableRun := (oxedProject <> nil) and (not running);

   oxedMenubar.FileMenu.FindByAction(oxedActions.CLOSE_PROJECT)^.Enable(enableRun);
   oxedMenubar.FileMenu.FindByAction(oxedActions.SAVE_PROJECT)^.Enable(enableRun);

   oxedMenubar.FileMenu.FindByAction(oxedActions.NEW_PROJECT)^.Enable(not running);
   oxedMenubar.FileMenu.FindByAction(oxedActions.OPEN_PROJECT)^.Enable(not running);
   oxedMenubar.FileMenu.FindByAction(oxedActions.NEW_SCENE)^.Enable(enableRun);
   oxedMenubar.FileMenu.FindByAction(oxedActions.OPEN_SCENE)^.Enable(enableRun);
   oxedMenubar.FileMenu.FindByAction(oxedActions.SAVE_SCENE)^.Enable(enableRun and oxedProjectValid() and (oxScene <> nil));

   oxedMenubar.Recents.Enable(not running);

   oxedMenubar.Project.FindByAction(oxedwndProjectSettings.OpenWindowAction)^.Enable(enableRun);
   oxedMenubar.Project.FindByAction(oxedActions.OPEN_LAZARUS)^.Enable(oxedProjectValid());
   oxedMenubar.Project.FindByAction(oxedActions.OPEN_PROJECT_DIRECTORY)^.Enable(oxedProjectValid());

   oxedMenubar.SceneMenu.Enable(oxedProject <> nil);
   oxedMenubar.Entities.Enable(oxedProject <> nil);
   oxedMenubar.Project.Enable(oxedProject <> nil);
   oxedMenubar.ObjectMenu.Enable(oxedProject <> nil);
end;


INITIALIZATION
   TProcedures.InitializeValues(oxedMenubar.OnInit);
   TProcedures.InitializeValues(oxedMenubar.OnDeinit);
   TProcedures.InitializeValues(oxedMenubar.OnResize);

   oxedMenubar.CLEAR_RECENTS_EVENT := appActionEvents.SetCallback(@clearRecents);
   oxedMenubar.UPDATE_RECENTS_EVENT := appActionEvents.SetCallback(@updateRecents);

   oxedProjectManagement.OnOpen.Add(@OnProjectChange);
   oxedProjectManagement.OnClosed.Add(@OnProjectChange);
   oxedProjectManagement.OnSaved.Add(@OnProjectChange);
   oxedProjectManagement.OnNew.Add(@OnProjectChange);

   oxedProjectRunner.OnStart.Add(@OnProjectChange);
   oxedProjectRunner.OnStop.Add(@OnProjectChange);
   oxedProjectRunner.OnPauseToggle.Add(@OnProjectChange);

   oxedTasks.OnTaskStart.Add(@OnProjectChange);
   oxedTasks.OnTaskDone.Add(@OnProjectChange);

   oxedRecents.OnUpdate.Add(@updateRecents);

END.
