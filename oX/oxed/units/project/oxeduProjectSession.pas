{
   oxeduProjectSession, project session settings
   Copyright (C) 2017. Dejan Boras

   Started On:    15.11.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectSession;

INTERFACE

   USES
      sysutils, uStd, udvars, dvaruFile,
      {oxed}
      oxeduProject;

CONST
   OXED_PROJECT_SESSION_FILE = 'session.dvar';

TYPE

   { oxedTProjectSession }

   oxedTProjectSession = record
      class function GetFn(): string; static;

      class procedure Load(); static;
      class procedure Save(); static;
   end;

IMPLEMENTATION

VAR
   dvGroup: TDVarGroup;
   dvLastScene,
   dvIncludeThirdPartyUnits,
   dvDebugResources,
   dvEnableConsole: TDVar;

{ oxedTProjectSession }

class function oxedTProjectSession.GetFn(): string;
begin
   Result := oxedProject.GetTempFilePath(OXED_PROJECT_SESSION_FILE);
end;

procedure UpdateVars();
begin
   dvLastScene.Update(oxedProject.LastScene);
   dvIncludeThirdPartyUnits.Update(oxedProject.Session.IncludeThirdPartyUnits);
   dvDebugResources.Update(oxedProject.Session.DebugResources);
   dvEnableConsole.Update(oxedProject.Session.EnableConsole);
end;

class procedure oxedTProjectSession.Load();
begin
   UpdateVars();

   dvarf.ReadText(dvGroup, GetFn());
end;

class procedure oxedTProjectSession.Save();
begin
   UpdateVars();
   oxedProject.RecreateTempDirectory();

   dvarf.WriteText(dvGroup, GetFn());
end;


INITIALIZATION
   dvar.Init(dvGroup);
   dvGroup.Name := 'session';

   dvGroup.Add(dvLastScene, 'last_scene', dtcSTRING, @oxedProject.LastScene);
   dvGroup.Add(dvIncludeThirdPartyUnits, 'include_third_party_units', dtcBOOL, @oxedProject.Session.IncludeThirdPartyUnits);
   dvGroup.Add(dvDebugResources, 'debug_resources', dtcBOOL, @oxedProject.Session.DebugResources);
   dvGroup.Add(dvEnableConsole, 'enable_console', dtcBOOL, @oxedProject.Session.EnableConsole)

END.
