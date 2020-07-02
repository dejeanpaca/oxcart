{
   oxeduBuildEditor
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuildEditor;

INTERFACE

   USES
      appuActionEvents,
      {oxed}
      oxeduActions, oxeduBuild, oxeduEditorPlatform;

IMPLEMENTATION

procedure RebuildEditorTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_REBUILD, oxedEditorPlatform.Architecture);
end;

procedure RecodeEditorTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_RECODE, oxedEditorPlatform.Architecture);
end;

procedure CleanupEditorTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_CLEANUP, oxedEditorPlatform.Architecture);
end;

procedure RecreateEditorTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_RECREATE, oxedEditorPlatform.Architecture);
end;

procedure RebuildThirdPartyTask();
begin
   oxedBuild.StartTask(OXED_BUILD_TASK_REBUILD_THIRD_PARTY, oxedEditorPlatform.Architecture);
end;

INITIALIZATION
   oxedActions.REBUILD := appActionEvents.SetCallback(@RebuildEditorTask);
   oxedActions.RECODE := appActionEvents.SetCallback(@RecodeEditorTask);
   oxedActions.RECREATE := appActionEvents.SetCallback(@RecreateEditorTask);
   oxedActions.CLEANUP := appActionEvents.SetCallback(@CleanupEditorTask);
   oxedActions.REBUILD_THIRD_PARTY := appActionEvents.SetCallback(@RebuildThirdPartyTask);

END.
