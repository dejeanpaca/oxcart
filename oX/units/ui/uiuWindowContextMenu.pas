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
      oxuRunRoutines,
      {ui}
      uiuBase, oxuUI, uiuWindowTypes, uiuWindow, uiuPointerEvents, uiuContextMenu;

TYPE

   { uiTWindowContextMenuWindow }

   uiTWindowContextMenuWindow = class(uiTContextMenuWindow)
      procedure DeInitialize(); override;
   end;

   { uiTWindowContextMenuGlobal }

   uiTWindowContextMenuGlobal = record
      Menu: uiTContextMenu;
      TargetWnd: uiTWindow;

      Items: record
         Minimize,
         Maximize,
         Move,
         Resize,
         Close: uiPContextMenuItem;
      end;
   end;

VAR
   uiWindowContextMenu: uiTWindowContextMenuGlobal;

IMPLEMENTATION

procedure DeInitialize();
begin
   FreeObject(uiWindowContextMenu.Menu);
end;

procedure maximize();
begin
   if(uiWindowContextMenu.TargetWnd <> nil) then
      uiWindowContextMenu.TargetWnd.Maximize();
end;

procedure minimize();
begin
   if(uiWindowContextMenu.TargetWnd <> nil) then
      uiWindowContextMenu.TargetWnd.Minimize();
end;

procedure move();
begin

end;

procedure resize();
begin

end;

procedure close();
begin
   if(uiWindowContextMenu.TargetWnd <> nil) then
      uiWindowContextMenu.TargetWnd.CloseQueue();
end;

procedure openContextWindow(wnd: uiTWindow);
begin
   if(uiWindowContextMenu.Menu = nil) then begin
      uiWindowContextMenu.Menu := uiTContextMenu.Create('Window context menu');

      uiWindowContextMenu.Items.Maximize :=
         uiWindowContextMenu.Menu.AddItem('Maximize', @maximize);

      uiWindowContextMenu.Items.Minimize :=
         uiWindowContextMenu.Menu.AddItem('Minimize', @minimize);

      uiWindowContextMenu.Items.Move :=
         uiWindowContextMenu.Menu.AddItem('Move', @move);
      uiWindowContextMenu.Items.Move^.Disable();

      uiWindowContextMenu.Items.Resize :=
         uiWindowContextMenu.Menu.AddItem('Resize', @resize);
      uiWindowContextMenu.Items.Resize^.Disable();

      uiWindowContextMenu.Items.Close :=
         uiWindowContextMenu.Menu.AddItem('Close', @close);
   end;

   uiContextMenu.Instance := uiTWindowContextMenuWindow;
   uiWindowContextMenu.TargetWnd := wnd;

   uiWindowContextMenu.Items.Move^.Enable((uiwndpMOVABLE in wnd.Properties) and false {TODO: Implement moving});
   uiWindowContextMenu.Items.Resize^.Enable((uiwndpRESIZABLE in wnd.Properties) and false {TODO: Implement resizing});

   uiWindowContextMenu.Items.Minimize^.Enable((not (uiwndpMINIMIZED in wnd.Properties)) and (uiwndpRESIZABLE in wnd.Properties));
   uiWindowContextMenu.Items.Maximize^.Enable((not (uiwndpMAXIMIZED in wnd.Properties)) and (uiwndpRESIZABLE in wnd.Properties));

   uiWindowContextMenu.Menu.Show(wnd);
end;

procedure windowDestroyed(wnd: uiTWindow);
begin
   if(wnd = uiWindowContextMenu.TargetWnd) then
      uiWindowContextMenu.TargetWnd := nil;
end;

{ uiTWindowContextMenuWindow }

procedure uiTWindowContextMenuWindow.DeInitialize();
begin
   inherited DeInitialize();

   uiWindowContextMenu.TargetWnd := nil;
end;

INITIALIZATION
   ui.InitializationProcs.dAdd('ui.window_context_menu', @DeInitialize);
   uiPointerEvents.OpenContextWindow := @openContextWindow;
   uiWindow.OnDestroy.Add(@windowDestroyed);

END.
