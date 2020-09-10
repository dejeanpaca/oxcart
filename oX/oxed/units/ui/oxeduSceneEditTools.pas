{
   oxeduSceneEdit, oxed scene edit window
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
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
      uOXED, oxeduActions, oxeduSceneEdit, oxeduEntities, oxeduDefaultScene, oxeduScene;


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
      button^.Activate(true);

      {TODO: Highlight selected tool}
   end;
end;

procedure selectTranslate();
begin
   selectTool(OXED_SCENE_EDIT_TOOL_TRANSLATE);
end;

procedure selectRotate();
begin
   selectTool(OXED_SCENE_EDIT_TOOL_ROTATE);
end;

procedure selectScale();
begin
   selectTool(OXED_SCENE_EDIT_TOOL_SCALE);
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
         wnd.wdg.SceneRender.Camera.vTarget := entity.vPosition;

         {set camera position}
         wnd.wdg.SceneRender.Camera.vPos :=
            wnd.wdg.SceneRender.Camera.vTarget - (wnd.wdg.SceneRender.Camera.vView * 10.0);
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
