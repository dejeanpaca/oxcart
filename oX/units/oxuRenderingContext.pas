{
   oxuRenderingContext
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRenderingContext;

INTERFACE

   USES
      uStd,
      {oX}
      oxuWindowTypes, oxuViewportType, oxuProjectionType;

TYPE
   oxPRenderingContext = ^oxTRenderingContext;

   { oxTRenderingContext }

   oxTRenderingContext = record
      Name: StdString;
      {rendering context Id of the renderer}
      RC: loopint;

      CanRender: boolean;

      Viewport: oxPViewport;
      Projection: oxPProjection;
      Camera: pointer;
      {window associated with this rendering context, if any}
      Window: oxTWindow;
      Initialized: boolean;

      procedure UseWindow(wnd: oxTWindow);
      procedure Initialize();
   end;

THREADVAR
   oxRenderingContext: oxTRenderingContext;

IMPLEMENTATION

{ oxTRenderingContext }

procedure oxTRenderingContext.UseWindow(wnd: oxTWindow);
begin
   Viewport := @wnd.Viewport;
   Window := Window;
   CanRender := true;
end;

procedure oxTRenderingContext.Initialize();
begin
   if(not Initialized) then begin
      RC := -1;
      Initialized := true;
   end;
end;

INITIALIZATION
   oxRenderingContext.Initialize();

END.
