{
   oxeduProjectPackagesConfiguration, project packages configuration
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectPackagesConfiguration;

INTERFACE

   USES
      sysutils, uStd, udvars, dvaruFile,
      {oxed}
      oxeduProject, oxeduProjectPackages, oxeduProjectManagement, oxeduProjectConfigurationFileHelper;

CONST
   OXED_PROJECT_PACKAGES_CONFIGURATION_FILE = 'packages.dvar';

VAR
   oxedProjectPackagesConfigurationFile: oxedTProjectConfigurationFileHelper;

IMPLEMENTATION

VAR
   dvGroup: TDVarGroup;
   dvPackage: TDVar;

   currentPackage: StdString;

procedure load();
begin
   oxedProjectPackagesConfigurationFile.Load();
end;

procedure save();
begin
   oxedProjectPackagesConfigurationFile.Save();
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
      if(currentPackage <> '') then begin
         if(currentPackage[1] = '@') then begin
            path := Copy(currentPackage, 2, Length(currentPackage) - 1);
            oxedProject.AddPackagePath(path);
         end else
            oxedProject.AddPackage(currentPackage);
      end;
   end;
end;


INITIALIZATION
   dvar.Init(dvGroup);
   dvGroup.Name := 'packages';

   dvGroup.Add(dvPackage, 'package', dtcSTRING, @currentPackage);
   dvPackage.pNotify := @packageNotify;
   dvPackage.Properties := dvPackage.Properties + [dvarNOTIFY_READ, dvarNOTIFY_WRITE];

   oxedProjectPackagesConfigurationFile.Create(dvGroup);
   oxedProjectPackagesConfigurationFile.FileName := OXED_PROJECT_PACKAGES_CONFIGURATION_FILE;

   oxedProjectManagement.OnLoadProject.Add(@load);
   oxedProjectManagement.OnSaveProject.Add(@save);

END.
