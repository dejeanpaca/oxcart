{
   uiuDockableWindow, dockable ui windows
   Copyright (C) 2016. Dejan Boras

   Started On:    26.12.2016.
}

{$INCLUDE oxdefines.inc}
UNIT uiuDockableWindowContextMenu;

INTERFACE

   USES
      uColors,
      {oX}
      uStd, oxuWindow, oxuRunRoutines,
      {ui}
      uiuBase, uiuWindow, oxuUI, uiuTypes, uiWidgets, uiuWidget,
      uiuContextMenu, uiuDockableWindow, uiuWidgetWindow,
      wdguTabs, wdguBlock;

TYPE
   uiTDockableWindowContextMenuWindow = class(uiTContextMenuWindow)
      TabWidget: wdgTDockableTabs;
      TabIndex: loopint;
   end;

   { uiTDockableWindowContextMenu }

   uiTDockableWindowContextMenu = record
      Menu: uiTContextMenu;
      UseMenu: uiTContextMenu;

      procedure Open(var from: uiTWidgetWindowOrigin; wdg: wdgTDockableTabs; index: loopint);
   end;

VAR
   uiDockableWindowContextMenu: uiTDockableWindowContextMenu;

IMPLEMENTATION

procedure untabWindow(wdg: uiTWidget; {%H-}menu: TObject; {%H-}item: uiPContextMenuItem);
var
   wnd: uiTDockableWindowContextMenuWindow;
   tabWidget: wdgTDockableTabs;

begin
   wnd := uiTDockableWindowContextMenuWindow(wdg.wnd);
   tabWidget := wnd.TabWidget;

   tabWidget.Untab(wnd.TabIndex);
end;

procedure closeTab(wdg: uiTWidget; {%H-}menu: TObject; {%H-}item: uiPContextMenuItem);
var
   wnd: uiTDockableWindowContextMenuWindow;
   tabWidget: wdgTDockableTabs;

begin
   wnd := uiTDockableWindowContextMenuWindow(wdg.wnd);
   tabWidget := wnd.TabWidget;

   tabWidget.CloseTabWindow(wnd.TabIndex);
end;

procedure init();
begin
   uiDockableWindowContextMenu.Menu := uiTContextMenu.Create('Dockable window');

   uiDockableWindowContextMenu.Menu.AddItem('Untab', 0, @untabWindow);
   uiDockableWindowContextMenu.Menu.AddItem('Close', 0, @closeTab);
end;

procedure deinit();
begin
   FreeObject(uiDockableWindowContextMenu.Menu);
end;

procedure openContextMenu(var from: uiTWidgetWindowOrigin; wdg: wdgTDockableTabs; index: loopint);
begin
   uiDockableWindowContextMenu.Open(from, wdg, index);
end;

{ uiTDockableWindowContextMenu }

procedure uiTDockableWindowContextMenu.Open(var from: uiTWidgetWindowOrigin; wdg: wdgTDockableTabs; index: loopint);
var
   openWith: uiTContextMenu;

begin
   if(UseMenu = nil) then
      openWith := Menu
   else
      openWith := UseMenu;

   uiContextMenu.Instance := uiTDockableWindowContextMenuWindow;
   openWith.Show(from);
   uiTDockableWindowContextMenuWindow(uiContextMenu.LastWindow).TabWidget := wdg;
   uiTDockableWindowContextMenuWindow(uiContextMenu.LastWindow).TabIndex := index;
end;

INITIALIZATION
   ui.BaseInitializationProcs.Add('ui.dockable_window', @init, @deinit);

   {self destroy windows by default}
   uiDockableWindow.SelfDestroy := true;
   uiDockableWindow.OpenContextMenu := @openContextMenu;

END.
