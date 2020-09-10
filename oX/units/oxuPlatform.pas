{
   oxuPlatform, platform interface
   Copyright (c) 2012. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuPlatform;

INTERFACE

   USES
      uStd, uLog, uComponentProvider, uFileUtils,
      {app}
      appuMouse, appuKeys,
      {ox}
      oxuTypes, oxuWindowTypes, oxuGlobalInstances,
      {ui}
      uiuTypes, uiuWindowTypes;

TYPE
   { oxTPlatform }

   oxTPlatform = class
      public
         Name: StdString;
         {pointer driver used by the platform}
         PointerDriver: appTPointerDriver;
         {platforms have components}
         Components: TComponentProvider;

         {does this platform support multiple windows}
         MultipleWindows: boolean;

      constructor Create(); virtual;

      function MakeWindow({%H-}wnd: oxTWindow): boolean;  virtual;
      function DestroyWindow({%H-}wnd: oxTWindow): boolean; virtual;
      procedure ProcessEvents(); virtual;

      function Initialize(): boolean; virtual;
      function DeInitialize(): boolean; virtual;

      procedure SetTitle({%H-}wnd: oxTWindow; const {%H-}newTitle: StdString); virtual;

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

      procedure ErrorMessageBox(const {%H-}title, {%H-}say: StdString);
      function MessageBox({%H-}wParent: uiTWindow; const {%H-}Title, {%H-}Say: StdString;
         {%H-}Style: uiTMessageBoxStyle; {%H-}Buttons: longword): longword; virtual;

      procedure LoadCursor({%H-}cursorType: uiTCursorType); virtual;
      procedure SetCursor({%H-}cursorType: uiTCursorType); virtual;

      {translate key into character}
      function TranslateKey(const k: appTKeyEvent): char; virtual;

      {checks if the platform supports a file trash/recycle mechanism}
      function FileTrashCapability(): boolean; virtual;
      {send a file or directory into trash (if not available, will remove file/directory)}
      procedure TrashFile(const {%H-}path: StdString); virtual;

      {get center position for a window}
      procedure GetCenterPosition({%H-}wnd: oxTWindow; out p: oxTPoint); virtual;
      {get center position for a window}
      function SetSystemIcon({%H-}wnd: oxTWindow; const {%H-}fn: string): loopint; virtual;

      { COMPONENTS }

      {get a component from the renderer}
      function GetComponent(const componentName: StdString): TObject;
      {find component}
      function FindComponent(const componentName: StdString): PSingleComponent;
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
   ComponentProvider.InitializeValues(Components);
   MultipleWindows := true;
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

procedure oxTPlatform.SetTitle(wnd: oxTWindow; const newTitle: StdString);
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

procedure oxTPlatform.ErrorMessageBox(const title, say: StdString);
begin
   MessageBox(nil, title, say, uimbsCRITICAL, uimbcOK);
end;

function oxTPlatform.MessageBox(wParent: uiTWindow; const Title, Say: StdString;
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

function oxTPlatform.TranslateKey(const k: appTKeyEvent): char;
begin
   Result := appk.Translate(k.Key);
end;

function oxTPlatform.FileTrashCapability(): boolean;
begin
   Result := false;
end;

procedure oxTPlatform.TrashFile(const path: StdString);
var
   pathType: TFilePathType;

begin
   pathType := FileUtils.PathType(path);

   if(pathType = PATH_TYPE_FILE) then begin
      FileUtils.Erase(path);
   end else if(pathType = PATH_TYPE_DIRECTORY) then begin
      FileUtils.RmDir(path);
   end;
end;

procedure oxTPlatform.GetCenterPosition(wnd: oxTWindow; out p: oxTPoint);
begin
   p := oxNullPoint;
end;

function oxTPlatform.SetSystemIcon(wnd: oxTWindow; const fn: string): loopint;
begin
   Result := 0;
end;

function oxTPlatform.GetComponent(const componentName: StdString): TObject;
var
   p: PSingleComponent;

begin
   p := FindComponent(componentName);

   if(p <> nil) then
      result := p^.Return()
   else
      result := nil;
end;

function oxTPlatform.FindComponent(const componentName: StdString): PSingleComponent;
begin
   Result := Components.FindComponent(componentName);

   if(Result = nil) then
      log.w('Requested component <' + componentName + '> not found for platform ' + Name);
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
