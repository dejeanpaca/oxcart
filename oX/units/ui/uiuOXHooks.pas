{
   uiuOXHooks, UI hooks
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuOXHooks;

INTERFACE

   USES
      {oX}
      oxuUIHooks, oxuTypes, oxuWindowTypes, oxuWindow, oxuWindows,
      oxuRenderer, oxuSurfaceRender, oxuRenderingContext,
      {ui}
      uiuCursor,
      uiuWindowTypes, uiuWindow, uiuWindowRender;

TYPE

   { uiTOXHooks }

   uiTOXHooks = class(oxTUIHooks)
      constructor Create();

      procedure InitializeWindow(wnd: oxTWindow); override;
      procedure DestroyWindow(wnd: oxTWindow); override;

      procedure SetupContextWindow(wnd: oxTWindow); override;

      procedure SetPosition(wnd: oxTWindow; const position: oxTPoint); override;
      procedure SetDimensions(wnd: oxTWindow; const dimensions: oxTDimensions); override;

      procedure Select(wnd: oxTWindow); override;
      procedure Render(var context: oxTRenderingContext); override;

      procedure Minimize(wnd: oxTWindow; fromSystem: boolean = false); override;
      procedure Maximize(wnd: oxTWindow; fromSystem: boolean = false); override;
      procedure Restore(wnd: oxTWindow; fromSystem: boolean = false); override;
   end;

IMPLEMENTATION

VAR
   surfaceRenderer: oxTSurfaceRenderer;

{ uiTOXHooks }

constructor uiTOXHooks.Create();
begin
   Name := 'UI';
end;

procedure uiTOXHooks.SetPosition(wnd: oxTWindow; const position: oxTPoint);
begin
   wnd.Position.x := position.x;
   wnd.Position.y := position.y;

   wnd.UpdatePositions();
end;

procedure uiTOXHooks.SetDimensions(wnd: oxTWindow; const dimensions: oxTDimensions);
begin
   wnd.Dimensions.w := dimensions.w;
   wnd.Dimensions.h := dimensions.h;

   wnd.UpdateResize();
   wnd.UpdateRPosition();
end;

procedure uiTOXHooks.Select(wnd: oxTWindow);
begin
   wnd.Select();
end;

procedure uiTOXHooks.Render(var context: oxTRenderingContext);
begin
   if(uiWindow.AutoRender) then
      uiWindowRender.Render(context);
end;

procedure uiTOXHooks.Minimize(wnd: oxTWindow; fromSystem: boolean);
begin
   uiTWindow(wnd).Minimize(fromSystem);
end;

procedure uiTOXHooks.Maximize(wnd: oxTWindow; fromSystem: boolean);
begin
   uiTWindow(wnd).Maximize(fromSystem);
end;

procedure uiTOXHooks.Restore(wnd: oxTWindow; fromSystem: boolean);
begin
   uiTWindow(wnd).Restore(fromSystem);
end;

procedure uiTOXHooks.InitializeWindow(wnd: oxTWindow);
begin
   {TODO: Assign a better UI ID}
   uiWindow.Create.Properties := uiWindow.RootDefaultProperties;
   uiWindow.Create.Buttons:= uiWindow.RootDefaultButtons;

   uiWindow.SetupCreatedWindow(wnd, uiWindow.Create);

   wnd.oxwParent := wnd;

   uiCursor.SetCursorTypeForced(wnd.CursorType);
   {$IFNDEF OX_LIBRARY}
   Include(wnd.Properties, uiwndpSYSTEM);
   {$ENDIF}
end;

procedure uiTOXHooks.DestroyWindow(wnd: oxTWindow);
begin
   uiWindow.Dispose(uiTWindow(wnd), false);
end;

procedure uiTOXHooks.SetupContextWindow(wnd: oxTWindow);
begin
   Exclude(wnd.Properties, uiwndpQUIT_ON_CLOSE);
end;

procedure render(var context: oxTRenderingContext);
begin
   oxUIHooks.Render(context);
end;

INITIALIZATION
   oxUIHooksInstance := uiTOXHooks;
   oxSurfaceRender.Get(surfaceRenderer, @render);
   surfaceRenderer.Name := 'UI';

END.
