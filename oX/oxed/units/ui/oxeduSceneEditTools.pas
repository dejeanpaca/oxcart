{
   oxeduSceneEdit, oxed scene edit window
   Copyright (C) 2016. Dejan Boras

   Started On:    26.12.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneEditTools;

INTERFACE

   USES
      {app}
      appuActionEvents,
      {widgets}
      wdguToolbar,
      {oxed}
      oxeduToolbar, oxeduActions, oxeduSceneEdit;


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

INITIALIZATION
   oxedActions.TOOL_TRANSLATE := appActionEvents.SetCallback(@selectTranslate);
   oxedActions.TOOL_ROTATE := appActionEvents.SetCallback(@selectRotate);
   oxedActions.TOOL_SCALE := appActionEvents.SetCallback(@selectScale);

END.
