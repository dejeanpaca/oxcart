{
   oxeduAndroidBuild
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidBuild;

INTERFACE

   USES
      {app}
      appuEvents, appuActionEvents,
      {oxed}
      oxeduBuild,
      oxeduAndroidPlatform;

TYPE

   { oxedTAndroidBuild }

   oxedTAndroidBuild = record
      BUILD_TO_PROJECT_ACTION: TEventID;

      procedure BuildToProject();
   end;

VAR
  oxedAndroidBuild: oxedTAndroidBuild;

IMPLEMENTATION

{ oxedTAndroidBuild }

procedure oxedTAndroidBuild.BuildToProject();
begin
   oxedBuild.BuildTarget := OXED_BUILD_LIB;
   oxedBuild.StartTask(OXED_BUILD_TASK_RECODE, oxedAndroidPlatform.Architectures.List[0]);
end;

procedure buildToProject();
begin
   oxedAndroidBuild.BuildToProject();
end;

INITIALIZATION
   oxedAndroidBuild.BUILD_TO_PROJECT_ACTION := appActionEvents.SetCallback(@buildToProject);

END.
