{
   oxeduRunButtons, run buttons
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
   oxedRunButtons.Wdg.Play^.SetHint('Start playing (run) the project');

   oxedRunButtons.Wdg.Pause := oxedMenuToolbar.Toolbar.Addbutton(oxedIcons.Create($f04c), oxedActions.RUN_PAUSE);
   oxedRunButtons.Wdg.Pause^.SetHint('Pause running');

   oxedRunButtons.Wdg.Stop := oxedMenuToolbar.Toolbar.AddButton(oxedIcons.Create($f04d), oxedActions.RUN_STOP);
   oxedRunButtons.Wdg.Stop^.SetHint('Stop running');

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
   if(not oxedProject.Paused) then begin
      oxedRunButtons.Wdg.Pause^.Color := cWhite4ub;
      oxedRunButtons.Wdg.Pause^.SetHint('Pause running');
   end else begin
      oxedRunButtons.Wdg.Pause^.Color.Assign(127, 64, 64, 255);
      oxedRunButtons.Wdg.Pause^.SetHint('Resume running');
   end;
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
