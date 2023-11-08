{
   oxeduWindowTitle, window title updating
   Copyright (C) 2017. Dejan Boras

   Started On:    09.04.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduWindowTitle;

INTERFACE

   USES
      {ox}
      oxuWindow,
      {oxed}
      uOXED, oxeduProject, oxeduProjectManagement;


IMPLEMENTATION

procedure UpdateTitle();
var
   title: string;

begin
   title := '';

   if(oxedProject <> nil) then begin
      if(oxedProject.Modified) then
         title := oxedPROJECT_WINDOW_TITLE + ' > *' + oxedProject.Name
      else
         title := oxedPROJECT_WINDOW_TITLE + ' > ' + oxedProject.Name;
   end else
      title := oxedPROJECT_WINDOW_TITLE;

   if(oxWindow.Current.Title <> title) then
      oxWindow.Current.SetTitle(title);
end;

INITIALIZATION
   oxedTProject.OnProjectModified.Add(@updateTitle);

   oxedProjectManagement.OnNew.Add(@updateTitle);
   oxedProjectManagement.OnSaved.Add(@updateTitle);
   oxedProjectManagement.OnClosed.Add(@updateTitle);
   oxedProjectManagement.OnOpen.Add(@updateTitle);

END.
