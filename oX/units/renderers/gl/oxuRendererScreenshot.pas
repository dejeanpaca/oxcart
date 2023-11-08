{
   oxuRendererScreenshot, oX renderer screenshot component
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRendererScreenshot;

INTERFACE

   USES
      uStd,
      uImage,
      {ox}
      oxuWindowTypes;

TYPE
   { oxTRendererScreenshotComponent }

   oxTRendererScreenshotComponent = class
      {capture a screenshot of the given window}
      procedure Grab({%H-}wnd: oxTWindow; {%H-}image: imgTImage; {%H-}x, {%H-}y, {%H-}w, {%H-}h: loopint); virtual;
   end;

IMPLEMENTATION

{ oxTRendererScreenshotComponent }

procedure oxTRendererScreenshotComponent.Grab(wnd: oxTWindow; image: imgTImage; x, y, w, h: loopint);
begin

end;

END.
