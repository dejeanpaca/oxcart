{
   oxeduProjectNotification, project notifications
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectNotification;

INTERFACE

   USES
      uStd,
      {ox}
      oxuWindow,
      {oxed}
      uOXED, oxeduSettings,
      oxeduProject, oxeduProjectManagement, oxuwndToast;

IMPLEMENTATION

procedure openNotify();
begin
   if(oxedProject <> nil) and (oxedSettings.ShowNotifications) then
      oxToast.Show('Project open', oxedProject.Name);
end;

INITIALIZATION
   oxedProjectManagement.OnOpen.Add(@openNotify);

END.
