{
   oxuglRendererPlatform, gl renderer platform specific component
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRendererPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTypes, oxuRenderer,
      {gl}
      oxuOGL, oxuglWindow;

TYPE
   oxglPPlatform = ^oxglTPlatform;

   { oxglTPlatform }

   oxglTPlatform = object
      Name: string;

      constructor Create();

      {raise an error, if any}
      function RaiseError(): loopint; virtual;

      procedure OnInitialize(); virtual;
      function PreInitWindow({%H-}wnd: oglTWindow): boolean; virtual;
      procedure OnInitWindow({%H-}wnd: oglTWindow); virtual;
      function OnDeInitWindow({%H-}wnd: oglTWindow): boolean; virtual;
      procedure SwapBuffers({%H-}wnd: oglTWindow); virtual;
      function GetContext({%H-}wnd: oglTWindow; {%H-}shareContext: oglTRenderingContext): oglTRenderingContext; virtual;
      function ContextCurrent(const {%H-}context: oxTRenderTargetContext): boolean; virtual;
      function ClearContext({%H-}wnd: oglTWindow): boolean; virtual;
      function DestroyContext({%H-}wnd: oglTWindow; {%H-}context: oglTRenderingContext): boolean; virtual;
   end;

IMPLEMENTATION

{ oxglTPlatform }

constructor oxglTPlatform.Create();
begin

end;

function oxglTPlatform.RaiseError(): loopint;
begin
   Result := 0;
end;

procedure oxglTPlatform.OnInitialize();
begin

end;

function oxglTPlatform.PreInitWindow(wnd: oglTWindow): boolean;
begin
   Result := false;
end;

procedure oxglTPlatform.OnInitWindow(wnd: oglTWindow);
begin

end;

function oxglTPlatform.OnDeInitWindow(wnd: oglTWindow): boolean;
begin
   Result := true;
end;

procedure oxglTPlatform.SwapBuffers(wnd: oglTWindow);
begin

end;

function oxglTPlatform.GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext;
begin
   Result := default(oglTRenderingContext);
end;

function oxglTPlatform.ContextCurrent(const context: oxTRenderTargetContext): boolean;
begin
   Result := true;
end;

function oxglTPlatform.ClearContext(wnd: oglTWindow): boolean;
begin
   Result := true;
end;

function oxglTPlatform.DestroyContext(wnd: oglTWindow; context: oglTRenderingContext): boolean;
begin
   Result := true;
end;

END.
