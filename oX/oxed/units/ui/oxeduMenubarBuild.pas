{
   oxeduMenubarBuild, menu bar build options
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduMenubarBuild;

INTERFACE

   USES
      uStd, uLog,
      {ui}
      uiuWidget, uiuContextMenu,
      {oxed}
      oxeduIcons,
      oxeduProject, oxeduActions,
      oxeduBuild, oxeduTasks, oxeduPlatform,
      oxeduProjectRunner, oxeduProjectManagement,
      oxeduMenubar;

IMPLEMENTATION

procedure thirdPartyChange({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem);
begin
   if(oxedProject <> nil) then begin
      oxedProject.Session.IncludeThirdPartyUnits := item^.IsChecked();
      oxedProject.MarkModified();
   end;
end;

procedure SetupRunItems(running: boolean);
var
   enable: boolean;
   item: uiPContextMenuItem;

begin
   enable := oxedBuild.Buildable() and (oxedTasks.Running(nil) = 0);

   oxedMenubar.Project.FindByAction(oxedActions.RUN_PLAY)^.Enable(enable and (not running));
   oxedMenubar.Project.FindByAction(oxedActions.RUN_STOP)^.Enable(running);

   item := oxedMenubar.Project.FindByAction(oxedActions.RUN_PAUSE);
   item^.Enable(running);

   if(oxedProject <> nil) and (oxedProject.Paused) then
      item^.Caption := 'Resume'
   else
      item^.Caption := 'Pause';
end;

procedure OnProjectChange();
var
   enable: boolean;

begin
   enable := oxedBuild.Buildable();

   oxedMenubar.Project.FindByAction(oxedActions.REBUILD)^.Enable(enable);
   oxedMenubar.Project.FindByAction(oxedActions.RECODE)^.Enable(enable);
   oxedMenubar.Project.FindByAction(oxedActions.CLEANUP)^.Enable(enable);
   oxedMenubar.Project.FindByAction(oxedActions.RESCAN)^.Enable(enable);
   oxedMenubar.Project.FindByAction(oxedActions.RECREATE)^.Enable(enable);
   oxedMenubar.Project.FindByAction(oxedActions.REBUILD_THIRD_PARTY)^.Enable(enable);

   oxedMenubar.Build.Enable(enable);

   if(oxedProject <> nil) then
      oxedMenubar.Items.IncludeThirdPartyUnits^.SetChecked(oxedProject.Session.IncludeThirdPartyUnits);

   SetupRunItems(oxedProjectRunner.IsRunning());
end;

procedure buildStandalone({%H-}wdg: uiTWidget; {%H-}menu: TObject; item: uiPContextMenuItem);
begin
   oxedBuild.BuildStandaloneTask(oxedTPlatformArchitecture(item^.ExternalData));
end;

procedure SetupBuildOptions();
var
   i,
   archIndex: loopint;
   platform: oxedTPlatform;
   arch: oxedTPlatformArchitecture;
   item: uiPContextMenuItem;

begin
   oxedMenubar.Build.RemoveAll();

   for i := 1 to (oxedPlatforms.List.n - 1) do begin
      platform := oxedPlatforms.List.list[i];

      for archIndex := 0 to platform.Architectures.n - 1 do begin
         arch := platform.Architectures.List[archIndex];

         if(arch.Architecture <> '') then
            item := oxedMenubar.Build.AddItem(platform.Name + ' (' + arch.Name + ')')
         else
            item := oxedMenubar.Build.AddItem(platform.Name);

         item^.Callback := @buildStandalone;
         item^.ExternalData := arch;

         if(platform.GlyphCode <> 0) then
            oxedIcons.Create(item, oxedPlatform.GlyphCode, oxedPlatform.GlyphName);
      end;
   end;

   if(oxedPlatforms.List.n > 0) then
      oxedMenubar.Build.AddSeparator();

   oxedMenubar.Build.AddItem('Custom')^.Disable();

   OnProjectChange();
end;

procedure initBuildOptions();
begin
   SetupBuildOptions();
   oxedMenubar.Items.IncludeThirdPartyUnits^.Callback := @thirdPartyChange;
end;

INITIALIZATION
   oxedMenubar.OnInit.Add(@initBuildOptions);

   oxedProjectManagement.OnOpen.Add(@OnProjectChange);
   oxedProjectManagement.OnClosed.Add(@OnProjectChange);
   oxedProjectManagement.OnSaved.Add(@OnProjectChange);
   oxedProjectManagement.OnNew.Add(@OnProjectChange);

   oxedProjectRunner.OnStart.Add(@OnProjectChange);
   oxedProjectRunner.OnStop.Add(@OnProjectChange);
   oxedProjectRunner.OnPauseToggle.Add(@OnProjectChange);

   oxedTasks.OnTaskStart.Add(@OnProjectChange);
   oxedTasks.OnTaskDone.Add(@OnProjectChange);

END.
