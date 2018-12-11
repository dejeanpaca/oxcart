{
   uiwdgButton, button widget for the UI
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT wdguButton;

INTERFACE

   USES
      uStd, uColors,
      {app}
      appuEvents, appuKeys, appuMouse, appuActionEvents,
      {ui}
      oxuTypes, oxuFont,
      {ui}
      uiWidgets, uiuWindowTypes, uiuWidget, uiuWindow, uiuTypes, uiuWidgetRender, uiuControl;

CONST
   wdghBUTTON_CLICKED                     = $0001;

   wdgscBUTTON_REGULAR = 0;
   wdgscBUTTON_REGULAR_DISABLED = 1;
   wdgscBUTTON_HOVER   = 2;

   wdgButtonSkinColorDescriptor: array[0..2] of uiTWidgetSkinColorDescriptor = (
       (
          Name: 'regular';
          Color: (127, 127, 127, 255)
       ),
       (
          Name: 'regular_disabled';
          Color: (32, 32, 32, 255)
       ),
       (
          Name: 'highlight';
          Color: (0, 153, 204, 255)
       )
    );

   wdgButtonSkinDescriptor: uiTWidgetSkinDescriptor = (
      Name: 'button';

      nColors: Length(wdgButtonSkinColorDescriptor);
      nImages: 0;
      nBools: 0;
      nStrings: 0;

      Colors: @wdgButtonSkinColorDescriptor;
      Images: nil;
      Bools: nil;
      Strings: nil;
      Setup: nil
   );

TYPE
   { wdgTButton }

   wdgTButton = class(uiTWidget)
      {is the button being currently pressed}
      Pressed: boolean;
      {associated action event called when button is activated}
      ActionEvent: TEventID;
      {called when button is activated}
      Callback: uiTWidgetCallback;

      ButtonGridPosition: uiTControlGridPosition;

      constructor Create; override;

      procedure Action(what: uiTWidgetEvents); override;
      procedure RenderBase();
      procedure Render(); override;
      procedure Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint); override;
      function Key(var k: appTKeyEvent): boolean;  override;

      procedure GetComputedDimensions(out d: oxTDimensions); override;
      procedure SetButtonPosition(pos: uiTControlGridPosition);

      private
         {curved frame properties}
         CurvedFrameProperties: TBitSet;

      procedure btDo();
   end;

   { uiTWidgetButtonGlobal }

   uiTWidgetButtonGlobal = record
      Internal: uiTWidgetClass;

      function Add(const Caption: string;
                  const Pos: oxTPoint; const Dim: oxTDimensions;
                  ActionEvent: TEventID = 0): wdgTButton;

      function Add(const Caption: string;
                  const Pos: oxTPoint; const Dim: oxTDimensions;
                  callback: TProcedure = nil): wdgTButton;
      function Add(const Caption: string;
                  const Pos: oxTPoint; const Dim: oxTDimensions;
                  callback: TObjectProcedure): wdgTButton;
      function Add(const Caption: string;
                  const Pos: oxTPoint; const Dim: oxTDimensions;
                  callback: uiTWidgetCallbackRoutine): wdgTButton;
      function Add(const Caption: string;
                  const Pos: oxTPoint; const Dim: oxTDimensions;
                  callback: uiTWidgetObjectCallbackRoutine): wdgTButton;

      function Add(const Caption: string;
                  ActionEvent: TEventID = 0): wdgTButton;
   end;

VAR
   wdgButton: uiTWidgetButtonGlobal;

IMPLEMENTATION

procedure wdgTButton.btDo();
begin
   if(wdgpENABLED in Properties) then begin
      {queue an action event if one is assigned}
      if(ActionEvent <> 0) then
         appActionEvents.Queue(ActionEvent, 0, wnd);

      {now we will notify the widget control routine that the button is pressed}
      Control(wdghBUTTON_CLICKED);
   end;

   {clear the pressed state}
   Pressed := false;

   {call the callback last, in case the callback destroys the widget or container}
   if(wdgpENABLED in Properties) then
      Callback.Call(Self);
end;

procedure wdgTButton.Point(var e: appTMouseEvent; {%H-}x, {%H-}y: longint);
begin
   if(wdgpENABLED in Properties) then begin
     {left button is released}
     if(e.Action = appmcRELEASED) and (e.Button = appmcLEFT) then
        btDo()
     {left button pressed}
     else if(e.Action = appmcPRESSED) and (e.Button = appmcLEFT) then
        Pressed := true
   end;
end;

constructor wdgTButton.Create;
begin
   inherited Create;

   SetPadding(8);
   SetBorder(1);
end;

procedure wdgTButton.Action(what: uiTWidgetEvents);
begin
   if(wdgpENABLED in Properties) then begin
     {if the button loses focus(unselected) then reset it to normal state}
      if(what = uiwdgACTION_DEACTIVATE) then
         Pressed := false;
   end;
end;

procedure wdgTButton.RenderBase();
var
   window: uiTWindow;
   renderProperties: TBitSet;
   colors: uiPSkinColorSet;

