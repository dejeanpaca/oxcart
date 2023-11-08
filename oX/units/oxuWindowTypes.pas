{
   oxuWindowTypes, oX window data types
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindowTypes;

INTERFACE

   USES
      uStd, uLog,
      {oX}
      oxuTypes, oxuViewportType,
      {ui}
      uiuTypes, uiuWindowTypes;

TYPE
   {a window}
   oxTWindowRenderSettings = record
     DoubleBuffer,
     Software,
     Stereo,
     VSync: boolean;

     ColorBits,
     DepthBits,
     StencilBits,
     AccumBits,
     AuxBuffers: longword;

     Layer: longint;
   end;

   { oxTWindow }

   oxTWindow = class (uiTWindow)
      {position of the window before going to fullscreen}
      FullscreenPosition: oxTPoint;
      {dimensions before going fullscreen}
      FullscreenDimensions: oxTDimensions;

      {index in the window list}
      Index: loopint;

      oxProperties: record
        {has the window been created yet}
        Created,
        {context window, used for gl context creation}
        Context,
        {apply the default render context}
        ApplyDefaultViewport,
        {is the screen fullscreen}
        Fullscreen,
        {is the fullscreen mode windowed}
        WindowedFullscreen: boolean;
      end;

      {renderer associated with the window}
      Renderer: TObject;
      {platform associated with the window}
      Platform: TObject;

      {base UI object}
      UIBase: TObject;

      {externally associated window}
      ExternalWindow: uiTWindow;
      {external ox parent window}
      oxwExternal: oxTWindow;

      {rendering settings}
      RenderSettings: oxTWindowRenderSettings;

      {rendering contexts}
      RenderingContext,
      ThreadRenderingContext: loopint;

      {viewport for this window}
      Viewport: oxTViewport;

      {error}
      ErrorDescription: TErrorString;

      constructor Create(); override;

      procedure RaiseError(code: longint; const description: StdString);
      procedure CreateFail(const description: StdString);
      procedure DestroyFail(const description: StdString);
   end;

   oxTWindowClass = class of oxTWindow;

   oxTSimpleWindowsList = specialize TSimpleList<oxTWindow>;

   oxTWindowRoutine = procedure(wnd: oxTWindow);
   oxTWindowRoutines = specialize TSimpleList<oxTWindowRoutine>;

   { oxTWindowRoutinesHelper }

   oxTWindowRoutinesHelper = record helper for oxTWindowRoutines
      procedure Call(wnd: oxTWindow);
   end;


CONST
   oxrDefaultWindowSettings: oxTWindowRenderSettings = (
      DoubleBuffer: true;
      Software: false;
      Stereo: false;
      VSync: false;

      ColorBits:     32;
      DepthBits:     24;
      StencilBits:   0;
      AccumBits:     0;
      AuxBuffers:    0;
      Layer:         0
   );

   oxrContextWindowSettings: oxTWindowRenderSettings = (
      DoubleBuffer: true;
      Software: false;
      Stereo: false;
      VSync: false;

      ColorBits:        32;
      DepthBits:        24;
      StencilBits:      0;
      AccumBits:        0;
      AuxBuffers:       0;
      Layer:            0
   );


IMPLEMENTATION

{ oxTWindowProceduresHelper }

procedure oxTWindowRoutinesHelper.Call(wnd: oxTWindow);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](wnd);
   end;
end;

constructor oxTWindow.Create;
begin
   inherited;

   Properties := Properties + [uiwndpAUTO_CENTER, uiwndpVISIBLE];

   oxProperties.ApplyDefaultViewport := true;

   RenderingContext := -1;
   ThreadRenderingContext := -1;

   Frame := uiwFRAME_STYLE_DEFAULT;

   Dimensions.Assign(640, 480);
end;

procedure oxTWindow.RaiseError(code: longint; const description: StdString);
begin
   if(ErrorCode = 0) then
      ErrorCode := code;

   ErrorDescription.Add(description);
   log.e(description);
end;

procedure oxTWindow.CreateFail(const description: StdString);
begin
   RaiseError(eFAIL, description);
end;

procedure oxTWindow.DestroyFail(const description: StdString);
begin
   RaiseError(eFAIL, description);
end;

END.
