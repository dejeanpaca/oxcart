{
   oxuPlatform, platform interface
   Copyright (c) 2012. Dejan Boras

   Started On:    21.02.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuPlatform;

INTERFACE

   USES
      appuMouse,
      {ox}
      oxuWindowTypes, oxuGlobalInstances,
      {ui}
      uiuTypes, uiuWindowTypes;

TYPE
   { oxTPlatform }

   oxTPlatform = class
      public
         Name: string;
         {pointer driver used by the platform}
         PointerDriver: appTPointerDriver;

      constructor Create(); virtual;

      function MakeWindow({%H-}wnd: oxTWindow): boolean;  virtual;
      function DestroyWindow({%H-}wnd: oxTWindow): boolean; virtual;
      procedure ProcessEvents(); virtual;

      function Initialize(): boolean; virtual;
      function DeInitialize(): boolean; virtual;

      procedure SetTitle({%H-}wnd: oxTWindow; const {%H-}newTitle: string); virtual;

      function TitleHeight({%H-}wnd: oxTWindow): longint; virtual;
      function FrameWidth({%H-}wnd: oxTWindow): longint; virtual;
      function FrameHeight({%H-}wnd: oxTWindow): longint; virtual;

      procedure ShowWindow({%H-}wnd: oxTWindow); virtual;
      procedure HideWindow({%H-}wnd: oxTWindow); virtual;

      procedure GetClientAreaCoordinates(wnd: oxTWindow; var x, y: single);
      procedure OutClientAreaCoordinates(wnd: oxTWindow; out x, y: single); virtual;

      function Fullscreen(wnd: oxTWindow): boolean; virtual;
      function Fullscreen({%H-}x, {%H-}y, {%H-}bpp: longint): boolean; virtual;
      function LeaveFullscreen({%H-}wnd: oxTWindow): boolean; virtual;

      procedure Move({%H-}wnd: oxTWindow; {%H-}x, {%H-}y: longint); virtual;
      procedure Resize({%H-}wnd: oxTWindow; {%H-}w, {%H-}h: longint); virtual;

      procedure Maximize({%H-}wnd: oxTWindow); virtual;
      procedure Minimize({%H-}wnd: oxTWindow); virtual;
      procedure Restore({%H-}wnd: oxTWindow); virtual;

      procedure ErrorMessageBox(const {%H-}title, {%H-}say: string);
      function MessageBox({%H-}wParent: uiTWindow; const {%H-}Title, {%H-}Say: string;
         {%H-}Style: uiTMessageBoxStyle; {%H-}Buttons: longword): longword; virtual;

      procedure LoadCursor({%H-}cursorType: uiTCursorType); virtual;
      procedure SetCursor({%H-}cursorType: uiTCursorType); virtual;
   end;

   oxTPlatformClass = class of oxTPlatform;

VAR
   oxPlatform: oxTPlatform;

IMPLEMENTATION

procedure setDefaultPlatform();
begin
   oxPlatform := oxTPlatform.Create();
end;

{ oxTPlatform }

constructor oxTPlatform.Create();
begin
   Name := 'default';
end;

function oxTPlatform.MakeWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

function oxTPlatform.DestroyWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

procedure oxTPlatform.ProcessEvents();
begin
end;

function oxTPlatform.Initialize(): boolean;
begin
   Result := true;
end;

function oxTPlatform.DeInitialize(): boolean;
begin
   Result := true;
end;

procedure oxTPlatform.SetTitle(wnd: oxTWindow; const newTitle: string);
begin

end;

function oxTPlatform.TitleHeight(wnd: oxTWindow): longint;
begin
   Result := 0;
end;

function oxTPlatform.FrameWidth(wnd: oxTWindow): longint;
begin
   Result := 0;
end;

function oxTPlatform.FrameHeight(wnd: oxTWindow): longint;
begin
   Result := 0;
end;

procedure oxTPlatform.ShowWindow(wnd: oxTWindow);
begin
end;

procedure oxTPlatform.HideWindow(wnd: oxTWindow);
begin
end;

procedure oxTPlatform.GetClientAreaCoordinates(wnd: oxTWindow; var x, y: single);
var
   nx,
   ny: single;

begin
   OutClientAreaCoordinates(wnd, nx, ny);

   x := x - nx;
   y := wnd.Dimensions.h - 1 - (y - ny);
end;

procedure oxTPlatform.OutClientAreaCoordinates(wnd: oxTWindow; out x, y: single);
begin
   x := wnd.Position.x;
   y := wnd.Position.y;
end;

function oxTPlatform.Fullscreen(wnd: oxTWindow): boolean;
begin
   Result := Fullscreen(wnd.dimensions.w, wnd.dimensions.h, 32);
end;

function oxTPlatform.Fullscreen(x, y, bpp: longint): boolean;
begin
   Result := true;
end;

function oxTPlatform.LeaveFullscreen(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

procedure oxTPlatform.Move(wnd: oxTWindow; x, y: longint);
begin

end;

procedure oxTPlatform.Resize(wnd: oxTWindow; w, h: longint);
begin

end;

procedure oxTPlatform.Maximize(wnd: oxTWindow);
begin

end;

procedure oxTPlatform.Minimize(wnd: oxTWindow);
begin

end;

procedure oxTPlatform.Restore(wnd: oxTWindow);
begin

end;

procedure oxTPlatform.ErrorMessageBox(const title, say: string);
begin
   MessageBox(nil, title, say, uimbsCRITICAL, uimbcOK);
end;

function oxTPlatform.MessageBox(wParent: uiTWindow; const Title, Say: string;
   Style: uiTMessageBoxStyle; Buttons: longword): longword;
begin
   Result := uimbcNONE;
end;

procedure oxTPlatform.LoadCursor(cursorType: uiTCursorType);
begin
end;

procedure oxTPlatform.SetCursor(cursorType: uiTCursorType);
begin
end;

VAR
   grPlatform: oxPGlobalInstance;

function instanceGlobal(): TObject;
begin
   Result := oxTPlatform.Create();
end;

INITIALIZATION
    grPlatform := oxGlobalInstances.Add(oxTPlatform, @oxPlatform, @instanceGlobal);
    grPlatform^.Allocate := false;
    grPlatform^.CopyOverReference := true;

END.