begin
   window := uiTWindow(wnd);
   colors := GetColorset();

   {render button block}
   renderProperties  := wdgRENDER_BLOCK_SURFACE;
   if(ButtonGridPosition <> []) then begin
      renderProperties := renderProperties or wdgRENDER_CORNERS;
      renderProperties := renderProperties or CurvedFrameProperties;
   end;

   if(not (wdgpHOVERING in Properties)) or (not Pressed) then
      renderProperties.Prop(wdgRENDER_BLOCK_BORDER);

   {if no textures present then render normally}
   if(wdgpENABLED in Properties) then begin
      if(wdgpHOVERING in Properties) or (Pressed) then
         uiRenderWidget.Box(uiTWidget(Self), GetColor(wdgscBUTTON_HOVER), colors^.SelectedBorder, renderProperties, window.opacity)
      else
         uiRenderWidget.Box(uiTWidget(Self), GetColor(wdgscBUTTON_REGULAR), colors^.Border, renderProperties, window.opacity);
   end else
      uiRenderWidget.Box(uiTWidget(Self), GetColor(wdgscBUTTON_REGULAR_DISABLED), colors^.Border, renderProperties, window.opacity)
end;

procedure wdgTButton.Render();
var
   r: oxTRect;
   f: oxTFont;

   window: uiTWindow;

begin
   f := CachedFont;
   window := uiTWindow(wnd);

   RenderBase();

   {render button caption, if any}
   if(Caption <> '') then begin
      GetRelativeRect(r);

      if(f <> nil) then begin
         if(wdgpENABLED in Properties) then
            window.SetColorBlended(window.Skin.Colors.Text)
         else
            window.SetColorBlended(window.Skin.Colors.InactiveText);

         f.Start();
            f.WriteCentered(Caption, r);
         oxf.Stop();
      end;
   end;
end;

function wdgTButton.Key(var k: appTKeyEvent): boolean;
begin
   Result := true;

   if(k.Key.Equal(kcSPACE) or k.Key.Equal(kcENTER)) then begin
      if(k.Key.Released()) then
         btDo();
   end else
      Result := false;
end;

procedure wdgTButton.GetComputedDimensions(out d: oxTDimensions);
var
   f: oxTFont;

begin
   f := CachedFont;

   d.w := f.GetLength(Caption) + PaddingLeft + PaddingTop + Border;
   d.h := f.GetHeight() + PaddingBottom + PaddingTop + Border;
end;

procedure wdgTButton.SetButtonPosition(pos: uiTControlGridPosition);
begin
   ButtonGridPosition := pos;
   CurvedFrameProperties := uiRenderWidget.GetCurvedFrameProperties(pos);
end;

procedure InitWidget();
begin
   wdgButton.Internal.Instance := wdgTButton;
   wdgButton.Internal.skinDescriptor := @wdgButtonSkinDescriptor;
   wdgButton.Internal.Done();
end;

function uiTWidgetButtonGlobal.Add(const Caption: string;
            const Pos: oxTPoint; const Dim: oxTDimensions;
            ActionEvent: TEventID = 0): wdgTButton;
begin
   Result := wdgTButton(uiWidget.Add(Internal, Pos, Dim));

   if(Result <> nil) then begin
      Result.SetCaption(Caption);
      Result.ActionEvent := ActionEvent;

      Result.AutoSize();
   end;
end;

function uiTWidgetButtonGlobal.Add(const Caption: string;
            const Pos: oxTPoint; const Dim: oxTDimensions;
            callback: TProcedure = nil): wdgTButton;
begin
   Result := Add(Caption, Pos, Dim, 0);

   if(Result <> nil) then
      Result.Callback.Use(callback);
end;

function uiTWidgetButtonGlobal.Add(const Caption: string; const Pos: oxTPoint; const Dim: oxTDimensions; callback: TObjectProcedure): wdgTButton;
begin
   Result := Add(Caption, Pos, Dim, 0);

   if(Result <> nil) then
      Result.Callback.Use(callback);
end;

function uiTWidgetButtonGlobal.Add(const Caption: string; const Pos: oxTPoint; const Dim: oxTDimensions; callback: uiTWidgetCallbackRoutine): wdgTButton;
begin
   Result := Add(Caption, Pos, Dim, 0);

   if(Result <> nil) then
      Result.Callback.Use(callback);
end;

function uiTWidgetButtonGlobal.Add(const Caption: string; const Pos: oxTPoint; const Dim: oxTDimensions;
   callback: uiTWidgetObjectCallbackRoutine): wdgTButton;

begin
   Result := Add(Caption, Pos, Dim, 0);

   if(Result <> nil) then
      Result.Callback.Use(callback);
end;

function uiTWidgetButtonGlobal.Add(const Caption: string; ActionEvent: TEventID): wdgTButton;
begin
   Result := Add(Caption, uiWidget.LastRect.BelowOf(), oxNullDimensions, ActionEvent);
end;

INITIALIZATION
   wdgButton.Internal.Register('widget.button', @InitWidget);

END.

