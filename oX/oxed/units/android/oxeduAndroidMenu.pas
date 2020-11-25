{
   oxeduAndroidMenu
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduAndroidMenu;

INTERFACE

   USES
      uColors,
      {ui}
      wdguToolbar,
      {oxed}
      oxeduPlatform, oxeduWorkbar, oxeduMenubar, oxeduIcons,
      {android}
      oxeduAndroid, oxeduAndroidPlatform, oxeduAndroidBuild, oxeduAndroidSettings;

IMPLEMENTATION

procedure onEnable(platform: oxedTPlatform);
var
   item: wdgPToolbarItem;

begin
   if(platform = oxedAndroidPlatform ) then begin
      item := oxedWorkbar.Workbar.FindItemByAction(oxedAndroidBuild.BUILD_TO_PROJECT_ACTION);

      if(item = nil) then begin
         item := oxedWorkbar.Workbar.AddButton(oxedIcons.Create($f3cd), oxedAndroidBuild.BUILD_TO_PROJECT_ACTION);
         item^.SetHint('Build binary (' +
            oxedAndroidCPUTypes[LongInt(oxedAndroidSettings.Project.EmulatorCPUType)] + ') to android project');

         item^.Color.Assign(61, 220, 132, 255);

         item := oxedWorkbar.Workbar.AddButton(oxedIcons.Create($f10b), oxedAndroidBuild.BUILD_ASSETS_TO_PROJECT_ACTION);
         item^.SetHint('Build assets to android project');
         item^.Color.Assign(61, 220, 132, 255);
      end;
   end;
end;

procedure onDisable(platform: oxedTPlatform);
begin
   if(platform = oxedAndroidPlatform) then begin
      oxedWorkbar.Workbar.RemoveItem(oxedWorkbar.Workbar.FindItemByAction(oxedAndroidBuild.BUILD_TO_PROJECT_ACTION));
      oxedWorkbar.Workbar.RemoveItem(oxedWorkbar.Workbar.FindItemByAction(oxedAndroidBuild.BUILD_ASSETS_TO_PROJECT_ACTION));
   end;
end;

INITIALIZATION
   oxedPlatforms.OnEnable.Add(@onEnable);
   oxedPlatforms.OnDisable.Add(@onDisable);

END.
