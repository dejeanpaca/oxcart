{
   oxeduBuild, oxed build system
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectActions;

INTERFACE

   USES
      uStd,
      {app}
      uAppInfo, uApp, appuPaths, appuActionEvents,
      {oxed}
      uOXED, oxeduActions,
      oxeduProject, oxeduAppInfo;

IMPLEMENTATION

procedure openProjectDirectory();
begin
   app.OpenFileManager(oxedProject.Path);
end;

procedure openProjectConfiguration();
var
   info: appTInfo;
   path: StdString;

begin
   oxedAppInfo.GetAppInfo(info);
   info.SetOrganization(oxedPROJECT_ORGANIZATION);

   path := appPath.GetConfigurationPath(info);

   if(path <> '') then
      app.OpenFileManager(path);
end;

INITIALIZATION
   oxedActions.OPEN_PROJECT_DIRECTORY := appActionEvents.SetCallback(@openProjectDirectory);
   oxedActions.OPEN_PROJECT_CONFIGURATION := appActionEvents.SetCallback(@openProjectConfiguration);

END.
