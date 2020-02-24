{
   oxuOXEDPlatform
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuOXEDPlatform;

INTERFACE

   USES 
   uStd, StringUtils, uLog,
   {app}
   appuEvents, appuKeys, appuKeyEvents, appuMouse, appuMouseEvents, oxuGlobalInstances,
   {oX}
   oxuTypes, oxuWindowTypes, {%H-}oxuWindow, oxuWindows, oxuPlatform, oxuRenderer,
   {ui}
   uiuTypes, uiuWindow, uiuWindowTypes;

VAR
   oxedPointerDriver: appTPointerDriver;

IMPLEMENTATION

TYPE
   { TOXEDPointerDriver }

   TOXEDPointerDriver = class(appTPointerDriver)
      constructor Create();

      procedure GetXY({%H-}devID: longint; wnd: pointer; out x, y: single); override;
      procedure SetXY({%H-}devID: longint; wnd: pointer; x, y: single); override;
      procedure Grab({%H-}devID: longint; wnd: pointer); override;
      procedure Release({%H-}devID: longint; {%H-}wnd: pointer); override;
      procedure Hide({%H-}devID: longint; {%H-}wnd: pointer); override;
      procedure Show({%H-}devID: longint; {%H-}wnd: pointer); override;
      function ButtonState({%H-}devID: longint; {%H-}wnd: pointer): longword; override;
   end;

   { TOXEDPlatform }

   TOXEDPlatform = class(oxTPlatform)
      constructor Create(); override;

      function Initialize(): boolean; override;
      function DeInitialize(): boolean; override;

      function MessageBox(wParent: uiTWindow;
         const Title, Say: string; Style: uiTMessageBoxStyle; Buttons: longword): longword; override;

      procedure LoadCursor(cursorType: uiTCursorType); override;
      procedure SetCursor(cursorType: uiTCursorType); override;
   end;

VAR
   externalPlatform: oxTPlatform;

{ TWinPointerDriver }

constructor TOXEDPointerDriver.Create();
begin
   Name := 'oxed'
end;

procedure TOXEDPointerDriver.GetXY(devID: longint; wnd: pointer; out x, y: single);
begin
   externalPlatform.PointerDriver.GetXY(devID, wnd, x, y);
end;

procedure TOXEDPointerDriver.SetXY(devID: longint; wnd: pointer; x, y: single);
begin
   externalPlatform.PointerDriver.SetXY(devID, wnd, x, y);
end;

procedure TOXEDPointerDriver.Grab(devID: longint; wnd: pointer);
begin
   externalPlatform.PointerDriver.Grab(devID, wnd);
end;

procedure TOXEDPointerDriver.Release(devID: longint; wnd: pointer);
begin
   externalPlatform.PointerDriver.Release(devID, wnd);
end;

procedure TOXEDPointerDriver.Show(devID: longint; wnd: pointer);
begin
   externalPlatform.PointerDriver.Show(devID, wnd);
end;

procedure TOXEDPointerDriver.Hide(devID: longint; wnd: pointer);
begin
   externalPlatform.PointerDriver.Hide(devID, wnd);
end;

function TOXEDPointerDriver.ButtonState(devID: longint; wnd: pointer): longword;
begin
   Result := externalPlatform.PointerDriver.ButtonState(devID, wnd);
end;

{ TOXEDPlatform }

constructor TOXEDPlatform.Create();
begin
   inherited;

   Name := 'oxed';
   PointerDriver := TOXEDPointerDriver.Create();
end;

function TOXEDPlatform.Initialize(): boolean;
begin
   externalPlatform := oxExternalGlobalInstances.FindInstance('oxTPlatform');
end;

function TOXEDPlatform.DeInitialize(): boolean;
begin
   Result := True;
end;

function TOXEDPlatform.MessageBox(wParent: uiTWindow; const Title, Say: string; Style: uiTMessageBoxStyle; Buttons: longword): longword;
begin
   externalPlatform.MessageBox(wParent, Title, Say, Style, Buttons);
end;

procedure TOXEDPlatform.LoadCursor(cursorType: uiTCursorType);
begin
   externalPlatform.LoadCursor(cursorType);
end;

procedure TOXEDPlatform.SetCursor(cursorType: uiTCursorType);
begin
   externalPlatform.SetCursor(cursorType);
end;

INITIALIZATION
   { platform }
   oxPlatformInstance := TOXEDPlatform;

END.
