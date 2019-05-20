{
   oxeduBuildEvents, oxed build events
   Copyright (C) 2019. Dejan Boras

   Started On:    20.05.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuildEvents;

INTERFACE

   USES
      appuActionEvents,
      {oxed}
      oxeduActions, oxeduBuild, oxeduProjectManagement;

IMPLEMENTATION

{NOTE: cleanup project after a overwrite, because we don't want to encounter problems with possible
 leftovers of a previous project}
procedure overwriteCleanup();
begin
   appActionEvents.Queue(oxedActions.CLEANUP);
end;


INITIALIZATION
   oxedProjectManagement.OnOverwritten.Add(@overwriteCleanup);

END.
