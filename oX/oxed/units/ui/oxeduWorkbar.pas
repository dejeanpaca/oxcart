{
   oxeduWorkbar, toolbar
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduWorkbar;

INTERFACE

   USES
      uStd, uColors,
      {ui}
      uiWidgets, uiuFiles, wdguToolbar,
      {oxed}
      oxeduUI,
      oxeduProject, oxeduProjectManagement,
      oxeduIcons, oxeduActions,
      oxeduwndProjectSettings;

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

   btn := Workbar.AddButton(oxedIcons.Create($f121), oxedActions.RECODE);
   btn^.Hint := 'Recode project';
   btn^.Color.Assign(255, 102, 0, 255);

   Workbar.AddSeparator();

   Buttons.ProjectSettings := Workbar.AddButton(oxedIcons.Create($f013), oxedwndProjectSettings.OpenWindowAction);
   Buttons.ProjectSettings^.Hint := 'Open project settings';

   btn := Workbar.AddButton(oxedIcons.Create($f07b), oxedActions.OPEN_PROJECT_DIRECTORY);
   btn^.Hint := 'Open project directory';
   btn^.Color := uiFiles.DirectoryColor;
   Buttons.ProjectDirectory := btn;

   btn := Workbar.AddButton(oxedIcons.Create($f1b0), oxedActions.OPEN_LAZARUS);
   btn^.Hint := 'Open lazarus for project';
   btn^.Color := oxedUI.LazarusColor;
   Buttons.OpenLazarus := btn;

   projectChange();
end;

INITIALIZATION
   oxedProjectManagement.OnNew.Add(@projectChange);
   oxedProjectManagement.OnClosed.Add(@projectChange);
   oxedProjectManagement.OnOpen.Add(@projectChange);

END.
