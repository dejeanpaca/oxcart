{
   oxeduProjectPackages, oxed project package handling
   Copyright (C) 2020. Dejan Boras

   Started On:    29.01.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectPackages;

INTERFACE

   USES
      uStd, StringUtils,
      {oxed}
      oxeduPackage, oxeduProject, oxeduProjectManagement;

IMPLEMENTATION

procedure projectClose();
begin
  oxedProject.Packages.Dispose();
end;

procedure newProject();
begin

end;

INITIALIZATION
   oxedProjectManagement.OnClose.Add(@projectClose);
   oxedProjectManagement.OnNew.Add(@newProject);

END.
