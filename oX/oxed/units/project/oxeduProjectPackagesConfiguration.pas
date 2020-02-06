{
   oxeduProjectPackagesConfiguration, project packages configuration
   Copyright (C) 2020. Dejan Boras

   Started On:    06.02.2020.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectPackagesConfiguration;

INTERFACE

   USES
      sysutils, uStd, udvars, dvaruFile,
      {oxed}
      oxeduProject, oxeduProjectPackages, oxeduProjectManagement;

CONST
   OXED_PROJECT_PACKAGES_CONFIGURATION_FILE = 'packages.dvar';

TYPE

   { oxedTProjectPackagesConfiguration }

   oxedTProjectPackagesConfiguration = record
      class function GetFn(): string; static;

      class procedure Load(); static;
      class procedure Save(); static;
   end;

IMPLEMENTATION

VAR
   dvGroup: TDVarGroup;
   dvPackage: TDVar;

   currentPackage: StdString;

{ oxedTProjectPackagesConfiguration }

class function oxedTProjectPackagesConfiguration.GetFn(): string;
begin
   Result := oxedProject.GetConfigFilePath(OXED_PROJECT_PACKAGES_CONFIGURATION_FILE);
end;

procedure UpdateVars();
begin
end;

class procedure oxedTProjectPackagesConfiguration.Load();
begin
   UpdateVars();

   dvarf.ReadText(dvGroup, GetFn());
end;

class procedure oxedTProjectPackagesConfiguration.Save();
begin
   UpdateVars();

   dvarf.WriteText(dvGroup, GetFn());
end;

procedure packageNotify(var context: TDVarNotificationContext);
var
   i: loopint;
   path: StdString;

begin
   if(context.What = DVAR_NOTIFICATION_WRITE) then begin
      context.Result := 0;

      if(oxedProject.Packages.n > 0) then begin
         for i := 0 to oxedProject.Packages.n - 1 do begin
            dvarPFileData(context.f)^.Write(context.Parent, dvPackage, oxedProject.Packages.List[i].GetIdentifier());
         end;
      end;
   end else if(context.What = DVAR_NOTIFICATION_READ) then begin
      if(currentPackage[1] = '@') then begin
         path := Copy(currentPackage, 1, Length(currentPackage) - 1);
         oxedProject.AddPackagePath(path);
      end else
         oxedProject.AddPackagePath(currentPackage);
   end;
end;


INITIALIZATION
   dvar.Init(dvGroup);
   dvGroup.Name := 'packages';

   dvGroup.Add(dvPackage, 'package', dtcSTRING, @currentPackage);
   dvPackage.pNotify := @packageNotify;

   oxedProjectManagement.OnLoadProject.Add(@oxedTProjectPackagesConfiguration.Load);
   oxedProjectManagement.OnSaveProject.Add(@oxedTProjectPackagesConfiguration.Save);

END.
