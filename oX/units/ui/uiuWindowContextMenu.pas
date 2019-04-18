{
   uiuWindowContextMenu, window context menu
   Copyright (C) 2019. Dejan Boras

   Started On:    17.04.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuWindowContextMenu;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes, oxuRunRoutines,
      {ui}
      oxuUI, uiuWindowTypes, uiuWindow, uiuPointerEvents, uiuContextMenu;

IMPLEMENTATION

VAR
   windowContextMenu: uiTContextMenu;

procedure DeInitialize();
begin
   FreeObject(windowContextMenu);
end;

procedure openContextWindow(wnd: uiTWindow);
begin
   if(windowContextMenu = nil) then begin
     windowContextMenu := uiTContextMenu.Create('Window context menu');

     windowContextMenu.AddItem('Maximize');
     windowContextMenu.AddItem('Minimize');
     windowContextMenu.AddItem('Move');
     windowContextMenu.AddItem('Resize');
     windowContextMenu.AddItem('Close');
   end;

   windowContextMenu.Show(wnd);
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxui.InitializationProcs.dAdd(initRoutines, 'ui.window_context_menu', @DeInitialize);
   uiPointerEvents.OpenContextWindow := @openContextWindow;

END.
