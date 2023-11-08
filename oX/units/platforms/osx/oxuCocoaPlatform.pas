{
   oxuCocoaPlatform, osx cocoa specific functionality
   Copyright (c) 2017. Dejan Boras

   Started On:    31.12.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuCocoaPlatform;

INTERFACE

   USES uStd,
   {app}
   appuMouse,
   {oX}
   oxuWindowTypes, {%H-}oxuWindow, oxuWindows, oxuPlatform, oxuPlatforms,
   oxuRenderer,
   {ui}
   uiuTypes, uiuWindow, uiuWindowTypes;

TYPE
   cocoaTWindow = class(oxTWindow)
      wd: record
        LastError: longint;
      end;
   end;

   { TCocoaPointerDriver }

   TCocoaPointerDriver = class(appTPointerDriver)
      constructor Create();

      procedure getXY({%H-}devID: longint; wnd: pointer; out x, y: single); override;
      procedure setXY({%H-}devID: longint; wnd: pointer; x, y: single); override;
      procedure grab({%H-}devID: longint; wnd: pointer); override;
      procedure release({%H-}devID: longint; {%H-}wnd: pointer); override;
      procedure hide({%H-}devID: longint; {%H-}wnd: pointer); override;
      procedure show({%H-}devID: longint; {%H-}wnd: pointer); override;
      function ButtonState({%H-}devID: longint; {%H-}wnd: pointer): longword; override;
   end;

   { TCocoaPlatform }

   TCocoaPlatform = class(oxTPlatform)
      constructor Create(); override;

      function MakeWindow(wnd: oxTWindow): boolean; override;
      function DestroyWindow(wnd: oxTWindow): boolean; override;
      procedure ProcessEvents(); override;

      function Initialize(): boolean; override;
      function DeInitialize(): boolean; override;

      function TitleHeight(wnd: oxTWindow): longint; override;
      function FrameWidth(wnd: oxTWindow): longint; override;
      function FrameHeight(wnd: oxTWindow): longint; override;

      procedure ShowWindow(wnd: oxTWindow); override;
      procedure HideWindow(wnd: oxTWindow); override;

      procedure OutClientAreaCoordinates(wnd: oxTWindow; out x, y: single); override;

      function Fullscreen(x, y, bpp: longint): boolean; override;
      function Fullscreen(window: oxTWindow): boolean; override;
      function LeaveFullscreen(window: oxTWindow): boolean; override;

      procedure Move(wnd: oxTWindow; x, y: longint); override;
      procedure Resize(wnd: oxTWindow; w, h: longint); override;

      procedure Maximize(wnd: oxTWindow); override;
      procedure Minimize(wnd: oxTWindow); override;
      procedure Restore(wnd: oxTWindow); override;

      function MessageBox(wParent: uiTWindow;
         const Title, Say: string; Style: uiTMessageBoxStyle; Buttons: longword): longword; override;

      procedure LoadCursor(cursorType: uiTCursorType); override;
      procedure SetCursor(cursorType: uiTCursorType); override;
   end;

IMPLEMENTATION

{ MOUSE HANDLER }
function winmGetX(): longint;
begin
   Result := 0;
end;

function winmGetY(): longint;
begin
   Result := 0;
end;

procedure winmSetXY(x, y: longint);
begin
end;

procedure winmHide();
begin
end;


{ POINTER DRIVER }

{ TCocoaPointerDriver }

constructor TCocoaPointerDriver.Create();
begin
   Name := 'cocoa'
end;

procedure TCocoaPointerDriver.GetXY(devID: longint; wnd: pointer; out x, y: single);
begin
end;

procedure TCocoaPointerDriver.SetXY(devID: longint; wnd: pointer; x, y: single);
begin
end;

procedure TCocoaPointerDriver.Grab(devID: longint; wnd: pointer);
begin
end;

procedure TCocoaPointerDriver.Release(devID: longint; wnd: pointer);
begin
end;

procedure TCocoaPointerDriver.Show(devID: longint; wnd: pointer);
begin
end;

procedure TCocoaPointerDriver.Hide(devID: longint; wnd: pointer);
begin
end;

function TCocoaPointerDriver.ButtonState(devID: longint; wnd: pointer): longword;
begin
   result := 0;
end;

{ TCocoaPlatform }

constructor TCocoaPlatform.Create();
begin
   inherited;

   Name := 'cococa';
end;

function TCocoaPlatform.MakeWindow(wnd: oxTWindow): boolean;
begin
   Result := false;
end;

function TCocoaPlatform.DestroyWindow(wnd: oxTWindow): boolean;
begin
   Result := false;
end;

procedure TCocoaPlatform.ProcessEvents();
begin
end;

function TCocoaPlatform.Initialize(): boolean;
begin
   Result := inherited;

      { pointer driver }
   PointerDriver := TX11PointerDriver.Create();
end;

function TCocoaPlatform.DeInitialize(): boolean;
begin
   result := true;
end;

function TCocoaPlatform.TitleHeight(wnd: oxTWindow): longint;
begin
   Result := 0;
end;

function TCocoaPlatform.FrameWidth(wnd: oxTWindow): longint;
begin
   Result := 0;
end;

function TCocoaPlatform.FrameHeight(wnd: oxTWindow): longint;
begin
   Result := 0;
end;

procedure TCocoaPlatform.ShowWindow(wnd: oxTWindow);
begin
end;

procedure TCocoaPlatform.HideWindow(wnd: oxTWindow);
begin
end;

procedure TCocoaPlatform.OutClientAreaCoordinates(wnd: oxTWindow; out x, y: single);
begin
end;

function TCocoaPlatform.Fullscreen(x, y, bpp: longint): boolean;
begin
   Result := false;
end;

function TCocoaPlatform.Fullscreen(window: oxTWindow): boolean;
begin
   Result := false;
end;

function TCocoaPlatform.LeaveFullscreen(window: oxTWindow): boolean;
begin
   Result := false;
end;

procedure TCocoaPlatform.Move(wnd: oxTWindow; x, y: longint);
begin
end;

procedure TCocoaPlatform.Resize(wnd: oxTWindow; w, h: longint);
begin
end;

procedure TCocoaPlatform.Maximize(wnd: oxTWindow);
begin
end;

procedure TCocoaPlatform.Minimize(wnd: oxTWindow);
begin
end;

procedure TCocoaPlatform.Restore(wnd: oxTWindow);
begin
end;

function TCocoaPlatform.MessageBox(wParent: uiTWindow; const Title, Say: string;
   Style: uiTMessageBoxStyle; Buttons: longword): longword;
begin
   result := 0;
end;

procedure TCocoaPlatform.LoadCursor(cursorType: uiTCursorType);
begin
end;

procedure TCocoaPlatform.SetCursor(cursorType: uiTCursorType);
begin
end;

INITIALIZATION
   { platform }
   oxPlatforms.Register(TCocoaPlatform);

   appm.SetDriver(appTPointerDriver(cocoaPointerDriver));

FINALIZATION
   FreeObject(cocoaPointerDriver);

END.
