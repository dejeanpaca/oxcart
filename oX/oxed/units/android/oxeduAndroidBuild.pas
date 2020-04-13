{
   oxeduAndroidBuild
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidBuild;

INTERFACE

   USES
      {app}
      appuEvents, appuActionEvents;

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

end;

procedure buildToProject();
begin
   oxedAndroidBuild.BuildToProject();
end;

INITIALIZATION
   oxedAndroidBuild.BUILD_TO_PROJECT_ACTION := appActionEvents.SetCallback(@buildToProject);

END.
