{
   oxuContextWindow, oX context window management
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
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

      function Required(): boolean;
      function Create(var wnd: oxTWindow): boolean;
      function Create(): boolean;
      procedure Destroy();
   end;

VAR
   {context window handling}
   oxContextWindow: oxTContextWindowGlobal;

IMPLEMENTATION

{ CONTEXT WINDOW }

function oxTContextWindowGlobal.Required(): boolean;
begin
   Require := oxRenderer.ContextWindowRequired();
   Result := Require;
end;

function oxTContextWindowGlobal.Create(var wnd: oxTWindow): boolean;
begin
   Result := false;

   wnd := oxRenderer.WindowInstance.Create();

   log.Collapsed('Context Window');

   oxWindows.Setup(wnd, oxWindowSettings.w[-1], true);
   oxWindow.Current := wnd;
   wnd.ID := ID;
   wnd.Title := 'oX Context';
   wnd.Properties := wnd.Properties - [uiwndpVISIBLE];
   wnd.oxProperties.Context := true;

   oxWindow.CreateWindow(wnd);
   oxUIHooks.SetupContextWindow(wnd);

   log.Leave();

   if(wnd.ErrorCode = 0) then
      Result := true
   else
      oxWindows.LastErrorDescription := wnd.ErrorDescription;
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
