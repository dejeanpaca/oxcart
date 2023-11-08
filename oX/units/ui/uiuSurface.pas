{
   uiuSurface
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuSurface;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes, oxuWindow, oxuWindows,
      {ui}
      uiuControl, uiuTypes, uiuWindow, uiuWindowTypes;

TYPE

   { uiTSurfaceGlobal }

   uiTSurfaceGlobal = record
      ZIndex: loopint;

      function Create(const Title: string): uiTWindow;

      procedure Reset();
   end;

VAR
   uiSurface: uiTSurfaceGlobal;

IMPLEMENTATION

function uiTSurfaceGlobal.Create(const Title: string): uiTWindow;
var
   oxw: uiTWindow;

begin
   oxw := oxWindow.Current;
   Result := nil;

   if(oxw <> nil) then begin
      if(uiWindow.Create.ZIndex >= 0) then
         uiWindow.Create.ZIndex := ZIndex
      else
         uiWindow.Create.ZIndex := abs(uiWindow.Create.ZIndex);

      uiWindow.Create.Frame := uiwFRAME_STYLE_NONE;

      Result := uiWindow.MakeChild(oxw, Title,
         oxPoint(0, oxw.Dimensions.h - 1), oxDimensions(oxw.Dimensions.w, oxw.Dimensions.h), nil);

      if(Result <> nil) then begin
         {surfaces should not be movable}
         Result.Properties := Result.Properties - [uiwndpMOVE_BY_SURFACE, uiwndpRESIZABLE, uiwndpMOVABLE];
         Result.Properties := Result.Properties + [uiwndpNO_ESCAPE_KEY, uiwndpNO_CONFIRMATION_KEY];
      end;
   end;

   Reset();
end;

procedure uiTSurfaceGlobal.Reset();
begin
   ZIndex := 0;
end;

INITIALIZATION
   uiSurface.Reset();

END.
