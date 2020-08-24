{
   oxuglScreenshot, screenshot component
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglScreenshot;

INTERFACE

   USES
      uStd,
      uImage,
      {ox}
      uOX, oxuWindowTypes, oxuRendererScreenshot,
      {gl}
      {$INCLUDE usesgl.inc}, oxuOGL, oxuglRenderer;

TYPE
   { oxglTRendererScreenshotComponent }
   oxglTRendererScreenshotComponent = class(oxTRendererScreenshotComponent)
      procedure Grab({%H-}wnd: oxTWindow; image: imgTImage; x, y, w, h: loopint); override;
   end;

VAR
   oglScreenshotComponent: oxglTRendererScreenshotComponent;

IMPLEMENTATION

{ oxglTRendererScreenshotComponent }

procedure oxglTRendererScreenshotComponent.Grab(wnd: oxTWindow; image: imgTImage; x, y, w, h: loopint);
begin
   {get the image data}
   glPixelStorei(GL_PACK_ALIGNMENT, 1);
   glReadPixels(x, y, w, h, GL_RGB, GL_UNSIGNED_BYTE, image.Image);
   ogl.eRaise();
end;

function componentReturn(): TObject;
begin
   Result := oglScreenshotComponent;
end;

procedure init();
begin
   oglScreenshotComponent := oxglTRendererScreenshotComponent.Create();

   oxglRenderer.Components.RegisterComponent('screenshot', @componentReturn);
end;

procedure deinit();
begin
   FreeObject(oglScreenshotComponent);
end;

INITIALIZATION
   ox.PreInit.Add('gl.screenshot', @init, @deinit);

END.
