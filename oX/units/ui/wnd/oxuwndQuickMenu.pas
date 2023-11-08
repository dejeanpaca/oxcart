{
   oxuwndQuickMenu, oX Quick Menu Window
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndQuickMenu;

INTERFACE

   USES
      {app}
      appuActionEvents, appuKeys,
      {oX}
      oxuTypes, oxuwndAbout, oxuwndSettings, oxuWindowTypes, oxuGlobalKeys,
      {ui}
      oxuUI, uiuTypes, uiuWindow, uiuWidget, uiWidgets, uiuWindowTypes, uiuControl,
      {widgets}
      wdguInputBox, wdguButton;

TYPE

   { oxTQuickMenuWindow }

   oxTQuickMenuWindow = record
     wnd: uiTwindow;
     wndID: uiTControlID;

     UseWindow: uiTWindow;

     DoDestroy,
     DoCreateWidgets,
     IncludeAbout,
     IncludeSettings: boolean;

     Dimensions: oxTDimensions;
     ButtonHeight,
     ButtonSpacing: longint;

     CreateWidgets: procedure(var wnd: uiTWindow);

     wdgID: record
       QUIT,
       CLOSE,
       ABOUT,
       SETTINGS: uiTControlID;
     end;

     {opens the quick menu window}
     procedure Open();
     {closes the quick menu window}
     class procedure Close(); static;
     {toggle the quick menu}
     procedure Toggle();

     private
     procedure AddWidgets();
     procedure CreateWindow();
   end;

VAR
   oxwndQuickMenu: oxTQuickMenuWindow;

IMPLEMENTATION

procedure oxTQuickMenuWindow.AddWidgets();
var
   wdg: uiTWidget;
   dim: oxTDimensions;

   y: longint = 0;

procedure setupWidget();
begin
   wdg.SetPosition(wdgPOSITION_HORIZONTAL_LEFT).
      SetSize(wdgWIDTH_MAX_HORIZONTAL);
end;

begin
   {add the label}
   if(CreateWidgets <> nil) then
      CreateWidgets(wnd);

   if(DoCreateWidgets) then begin
      dim.w := 90;
      dim.h := ButtonHeight;

      y := ButtonSpacing;

      if(IncludeSettings) then begin
         wdg := wdgButton.Add('Settings', oxPoint(25, y * 4), dim, @oxwndSettings.Open).
            SetID(wdgID.SETTINGS);

         setupWidget();
      end;

      if(IncludeAbout) then begin
         wdg := wdgButton.Add('About', oxPoint(25, y * 3), dim, @oxwndAbout.Open).
            SetID(wdgID.ABOUT);

         setupWidget();
      end;

      wdg := wdgButton.Add('Quit', oxPoint(25, y * 2), dim, appACTION_QUIT).
         SetID(wdgID.QUIT);

      setupWidget();

      wdg := wdgButton.Add('Close', oxPoint(25, y), dim, @Close).
         SetID(wdgID.CLOSE);

      setupWidget();
   end;
end;

procedure oxTQuickMenuWindow.CreateWindow();
var
   x, y: longint;
   uiwnd: uiTWindow;

begin
   oxui.SetUseWindow(useWindow);
   uiwnd := oxui.GetUseWindow();

   {position the window}
   x := 10;
   y := uiwnd.Dimensions.h - 30;

   {create the window}
   uiWindow.Create.Buttons := uiwbCLOSE;
   wnd := uiWindow.MakeChild(uiwnd, 'Menu',
      oxPoint(x, y), dimensions, nil).SetID(wndID);

   if(wnd <> nil) then
      {add widgets}
      AddWidgets();
end;

procedure oxTQuickMenuWindow.Open();
begin
   if(wnd = nil) then
      CreateWindow();

   wnd.Open();

   {select the window}
   wnd.Select();
end;

class procedure oxTQuickMenuWindow.Close();
begin
   if(oxwndQuickMenu.wnd <> nil) then begin
      if(oxwndQuickMenu.doDestroy) then
         uiWindow.DisposeQueue(oxwndQuickMenu.wnd)
      else
         oxwndQuickMenu.wnd.Close();
   end;
end;

procedure oxTQuickMenuWindow.Toggle();
begin
   if(wnd.IsVisible()) then begin
      Close();
   end else
      Open();
end;

procedure gkHandler({%H-}wnd: oxTWindow);
begin
   oxwndQuickMenu.Open();
end;

CONST
   qmgkHandler: oxTGlobalKeyHandler = (
      Key: (
         Code: kcF10;
         State: 0
      );
      Pressed: nil;
      Released: @gkHandler;
      Name: 'ox.quickmenu'
   );


INITIALIZATION
   oxwndQuickMenu.wndID := uiControl.GetID('ox.quickmenu');

   oxwndQuickMenu.wdgID.QUIT  := uiControl.GetID('ox.quickmenu.quit');
   oxwndQuickMenu.wdgID.CLOSE := uiControl.GetID('ox.quickmenu.close');
   oxwndQuickMenu.wdgID.ABOUT := uiControl.GetID('ox.quickmenu.about');
   oxwndQuickMenu.wdgID.SETTINGS := uiControl.GetID('ox.quickmenu.settings');

   oxwndQuickMenu.Dimensions.w   := 200;
   oxwndQuickMenu.Dimensions.h   := 240;
   oxwndQuickMenu.ButtonHeight   := 24;
   oxwndQuickMenu.ButtonSpacing  := 25;
   oxwndQuickMenu.DoCreateWidgets := true;
   oxwndQuickMenu.IncludeAbout    := true;
   oxwndQuickMenu.IncludeSettings := true;

   oxGlobalKeys.Hook(qmgkHandler);
END.

