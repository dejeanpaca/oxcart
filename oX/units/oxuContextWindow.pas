{
   oxuContextWindow, oX context window management
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuContextWindow;

INTERFACE

   USES
      uStd, uLog,
      {oX}
      uOX, oxuWindowTypes, oxuWindow, oxuUIHooks, oxuGlobalInstances,
      oxuRenderer, oxuWindowSettings, oxuWindows,
      {io}
      uiuWindowTypes, uiuControl;

TYPE
   { oxTContextWindowGlobal }

   oxTContextWindowGlobal = record
      Require: boolean;
      ID: uiTControlID;

      procedure Required();
      function Create(var wnd: oxTWindow): boolean;
      function Create(): boolean;
      procedure Destroy();
   end;

VAR
   {context window handling}
   oxContextWindow: oxTContextWindowGlobal;

IMPLEMENTATION

{ CONTEXT WINDOW }

procedure oxTContextWindowGlobal.Required();
begin
   Require := oxRenderer.ContextWindowRequired();
end;

function oxTContextWindowGlobal.Create(var wnd: oxTWindow): boolean;
begin
   Result := false;

   wnd := oxRenderer.WindowInstance.Create();

   log.Collapsed('Context Window');

   oxWindows.Setup(wnd, oxWindowSettings.w[-1], true);
   wnd.ID := ID;
   wnd.Title   := 'oX Context';
   wnd.RenderSettings := oxRenderer.ContextWindowSettings;
   wnd.Properties := wnd.Properties - [uiwndpVISIBLE];
   wnd.oxProperties.Context := true;

   oxWindow.CreateWindow(wnd);
   oxUIHooks.SetupContextWindow(wnd);

   log.Leave();

   if(wnd.errorCode = 0) then
      Result := true
   else
      oxWindows.LastErrorDescription := wnd.errorDescription;
end;

function oxTContextWindowGlobal.Create(): boolean;
begin
   Result := Create(oxWindows.w[oxcCONTEXT_WINDOW_IDX]);
end;

procedure oxTContextWindowGlobal.Destroy();
begin
   log.Collapsed('Destroy Context Window');

   if(oxWindows.w[oxcCONTEXT_WINDOW_IDX] <> nil) then begin
      oxWindow.Dispose(oxWindows.w[oxcCONTEXT_WINDOW_IDX]);
      FreeObject(oxWindows.w[oxcCONTEXT_WINDOW_IDX]);
   end;

   log.Leave();
end;


INITIALIZATION
   oxContextWindow.ID := uiControl.GetID('context');
   oxContextWindow.Require := true;

END.
