{
   oxeduVCS
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduVCSManagement;

INTERFACE

   USES
      {oxed}
      oxeduProjectManagement, oxeduVCS;

IMPLEMENTATION

procedure projectLoaded();
begin
   if(oxedVCS.UsedVCS <> nil) then begin
      oxedVCS.UsedVCS.Stop();
      {NOTE: Set a different vcs if used by this project (for now we only have a single VCS integration with git)}
      oxedVCS.UsedVCS.Start();
   end;
end;

INITIALIZATION
   oxedProjectManagement.OnLoadedProject.Add(@projectLoaded);
END.
