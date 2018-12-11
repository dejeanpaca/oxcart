{
   oxeduProjectSession, project session settings
   Copyright (C) 2017. Dejan Boras

   Started On:    15.11.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectSession;

INTERFACE

   USES
      sysutils, uStd, uLog, udvars, dvaruFile, uFileUtils,
      uAppInfo,
      {ox}
      oxuScene,
      {oxed}
      uOXED, oxeduProject, oxeduMessages;

CONST
   OXED_PROJECT_SESSION_FILE = 'session.dvar';

TYPE

   { oxedTProjectSession }

   oxedTProjectSession = record
      function GetFn(): string;

      procedure Load();
      procedure Save();
   end;

VAR
   oxedProjectSession: oxedTProjectSession;

IMPLEMENTATION

VAR
   dvGroup: TDVarGroup;
   dvLastScene,
   dvIncludeThirdPartyUnits,
   dvDebugResources,
   dvEnableConsole: TDVar;

{ oxedTProjectSession }

function oxedTProjectSession.GetFn(): string;
begin
   result := oxedProject.TempPath + OXED_PROJECT_SESSION_FILE;
end;

procedure UpdateVars();
begin
   dvLastScene.Variable := @oxedProject.LastScene;
   dvIncludeThirdPartyUnits.Variable := @oxedProject.Session.IncludeThirdPartyUnits;
   dvDebugResources.Variable := @oxedProject.Session.DebugResources;
   dvEnableConsole.Variable := @oxedProject.Session.EnableConsole;
end;

procedure oxedTProjectSession.Load;
begin
   UpdateVars();

   dvarf.ReadText(dvGroup, GetFn());
end;

procedure oxedTProjectSession.Save;
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
