{
   oxeduProject, project for oxed
   Copyright (C) 2016. Dejan Boras

   Started On:    13.10.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduActions;

INTERFACE

   USES appuEvents, appuActionEvents;

VAR
   oxedActions: record
      OPEN_PROJECT,
      NEW_PROJECT,
      SAVE_PROJECT,
      CLOSE_PROJECT,

      NEW_SCENE,
      OPEN_SCENE,
      SAVE_SCENE,

      RUN_PLAY,
      RUN_PAUSE,
      RUN_STOP,

      BUILD,
      RECODE,
      CLEANUP,
      RESCAN,
      REBUILD_THIRD_PARTY,

      RESET_WINDOW_LAYOUT,
      OPEN_LAZARUS,

      RESET_CAMERA,
      FOCUS_SELECTED,

      OPEN_PROJECT_DIRECTORY,
      OPEN_PROJECT_CONFIGURATION,

      VIEW_FRONT,
      VIEW_UP,
      VIEW_LEFT,

      VIEW_BACK,
      VIEW_DOWN,
      VIEW_RIGHT,

      TOOL_TRANSLATE,
      TOOL_ROTATE,
      TOOL_SCALE,

      SCENE_CLEAR,
      SCENE_DEFAULT,
      SCENE_SCREENSHOT: TEventID;
   end;

IMPLEMENTATION

END.
