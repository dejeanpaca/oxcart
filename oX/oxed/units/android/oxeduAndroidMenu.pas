{
   oxeduAndroidMenu
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidMenu;

INTERFACE

   USES
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
   if(platform.Id = 'android') then begin
      item := oxedWorkbar.Workbar.FindItemByAction(oxedAndroidBuild.BUILD_TO_PROJECT_ACTION);

      if(item = nil) then begin
         oxedWorkbar.Workbar.AddButton(oxedIcons.Create($f3cd), oxedAndroidBuild.BUILD_TO_PROJECT_ACTION)^.
            Hint := 'Build to android project';
      end;
   end;
end;

procedure onDisable(platform: oxedTPlatform);
var
   item: wdgPToolbarItem;

begin
   if(platform.Id = 'android') then begin
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
