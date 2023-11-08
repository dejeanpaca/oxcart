{
   oxeduProjectSession, project session settings
   Copyright (C) 2017. Dejan Boras

   Started On:    15.11.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectSession;

INTERFACE

   USES
      sysutils, uStd, udvars,
      {oxed}
      oxeduProject, oxeduProjectConfigurationFileHelper;

CONST
   OXED_PROJECT_SESSION_FILE = 'session.dvar';

VAR
   oxedProjectSessionFile: oxedTProjectConfigurationFileHelper;

IMPLEMENTATION

VAR
   dvGroup: TDVarGroup;
   dvLastScene,
   dvIncludeThirdPartyUnits,
   dvDebugResources,
   dvEnableConsole: TDVar;

procedure UpdateVars();
begin
   dvLastScene.Update(oxedProject.LastScene);
   dvIncludeThirdPartyUnits.Update(oxedProject.Session.IncludeThirdPartyUnits);
   dvDebugResources.Update(oxedProject.Session.DebugResources);
   dvEnableConsole.Update(oxedProject.Session.EnableConsole);
end;

procedure beforeSave();
begin
   UpdateVars();
   oxedProject.RecreateTempDirectory();
end;


INITIALIZATION
   dvar.Init(dvGroup);
   dvGroup.Name := 'session';

   dvGroup.Add(dvLastScene, 'last_scene', dtcSTRING, @oxedProject.LastScene);
   dvGroup.Add(dvIncludeThirdPartyUnits, 'include_third_party_units', dtcBOOL, @oxedProject.Session.IncludeThirdPartyUnits);
   dvGroup.Add(dvDebugResources, 'debug_resources', dtcBOOL, @oxedProject.Session.DebugResources);
   dvGroup.Add(dvEnableConsole, 'enable_console', dtcBOOL, @oxedProject.Session.EnableConsole);

   oxedProjectSessionFile.Create();
   oxedProjectSessionFile.FileName := OXED_PROJECT_SESSION_FILE;
   oxedProjectSessionFile.IsTemp := true;
   oxedProjectSessionFile.BeforeLoad := @UpdateVars;
   oxedProjectSessionFile.BeforeSave := @beforeSave;
   oxedProjectSessionFile.dvg := @dvGroup;

END.
