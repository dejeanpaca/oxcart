{
   oxeduKeys, oxed key mappings
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduKeys;

INTERFACE

   USES
      appuKeys, appuKeyMappings, appuActionEvents,
      oxeduActions;

TYPE
   { oxedTKeyMappings }

   oxedTKeyMappings = record
      mFile,
      mProject,
      mView: appTKeyMappingGroup;

      procedure Initialize();
   end;

VAR
   oxedKeyMappings: oxedTKeyMappings;

IMPLEMENTATION

{ oxedTKeyMappings }

procedure oxedTKeyMappings.Initialize();
begin
   { FILE OPERATIONS }
   appKeyMappings.AddGroup('file', 'File operations', mFile);

   {open project}
   mFile.AddKey('project.open', 'Open project', kcO, kmCONTROL)^.
      Action := oxedActions.OPEN_PROJECT;
   {new project}
   mFile.AddKey('project.new', 'New project', kcN, kmCONTROL)^.
      Action := oxedActions.NEW_PROJECT;
   {open project}
   mFile.AddKey('project.save', 'Save project', kcS, kmCONTROL)^.
      Action := oxedActions.SAVE_PROJECT;

   {new scene}
   mFile.AddKey('scene.new', 'New scene', kcN, kmSHIFT or kmCONTROL)^.
      Action := oxedActions.NEW_SCENE;
   {open scene}
   mFile.AddKey('scene.open', 'Open scene', kcO, kmSHIFT or kmCONTROL)^.
      Action := oxedActions.OPEN_SCENE;
   {save scene}
   mFile.AddKey('scene.save', 'Save scene', kcS, kmSHIFT or kmCONTROL)^.
      Action := oxedActions.SAVE_SCENE;

   {quit}
   mFile.AddKey('quit', 'Quit', kcX, kmALT)^.
      Action := appACTION_QUIT;

   { PROJECT }
   appKeyMappings.AddGroup('project', 'Project', mProject);

   {build}
   mProject.AddKey('project.build', 'Build project', kcF9, kmSHIFT)^.
     Action := oxedActions.BUILD;
   {recode}
   mProject.AddKey('project.recode', 'Recode project', kcF9, kmCONTROL)^.
     Action := oxedActions.RECODE;

   {run}
   mProject.AddKey('run.play', 'Play (Run)', kcR, kmCONTROL)^.
      Action := oxedActions.RUN_PLAY;
   mProject.AddKey('run.pause', 'Pause)', kcP, kmCONTROL)^.
      Action := oxedActions.RUN_PAUSE;
   mProject.AddKey('run.stop', 'Stop', kcX, kmCONTROL)^.
      Action := oxedActions.RUN_STOP;

   { VIEW }

   {view}
   appKeyMappings.AddGroup('view', 'View', mView);

   mView.AddKey('view.front', 'View Front', kcNUM1, kmNONE)^.
     Action := oxedActions.VIEW_FRONT;
   mView.AddKey('view.left', 'View Left', kcNUM3, kmNONE)^.
     Action := oxedActions.VIEW_LEFT;
   mView.AddKey('view.up', 'View Up', kcNUM7, kmNONE)^.
     Action := oxedActions.VIEW_UP;

   mView.AddKey('view.back', 'View Back', kcNUM1, kmCONTROL)^.
     Action := oxedActions.VIEW_BACK;
   mView.AddKey('view.right', 'View Right', kcNUM3, kmCONTROL)^.
     Action := oxedActions.VIEW_RIGHT;
   mView.AddKey('view.down', 'View Down', kcNUM7, kmCONTROL)^.
     Action := oxedActions.VIEW_DOWN;

   appKeyMappings.Validate();
end;

END.
