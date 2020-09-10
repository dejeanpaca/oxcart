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
      oxeduPlatform, oxeduAndroidPlatform, oxeduWorkbar,
      oxeduAndroidBuild,
      oxeduMenubar, oxeduIcons;

IMPLEMENTATION

procedure onEnable(platform: oxedTPlatform);
var
   item: wdgPToolbarItem;

begin
   if(platform = oxedAndroidPlatform ) then begin
      item := oxedWorkbar.Workbar.FindItemByAction(oxedAndroidBuild.BUILD_TO_PROJECT_ACTION);

      if(item = nil) then begin
         item := oxedWorkbar.Workbar.AddButton(oxedIcons.Create($f3cd), oxedAndroidBuild.BUILD_TO_PROJECT_ACTION);
         item^.Hint := 'Build to android project';
         item^.Color.Assign(61, 220, 132, 255);
      end;
   end;
end;

procedure onDisable(platform: oxedTPlatform);
var
   item: wdgPToolbarItem;

begin
   if(platform = oxedAndroidPlatform) then begin
      item := oxedWorkbar.Workbar.FindItemByAction(oxedAndroidBuild.BUILD_TO_PROJECT_ACTION);

      if(item <> nil) then begin
         oxedWorkbar.Workbar.RemoveItem(item);
      end;
   end;
end;

INITIALIZATION
   oxedPlatforms.OnEnable.Add(@onEnable);
   oxedPlatforms.OnDisable.Add(@onDisable);

END.
