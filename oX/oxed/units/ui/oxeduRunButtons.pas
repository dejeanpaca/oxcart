{
   oxeduRunButtons, run buttons
   Copyright (C) 2017. Dejan Boras

   Started On:    04.06.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduRunButtons;

INTERFACE

   USES
      uStd, uColors,
      {ox}
      oxuThreadTask,
      {widgets}
      uiWidgets, wdguToolbar,
      {oxed}
      oxeduActions, oxeduIcons, oxeduTasks, oxeduMenubar, oxeduMenuToolbar,
      oxeduProject, oxeduProjectRunner, oxeduProjectManagement;

TYPE
   oxedTRunButtons = record
      Wdg: record
         Play,
         Stop,
         Pause: wdgPToolbarItem;
      end;
   end;

VAR
   oxedRunButtons: oxedTRunButtons;

IMPLEMENTATION

procedure SetupRunButtons(running: boolean);
var
   enable: boolean;

begin
   if(oxedMenuToolbar.Toolbar = nil) then
      exit;

   enable := oxedProjectRunner.CanRun();

   oxedRunButtons.Wdg.Play^.Enable(enable and (not running));
   oxedRunButtons.Wdg.Pause^.Enable(running);
   oxedRunButtons.Wdg.Stop^.Enable(running);
end;

procedure Initialize();
begin
   if(oxedMenuToolbar.Toolbar = nil) then
      exit;

   if(oxedMenuToolbar.Toolbar.Items.n > 0) then
      oxedMenuToolbar.Toolbar.AddSeparator();

   oxedRunButtons.Wdg.Play := oxedMenuToolbar.Toolbar.AddButton(oxedIcons.Create($f04b), oxedActions.RUN_PLAY);
   oxedRunButtons.Wdg.Play^.Hint := 'Start playing (run) the project';

   oxedRunButtons.Wdg.Pause := oxedMenuToolbar.Toolbar.Addbutton(oxedIcons.Create($f04c), oxedActions.RUN_PAUSE);
   oxedRunButtons.Wdg.Pause^.Hint := 'Pause running';

   oxedRunButtons.Wdg.Stop := oxedMenuToolbar.Toolbar.AddButton(oxedIcons.Create($f04d), oxedActions.RUN_STOP);
   oxedRunButtons.Wdg.Stop^.Hint := 'Stop running';

   oxedMenuToolbar.OnResize();

   SetupRunButtons(false);
end;

procedure OnProjectChange();
begin
   if(oxedProject <> nil) then
      SetupRunButtons(oxedProject.Running);
end;

procedure OnProjectStart();
begin
   SetupRunButtons(true);
end;

procedure OnProjectStop();
begin
   SetupRunButtons(false);
end;

procedure OnProjectPauseToggle();
begin
   if(not oxedProject.Paused) then
      oxedRunButtons.Wdg.Pause^.Color := cWhite4ub
   else
      oxedRunButtons.Wdg.Pause^.Color.Assign(192, 64, 64, 255);
end;

INITIALIZATION
   oxedMenubar.OnInit.Add(@initialize);

   oxedProjectManagement.OnOpen.Add(@OnProjectChange);
   oxedProjectManagement.OnClosed.Add(@OnProjectChange);
   oxedProjectManagement.OnSaved.Add(@OnProjectChange);

   oxedProjectRunner.OnStart.Add(@OnProjectStart);
   oxedProjectRunner.OnStop.Add(@OnProjectStop);
   oxedProjectRunner.OnPauseToggle.Add(@OnProjectPauseToggle);

   oxedTasks.OnTaskStart.Add(@OnProjectChange);
   oxedTasks.OnTaskDone.Add(@OnProjectChange);

END.
