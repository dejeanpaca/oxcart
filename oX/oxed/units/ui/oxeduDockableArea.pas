{
   oxeduDockableArea, oxed base unit
   Copyright (C) 201/. Dejan Boras

   Started On:    29.05.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduDockableArea;

INTERFACE

   USES
      appuActionEvents,
      {ui}
      uiuDockableWindow, uiuWindow, uiuWindowTypes,
      {oxed}
      uOXED, oxeduActions, oxeduSceneEdit, oxeduSceneHierarchy, oxeduMessagesWindow, oxeduProblemsWindow,
      oxeduInspectorWindow, oxeduProjectBrowser, oxeduGameView, oxeduWindow;

TYPE

   { oxedTDockableAreaWindow }

   oxedTDockableAreaWindow = class(uiTDockableArea)
      procedure DeInitialize; override;
   end;

   { oxedTDockableArea }

   oxedTDockableArea = record
      procedure Initialize();
      procedure SetupLayout();
   end;

VAR
   oxedDockableArea: oxedTDockableArea;

IMPLEMENTATION

{ oxedTDockableAreaWindow }

procedure oxedTDockableAreaWindow.DeInitialize;
begin
   inherited DeInitialize;

   oxed.DockableArea := nil;
end;

{ oxedTDockableArea }

procedure oxedTDockableArea.Initialize;
begin
   SetupLayout();
end;

procedure oxedTDockableArea.SetupLayout;
begin
   if(oxed.DockableArea <> nil) then
      uiWindow.Dispose(uiTWindow(oxed.DockableArea));

   uiWindow.Create.Instance := oxedTDockableAreaWindow;
   oxed.DockableArea := uiDockableWindow.CreateDockableArea();

   {setup windows again}
   oxedSceneEdit.CreateWindow().Dock();
   oxedSceneHierarchy.CreateWindow().DockLeft(oxed.DockableArea, 0.2);
   oxedMessagesWindow.CreateWindow().DockDown(oxed.DockableArea, 0.2);

   oxedProblemsWindow.CreateWindow().TabTo(oxedMessagesWindow.Instance);
   oxedMessagesWindow.Instance.Select();

   oxedInspector.CreateWindow().DockUp(
      oxedProjectBrowser.CreateWindow().DockRight(oxed.DockableArea, 0.2));

   oxedGameView.CreateWindow().DockCenter(oxedSceneEdit.Instance);

   {select default window}
   oxedWindow.Find(oxedTSceneEditWindow).Select();
end;

procedure resetLayout();
begin
   oxedDockableArea.SetupLayout();
end;

INITIALIZATION
   oxedActions.RESET_WINDOW_LAYOUT := appActionEvents.SetCallback(@resetLayout);

END.
