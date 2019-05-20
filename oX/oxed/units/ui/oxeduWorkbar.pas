{
   oxeduWorkbar, toolbar
   Copyright (C) 2016. Dejan Boras

   Started On:    29.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduWorkbar;

INTERFACE

   USES
      uStd, uColors,
      {ui}
      uiWidgets, wdguToolbar, wdguFileList,
      {oxed}
      oxeduProject, oxeduProjectManagement,
      oxeduIcons, oxeduActions, oxeduProjectSettingsWindow;

TYPE
   { oxedTWorkbarGlobal }

   oxedTWorkbarGlobal = record
      Workbar: wdgTToolbar;

      Buttons: record
         ProjectSettings,
         ProjectDirectory,
         OpenLazarus: wdgPToolbarItem;
      end;

      procedure Initialize();
   end;

VAR
   oxedWorkbar: oxedTWorkbarGlobal;

IMPLEMENTATION

{ oxedTWorkbarGlobal }

procedure projectChange();
begin
   if(oxedWorkbar.Workbar = nil) then
      exit;

   oxedWorkbar.Buttons.OpenLazarus^.Enable(oxedProjectValid());
   oxedWorkbar.Buttons.ProjectSettings^.Enable(oxedProject <> nil);
   oxedWorkbar.Buttons.ProjectDirectory^.Enable(oxedProjectValid());
end;

procedure oxedTWorkbarGlobal.Initialize;
var
   btn: wdgPToolbarItem;

begin
   uiWidget.SetTarget();

   Workbar := wdgToolbar.Add();
   Workbar.AddSeparator();

   Buttons.ProjectSettings := Workbar.AddButton(oxedIcons.Create($f013), oxedwndProjectSettings.OpenWindowAction);
   Buttons.ProjectSettings^.Hint := 'Open project settings';

   btn := Workbar.AddButton(oxedIcons.Create($f07b), oxedActions.OPEN_PROJECT_DIRECTORY);
   btn^.Hint := 'Open project directory';
   btn^.Color := wdgFileList.DirectoryColor;
   Buttons.ProjectDirectory := btn;

   btn := Workbar.AddButton(oxedIcons.Create($f1b0), oxedActions.OPEN_LAZARUS);
   btn^.Hint := 'Open lazarus for project';
   btn^.Color.Assign(160, 160, 255, 255);
   Buttons.OpenLazarus := btn;

   projectChange();
end;

INITIALIZATION
   oxedProjectManagement.OnNew.Add(@projectChange);
   oxedProjectManagement.OnClosed.Add(@projectChange);
   oxedProjectManagement.OnOpen.Add(@projectChange);

END.
