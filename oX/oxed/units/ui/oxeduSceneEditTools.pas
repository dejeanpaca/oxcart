{
   oxeduSceneEdit, oxed scene edit window
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneEditTools;

INTERFACE

   USES
      uStd, vmVector,
      {app}
      appuActionEvents,
      {ox}
      oxuScene, oxuEntity,
      {widgets}
      wdguToolbar,
      {oxed}
      uOXED, oxeduToolbar, oxeduActions, oxeduSceneEdit, oxeduEntities, oxeduDefaultScene, oxeduScene;


IMPLEMENTATION

procedure selectTool(tool: oxedTSceneEditTool);
var
   wnd: oxedTSceneEditWindow;

begin
   wnd := oxedTSceneEditWindow(oxedSceneEdit.Instance);

   if(wnd <> nil) then begin
      wnd.CurrentTool := tool;
      wnd.ToolChanged();
   end;
end;

procedure selectButton(button: wdgPToolbarItem);
begin
   if(button <> nil) then begin
      oxedToolbar.Buttons.Translate^.Activate(false);
      oxedToolbar.Buttons.Rotate^.Activate(false);
      oxedToolbar.Buttons.Scale^.Activate(false);

      button^.Activate(true);
   end;
end;

procedure selectTranslate();
begin
   selectTool(OXED_SCENE_EDIT_TOOL_TRANSLATE);
   selectButton(oxedToolbar.Buttons.Translate);
end;

procedure selectRotate();
begin
   selectTool(OXED_SCENE_EDIT_TOOL_ROTATE);
   selectButton(oxedToolbar.Buttons.Rotate);
end;

procedure selectScale();
begin
   selectTool(OXED_SCENE_EDIT_TOOL_SCALE);
   selectButton(oxedToolbar.Buttons.Scale);
end;

procedure clearScene();
begin
   oxScene.Empty();
   oxed.OnSceneChange.Call();
end;

procedure defaultScene();
begin
   oxedDefaultScene.Create();
   oxed.OnSceneChange.Call();
end;

procedure focusSelected();
var
   wnd: oxedTSceneEditWindow;
   entity: oxTEntity;

begin
   wnd := oxedTSceneEditWindow(oxedSceneEdit.LastSelected);

   if(wnd <> nil) then begin
      entity := oxedScene.SelectedEntity;

      if(entity <> nil) then begin
         {set camera target}
         wnd.Camera.vTarget := entity.vPosition;

         {set camera position}
         wnd.Camera.vPos := wnd.Camera.vTarget - (wnd.Camera.vView * 10.0);
      end;
   end;
end;

INITIALIZATION
   oxedActions.SCENE_CLEAR := appActionEvents.SetCallback(@clearScene);
   oxedActions.SCENE_DEFAULT := appActionEvents.SetCallback(@defaultScene);
   oxedActions.FOCUS_SELECTED := appActionEvents.SetCallback(@focusSelected);

   oxedActions.TOOL_TRANSLATE := appActionEvents.SetCallback(@selectTranslate);
   oxedActions.TOOL_ROTATE := appActionEvents.SetCallback(@selectRotate);
   oxedActions.TOOL_SCALE := appActionEvents.SetCallback(@selectScale);

END.
