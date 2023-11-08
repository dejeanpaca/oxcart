{
   oxeduProjectNotification, project notifications
   Copyright (C) 2019. Dejan Boras

   Started On:    28.07.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectNotification;

INTERFACE

   USES
      {ox}
      oxuWindow,
      {oxed}
      uOXED, oxeduProject, oxeduProjectManagement, oxuwndToast;

IMPLEMENTATION

procedure openNotify();
begin
   if(oxedProject <> nil) then
      oxToast.Show('Project open', oxedProject.Name);
end;

INITIALIZATION
   oxedProjectManagement.OnOpen.Add(@openNotify);

END.