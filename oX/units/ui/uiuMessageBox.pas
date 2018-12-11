{
   uiuMessageBox, message boxes
   Copyright (C) 2011. Dejan Boras

   Started On:    26.04.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuMessageBox;

INTERFACE

   USES

      uStd, uColors,
      {oX}
      oxuWindows, oxuTypes, oxuWindow, oxuWindowTypes, oxuPlatform, oxuFont,
      {ui}
      oxuUI, uiuWindowTypes, uiuWindow, uiuTypes, uiuSurface, uiuWidget, uiuControl, uiuDraw,
      {widgets}
      uiWidgets, wdguButton, wdguCheckbox, wdguLabel, wdguEmpty, wdguInputBox;

TYPE

   { uiTMessageBoxData }

   uiTMessageBoxData = record
      What,
      Button: longword;
      Input: String;

      Window: uiTWindow;

      class procedure Init(out data: uiTMessageBoxData); static;
   end;

   uiTMessageBoxNotifyRoutine = procedure(var data: uiTMessageBoxData);

   uiPMessageBoxProperties = ^uiTMessageBoxProperties;
   uiTMessageBoxProperties = record
      Style: uiTMessageBoxStyle;
      Buttons,
      Properties: longword;
      Parent: uiTWindow;
      Notify: uiTMessageBoxNotifyRoutine;
   end;

   { uiTMessageBoxSurfaceWindow }

   uiTMessageBoxSurfaceWindow = class(uiTWindow)
      msgBox: uiTWindow;
   end;

   { uiTMessageBoxWindow }

   uiTMessageBoxWindow = class(uiTWindow)
      {external data}
      External: TObject;

      msgBox: record
         Style: uiTMessageBoxStyle;
         Buttons,
         Properties: longword;
         Notify: uiTMessageBoxNotifyRoutine;

         What,
         ButtonResult: longword;

         {internal}
         SurfaceWnd: uiTMessageBoxSurfaceWindow;

         wdg: record
            Input: wdgTInputBox;
            Buttons: array[0..uimbcNBUTTONS - 1] of wdgTButton;
         end;
      end;

      procedure OnDeactivate; override;
      procedure OnClose(); override;

   protected
      IsDone: boolean;
   end;

   { uiTMessageBoxGlobal }

   uiTMessageBoxGlobal = record
      SurfaceZ,
      BoxZ: loopint;

      {window class used as the message box window}
      WindowType: uiTWindowClass;

      {NOTE: The DONTSHOWAGAIN check-box, and some other things are not available with
      the system message box functionality.}

      {uses system provided message box functionality}
      class function System(wParent: uiTWindow; const title, say: string;
         style: uiTMessageBoxStyle; Buttons: longword): longword; static;

      {displays a message box}
      class function Show(wParent: uiTWindow; const title, say: string;
         style: uiTMessageBoxStyle; buttons, properties: longword; notification: uiTMessageBoxNotifyRoutine): uiTMessageBoxWindow; static;
      class function Show(const Title, Say: string;
         style: uiTMessageBoxStyle; buttons, properties: longword; notification: uiTMessageBoxNotifyRoutine): uiTMessageBoxWindow; static;
      class function Show(wParent: uiTWindow; const title, say: string;
         style: uiTMessageBoxStyle; buttons, properties: longword): uiTMessageBoxWindow; static;
      class function Show(const title, say: string;
         style: uiTMessageBoxStyle; buttons: longword; properties: longword = uimbpDEFAULT): uiTMessageBoxWindow; static;
      class function Show(const title, say: string; var props: uiTMessageBoxProperties): uiTMessageBoxWindow; static;
      {show an input box}
      class function ShowInput(const title, say: String; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow; static;

      class function ShowWarning(const title, say: string; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow; static;
      class function ShowCritical(const title, say: string; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow; static;
      class function ShowError(const title, say: string; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow; static;

      {initializes a message box properties record}
      class procedure Init(out props: uiTMessageBoxProperties); static;
   end;

VAR
   uiMessageBox: uiTMessageBoxGlobal;

IMPLEMENTATION

{widget IDs}
VAR
   WDGID_TEXT,
   WDGID_INPUT,
   WDGID_DONTSHOWAGAIN,

   {buttons}
   WDGID_OK,
   WDGID_CANCEL,
   WDGID_YES,
   WDGID_NO,
   WDGID_RETRY,
   WDGID_IGNORE,
   WDGID_ABORT,

   WNDID_MSGBOX,
   WNDID_MSGBOX_SURFACE: uiTControlID;

TYPE
   TButtonDescriptor = record
      sCaption: string;
      wdgID: uiPControlID;
   end;

   { wdgTMessageBoxIcon }

   wdgTMessageBoxIcon = class(uiTWidget)
      Style: uiTMessageBoxStyle;

      constructor Create; override;

      procedure Render; override;
   end;


CONST
   BTN_HEIGHT = 24;
   INPUT_HEIGHT = 24;

   ICON_WIDTH = 70;
   ICON_HEIGHT = 70;

   ButtonDescriptors: array[0..uimbcNBUTTONS - 1] of TButtonDescriptor = (
      (
         sCaption: 'OK'; 
         wdgID: @WDGID_OK
      ),
      (
         sCaption: 'Cancel'; 
         wdgID: @WDGID_CANCEL
      ),
      (
         sCaption: 'Yes'; 
         wdgID: @WDGID_YES
      ),
      (
         sCaption: 'No'; 
         wdgID: @WDGID_NO
      ),
      (
         sCaption: 'Retry'; 
         wdgID: @WDGID_RETRY
      ),
      (
         sCaption: 'Ignore'; 
         wdgID: @WDGID_IGNORE
      ),
      (
         sCaption: 'Abort'; 
         wdgID: @WDGID_ABORT
      )
   );

procedure DoneMsgBox(wnd: uiTMessageBoxWindow);
var
   data: uiTMessageBoxData;

begin
   if(not wnd.IsDone) then
      wnd.IsDone := true
   else
      exit;

   uiTMessageBoxData.Init(data);

   data.What := wnd.msgBox.What;
   data.Button := wnd.msgBox.ButtonResult;
   if(wnd.msgBox.wdg.Input <> nil) then
      data.Input := wnd.msgBox.wdg.Input.GetText();

   data.Window := wnd;

   if(wnd.msgBox.Notify <> nil) then
      wnd.msgBox.Notify(data);

   uiWindow.DisposeQueue(uiTWindow(wnd.msgBox.SurfaceWnd));
   uiWindow.DisposeQueue(uiTWindow(wnd));
end;

function wdgControl(wdg: uiTWidget; what: longword): longint;
var
   i: longint;

begin
   Result := -1;

   {if clicked one of the buttons}
   if(wdg.wdgClass^.cID = wdgButton.internal.cID) then begin
      if(what = wdghBUTTON_CLICKED) then begin
         for i := 0 to (uimbcNBUTTONS - 1) do begin
            if(wdg = ButtonDescriptors[i].wdgID^) then begin
               uiTMessageBoxWindow(wdg.wnd).msgBox.What := uimbcWHAT_BUTTON;
               uiTMessageBoxWindow(wdg.wnd).msgBox.ButtonResult := 1 shl (i);
               break;
            end;
         end;

         uiTMessageBoxWindow(wdg.wnd).Close();
      end;
   end;
end;

procedure MsgBoxWidgets(var wnd: uiTMessageBoxWindow; const say: string; style: uiTMessageBoxStyle; buttons, properties: longword);
var
   i,
   nButtons,
   w, x, y: loopint;

   labelWidget: wdgTLabel;

procedure DetermineDimensions();
begin
   y := BTN_HEIGHT + wdgDEFAULT_SPACING;
   w := ((wnd.Dimensions.w - 8) div nButtons) - 4;
   x := wdgDEFAULT_SPACING;
end;

procedure  AddButton();
begin
end;

procedure addButtons();
var
   i,
   curButton: loopint;
   wdg: wdgTButton;

begin
   curButton := 0;

   for i := 0 to (uimbcNBUTTONS - 1) do begin
      if(buttons and (longword(1) shl i) > 0) then begin
          wdg := wdgTButton(wdgButton.Add(ButtonDescriptors[i].sCaption,
            oxPoint(x, y), oxDimensions(w, BTN_HEIGHT), 0).SetID(ButtonDescriptors[i].wdgID^));

         wnd.msgBox.wdg.Buttons[curButton] := wdg;
         if(nButtons > 0) then begin
            if(curButton = 0) then
               wdg.SetButtonPosition([uiCONTROL_GRID_LEFT])
            else if(curButton = nButtons - 1) then
               wdg.SetButtonPosition([uiCONTROL_GRID_RIGHT])
            else
               wdg.SetButtonPosition([uiCONTROL_GRID_MIDDLE]);
         end;

         inc(x, w);
         inc(curButton);
      end;
   end;
end;

procedure AddCBDontShowAgain();
var
   pWdg: wdgTCheckbox = nil;

begin
   pWdg := wdgTCheckbox(wdgCheckbox.Add('Don''t show this again',
      oxPoint(wdgDEFAULT_SPACING, y + wdgDEFAULT_SPACING + wdgCheckbox.Height)).
      SetID(WDGID_DONTSHOWAGAIN));

   {set the widget as true}
   if(pWdg <> nil) and (properties and uimbpCBDONTSHOWAGAINTRUE > 0) then
      pWdg.Check(true);
end;

procedure AddLabel();
var
   x, h: loopint;

begin
   x := 5;

   if(style <> uimbsNONE) then
      inc(x, ICON_WIDTH + wdgDEFAULT_SPACING * 2);

   h := wnd.Dimensions.h - BTN_HEIGHT - wdgDEFAULT_SPACING * 3;

   if(properties and uimbpINPUT > 0) then
      h := h - INPUT_HEIGHT - wdgDEFAULT_SPACING * 2;

   labelWidget := wdgTLabel(wdgLabel.Add(say,
      oxPoint(x, wnd.Dimensions.h - 1 - wdgDEFAULT_SPACING),
      oxDimensions(wnd.Dimensions.w - wdgDEFAULT_SPACING - x, h),
      true).
      SetID(WDGID_TEXT));

   Include(labelWidget.FontProperties, oxfpCenterVertical);
   Include(labelWidget.FontProperties, oxfpCenterHorizontalTotal);

   labelWidget.Multiline();
end;

procedure AddInput();
var
   h: loopint;

begin
   h := INPUT_HEIGHT;

   wnd.msgBox.wdg.Input := wdgTInputBox(wdgInputBox.Add('',
      oxPoint(wdgDEFAULT_SPACING, labelWidget.BelowOf()),
      oxDimensions(wnd.Dimensions.w - wdgDEFAULT_SPACING * 2, h)).
      SetID(WDGID_TEXT));

   wnd.msgBox.wdg.Input.AutoSetDimensions(True);

   wnd.msgBox.wdg.Input.SetPlaceholder('');
end;


procedure AddIcon();
var
   icon: wdgTMessageBoxIcon;
   y: loopint;

begin
   uiWidget.Create.Instance := wdgTMessageBoxIcon;

   y := labelWidget.Position.y - (labelWidget.Dimensions.h div 2 - ICON_HEIGHT div 2);
   if(properties and uimbpINPUT > 0) then
      y := y + INPUT_HEIGHT;

   icon := wdgTMessageBoxIcon(wdgEmpty.Add(oxPoint(wdgDEFAULT_SPACING, y),
      oxDimensions(ICON_WIDTH, ICON_HEIGHT)));

   icon.Style := style;
end;

begin
   uiWidget.SetTarget(wnd, uiTWidgetControlProc(@wdgControl));

   {let's figure out how many buttons there are}
   nButtons := 0;

   for i := 0 to (uimbcNBUTTONS-1) do begin
      if(buttons and (longword(1) shl i) > 0) then
         inc(nButtons);
   end;

   DetermineDimensions();

   {add the buttons}
   addButtons();

   {add the "Don't show again check-box"}
   if(properties and uimbpCBDONTSHOWAGAIN > 0) then
      AddCBDontShowAgain();

   AddLabel();

   if(properties and uimbpINPUT > 0) then
      AddInput();

   if(style <> uimbsNONE) then
      AddIcon();

   uiWidget.ClearTarget();
end;

function instanceWindow(): uiTWindow;
begin
   Result := uiTMessageBoxWindow.Create();
end;

function CreateMsgBoxWnd(wParent: uiTWindow; const title, say: string; style: uiTMessageBoxStyle; buttons, properties: longword): uiTMessageBoxWindow;
var
   wnd: uiTWindow = nil;
   dimensions: oxTDimensions;

begin
   Result := nil;

   dimensions.w := 480;
   dimensions.h := 200;

   if(style <> uimbsNONE) then
      inc(dimensions.w, wdgDEFAULT_SPACING * 2 + ICON_WIDTH);

   if(properties and uimbpINPUT > 0) then
      dimensions.h := 240;

   wParent := oxWindow.Current;

   {create the window}
   uiWindow.Create.Frame := uiwFRAME_STYLE_DIALOG;
   uiWindow.Create.ZIndex := uiMessageBox.BoxZ;
   uiWindow.Create.Buttons := uiwbCLOSE;
   uiWindow.Create.Instance := uiMessageBox.WindowType;

   Include(uiWindow.Create.Properties, uiwndpAUTO_CENTER);
   uiWindow.Create.Properties.Immovable();

   wnd := uiWindow.MakeChild(wParent, title,
      oxNullPoint,
      dimensions).SetID(WNDID_MSGBOX);

   uiMessageBox.WindowType := uiTMessageBoxWindow;

   if(wnd <> nil) and (wnd.ErrorCode = 0) then
      MsgBoxWidgets(uiTMessageBoxWindow(wnd), say, style, buttons, properties);

   Result := uiTMessageBoxWindow(wnd);
end;

{ uiTMessageBoxData }

class procedure uiTMessageBoxData.Init(out data: uiTMessageBoxData);
begin
   ZeroOut(data, SizeOf(data));
end;

{ uiTMessageBoxWindow }

procedure uiTMessageBoxWindow.OnDeactivate;
begin
   if(oxui.Select.GetSelectedWnd() = msgBox.SurfaceWnd) then
      Select();
end;

procedure uiTMessageBoxWindow.OnClose();
begin
   DoneMsgBox(uiTMessageBoxWindow(wnd));
end;

{ wdgTMessageBoxIcon }

constructor wdgTMessageBoxIcon.Create;
begin
   inherited Create;
end;

procedure wdgTMessageBoxIcon.Render;
var
   f: oxTFont;
   scale: Single;
   scolor: TColor4ub;
   symbol: string;

begin
   f := CachedFont;
   scale := (ICON_HEIGHT div 2) / f.GetHeight();

   scolor := cWhite4ub;;

   symbol := 'o';
   if (Style = uimbsNOTIFICATION) then
      symbol := 'i'
   else if (Style = uimbsQUESTION) then
      symbol := '?'
   else if (Style = uimbsWARNING) then begin
      scolor.Assign(255, 255, 0, 255);
      symbol := '!';
   end else if(Style = uimbsCRITICAL) then begin
      symbol := 'X';
      scolor := cRed4ub;
   end;

   SetColor(scolor);
   uiDraw.Rect(RPosition, Dimensions);

   SetColorBlended(scolor);
   f.Start();
      f.Scale(scale, scale);
      f.Write(RPosition.x + Dimensions.w / 2 - f.GetWidth(), RPosition.y - (Dimensions.h / 2 + (f.GetHeight() * scale / 2)), symbol);
      f.Scale(1, 1);
   oxf.Stop();
end;

class function uiTMessageBoxGlobal.System(wParent: uiTWindow; const title, say: string; style: uiTMessageBoxStyle; Buttons: longword): longword;
begin
   Result := oxTPlatform(oxTWindow(wParent.oxwParent).Platform).MessageBox(wParent, title, say, style, Buttons);
end;

class function uiTMessageBoxGlobal.Show(wParent: uiTWindow; const title, say: string;
   style: uiTMessageBoxStyle; buttons, properties: longword; notification: uiTMessageBoxNotifyRoutine): uiTMessageBoxWindow;
var
   msgBoxProps: uiTMessageBoxProperties;

begin
   Init(msgBoxProps);

   msgBoxProps.Style       := style;
   msgBoxProps.Buttons     := buttons;
   msgBoxProps.Properties  := properties;
   msgBoxProps.Parent      := wParent;
   msgBoxProps.Notify      := notification;

   Result := Show(title, say, msgBoxProps);
end;

class function uiTMessageBoxGlobal.Show(const Title, Say: string;
      style: uiTMessageBoxStyle; buttons, properties: longword; notification: uiTMessageBoxNotifyRoutine): uiTMessageBoxWindow;
begin
   Result := Show(nil, Title, Say, style, buttons, properties, notification);
end;

class function uiTMessageBoxGlobal.Show(wParent: uiTWindow; const title, say: string;
   style: uiTMessageBoxStyle; buttons, properties: longword): uiTMessageBoxWindow;
begin
   Result := Show(wParent, title, say, style, buttons, properties, nil);
end;

class function uiTMessageBoxGlobal.Show(const title, say: string;
   style: uiTMessageBoxStyle; buttons: longword; properties: longword): uiTMessageBoxWindow;
begin
   Result := Show(nil, title, say, style, buttons, properties, nil);
end;

class function uiTMessageBoxGlobal.Show(const title, say: string; var props: uiTMessageBoxProperties): uiTMessageBoxWindow;
var
   wnd: uiTMessageBoxWindow = nil;
   surface: uiTMessageBoxSurfaceWindow;
   buttonResult: longword;
   data: uiTMessageBoxData;

begin
   {system message-box functionality}
   if(props.properties and uimbpSYSTEM > 0) then begin
      buttonResult := System(props.parent, title, say, props.style, props.buttons);

      uiTMessageBoxData.Init(data);
      data.What := uimbcWHAT_BUTTON;
      data.Button := buttonResult;

      if(props.Notify <> nil) then
         props.Notify(data);
   {provide an own message-box}
   end else begin
      wnd := CreateMsgBoxWnd(props.parent, title, say, props.Style, props.Buttons, props.properties);

      if(wnd <> nil) then begin
         wnd.msgBox.Style       := props.Style;
         wnd.msgBox.Properties  := props.Properties;
         wnd.msgBox.Buttons     := props.Buttons;
         wnd.msgBox.Notify      := props.Notify;

         if(props.properties and uimbpSURFACE > 0) then begin
            uiWindow.Create.ZIndex := -uiMessageBox.SurfaceZ;

            uiWindow.Create.Instance := uiTMessageBoxSurfaceWindow;
            surface := uiTMessageBoxSurfaceWindow(uiSurface.Create('MsgBoxSurface'));
            surface.Background.Color.Assign(0, 0, 0, 127);
            surface.msgBox := wnd;
            wnd.msgBox.SurfaceWnd := surface;
         end;

         wnd.Select();
      end;
   end;

   Result := wnd;
end;

class function uiTMessageBoxGlobal.ShowInput(const title, say: String; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow;
begin
   Result := uiMessageBox.Show(title, say, uimbsNOTIFICATION, uimbcOK_CANCEL, uimbpDEFAULT or uimbpINPUT, notify);
end;

class function uiTMessageBoxGlobal.ShowWarning(const title, say: string; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow;
begin
   Result := Show(title, say, uimbsWARNING, uimbcOK, uimbpDEFAULT, notify);
end;

class function uiTMessageBoxGlobal.ShowCritical(const title, say: string; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow;
begin
   Result := Show(title, say, uimbsCRITICAL, uimbcOK, uimbpDEFAULT, notify);
end;

class function uiTMessageBoxGlobal.ShowError(const title, say: string; notify: uiTMessageBoxNotifyRoutine = nil): uiTMessageBoxWindow;
begin
   Result := Show(title, say, uimbsCRITICAL, uimbcOK, uimbpDEFAULT, notify);
end;

class procedure uiTMessageBoxGlobal.Init(out props: uiTMessageBoxProperties);
begin
   ZeroOut(props, SizeOf(props));
end;


INITIALIZATION
   uiMessageBox.SurfaceZ := 1000;
   uiMessageBox.BoxZ := 1001;
   uiMessageBox.WindowType := uiTMessageBoxWindow;

   WDGID_TEXT           := uiControl.GetID('TEXT');
   WDGID_INPUT          := uiControl.GetID('INPUT');
   WDGID_DONTSHOWAGAIN  := uiControl.GetID('DONTSHOWAGAIN');

   {buttons}
   WDGID_OK             := uiControl.GetID('OK');
   WDGID_CANCEL         := uiControl.GetID('CANCEL');
   WDGID_YES            := uiControl.GetID('YES');
   WDGID_NO             := uiControl.GetID('NO');
   WDGID_RETRY          := uiControl.GetID('RETRY');
   WDGID_IGNORE         := uiControl.GetID('IGNORE');
   WDGID_ABORT          := uiControl.GetID('ABORT');

   {window}
   WNDID_MSGBOX         := uiControl.GetID('MsgBox');
   WNDID_MSGBOX_SURFACE := uiControl.GetID('MsgBoxSurface');
END.
