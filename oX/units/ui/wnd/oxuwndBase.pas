{
   oxuwndBase, base window structure
   Copyright (C) 2017. Dejan Boras

   Started On:    17.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndBase;

INTERFACE

   USES
      {app}
      appuEvents, appuActionEvents,
      {oX}
      oxuTypes, oxuRenderer,
      {ui}
      uiuTypes, uiuControl, oxuUI, uiuWindowTypes, uiuWindow, uiuSurface;

TYPE

   { oxuiTWindowBase }

   oxuiTWindowBase = class(uiTWindow)
      {the associated oxTWindowBase}
      BaseHandler: TObject;

      procedure DeInitialize(); override;
   end;

   oxuiTWindowBaseClass = class of oxuiTWindowBase;

   { oxTWindowBase }

   oxTWindowBase = class
      Name,
      Title: string;

      DoDestroy,
      {use a surface instead of a regular window}
      UseSurface: boolean;
      UseWindow: uiTWindow;
      Instance: oxuiTWindowBaseClass;

      Width,
      Height: longint;

      Window: oxuiTWindowBase;
      ID: uiTControlID;
      OpenWindowAction: TEventID;

      constructor Create(); virtual;
      destructor Destroy(); override;

      {opens/creates the window}
      procedure Open(); virtual;
      {closes/destroys the window}
      procedure Close(); virtual;

      protected
      {creates the window}
      procedure CreateWindow(); virtual;
      {adds widgets to the window}
      procedure AddWidgets(); virtual;

      {called when a window is destroyed}
      procedure WindowDestroyed({%H-}wnd: oxuiTWindowBase); virtual;
   end;

IMPLEMENTATION

{ oxuiTWindowBase }

procedure oxuiTWindowBase.DeInitialize();
begin
   inherited DeInitialize();

   if(BaseHandler <> nil) then begin
      oxTWindowBase(BaseHandler).WindowDestroyed(Self);
      oxTWindowBase(BaseHandler).Window := nil;
   end;
end;

{ oxTWindowBase }

constructor oxTWindowBase.Create();
begin
   if(OpenWindowAction = 0) then
      OpenWindowAction := appActionEvents.SetCallback(@Open);

   if(Width = 0) then
      Width := 480;

   if(Height = 0) then
      Height:= 320;

   doDestroy := true;
end;

destructor oxTWindowBase.Destroy();
begin
   inherited Destroy;

   if(Window <> nil) then begin
      Window.BaseHandler := nil;
      uiWindow.DisposeQueue(uiTWindow(Window));
   end;
end;

procedure oxTWindowBase.CreateWindow();
var
   uiwnd: uiTWindow;

begin
   oxui.SetUseWindow(UseWindow);
   uiwnd := oxui.GetUseWindow();

   {create the window}
   uiWindow.Create.Buttons := uiwbCLOSE;
   Include(uiWindow.Create.Properties, uiwndpAUTO_CENTER);

   if(Instance <> nil) then
      uiWindow.Create.Instance := Instance
   else
      uiWindow.Create.Instance := oxuiTWindowBase;

   if(UseSurface) then begin
      Window := oxuiTWindowBase(uiSurface.Create(Title))
   end else
      Window := oxuiTWindowBase(uiWindow.MakeChild(uiwnd,
         Title,
         oxNullPoint,
         oxTDimensions.Fit(width, uiwnd.Dimensions.w, height, uiwnd.Dimensions.h)));

   Window.SetID(ID);

   if(Window <> nil) then begin
      Window.BaseHandler := Self;

      {add widgets}
      AddWidgets();
   end;
end;

procedure oxTWindowBase.AddWidgets();
begin

end;

procedure oxTWindowBase.WindowDestroyed(wnd: oxuiTWindowBase);
begin

end;

procedure oxTWindowBase.Open();
begin
   if(Window = nil) then
      CreateWindow();

   Window.Open();
end;

procedure oxTWindowBase.Close();
begin
   if(Window <> nil) then begin
      if(doDestroy) then
         uiWindow.DisposeQueue(uiTWindow(Window))
      else
         Window.Close();
   end;
end;

END.
