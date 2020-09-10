{
   oxuglRendererCocoa, gl renderer cocoa (mac os x ) platform component
   Copyright (c) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglRendererCocoa;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uStd,
      CocoaAll,
      {ox}
      oxuRenderer, oxuOGL;

TYPE

   { oxglxTGlobal }

   oxglTCocoaGlobal = record
      procedure InitGL();
      function PreInitWindow(wnd: oglTWindow): boolean;
      procedure SwapBuffers(wnd: oglTWindow);

      function GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext = default(oglTRenderingContext)): oglTRenderingContext;
   end;

VAR
   oxglCocoa: oxglTCocoaGlobal;

IMPLEMENTATION

function oxglTCocoaGlobal.PreInitWindow(wnd: oglTWindow): boolean;
var
   Attributes: specialize TSimpleList<NSOpenGLPixelFormatAttribute>;

begin
   ZeroOut(Attributes, SizeOf(Attributes));

   {TODO: Implement}

   Attributes.Add(0);

   Result := false;
end;

procedure oxglTCocoaGlobal.InitGL();
begin
end;

procedure oxglTCocoaGlobal.SwapBuffers(wnd: oglTWindow);
begin
end;

function oxglTCocoaGlobal.GetContext(wnd: oglTWindow; shareContext: oglTRenderingContext): oglTRenderingContext;
begin
   Result := nil;
end;

END.
