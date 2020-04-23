{
   uiuWindowRender, UI window rendering
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuWindowRender;

INTERFACE

   USES
      uStd, uColors, vmVector,
      {oX}
      oxuTypes, oxuWindowTypes, oxuFont,
      oxuPrimitives, oxuTexture,
      oxuRenderer, oxuRender, oxuProjectionType, oxuProjection,
      {ui}
      oxuUI, uiuTypes, uiuSkinTypes,
      uiuWindowTypes, uiuWidget, uiuDraw, uiuDrawUtilities, uiWidgets, uiuWindow;

TYPE
   uiTWindowRenderHelper = class helper(uiTWindowHelper) for uiTWindow
      { window rendering }
      procedure RenderSubWindows();
      procedure RenderWindow();
   end;

   { uiTWindowRenderGlobal }

   uiTWindowRenderGlobal = record
      Projection: oxTProjection;

      { WINDOW RENDERING }
      {render an oX window}
      procedure Prepare(wnd: oxTWindow);
      procedure Render(wnd: oxTWindow);
   end;

VAR
   uiWindowRender: uiTWindowRenderGlobal;

IMPLEMENTATION

{ WINDOW RENDERING }

procedure uiTWindowRenderHelper.RenderSubWindows();
var
   i: longint;
   pwnd: uiTWindow;

begin
   for i := 0 to (w.z.Entries.n - 1) do begin
      pwnd := uiTWindow(w.z.Entries[i]);

      if(pwnd <> nil) then
         pwnd.RenderWindow();
   end;
end;

procedure uiTWindowRenderHelper.RenderWindow();
var
   width,
   fw,
   fh: longint;
   f: oxTFont;
   wSelected: boolean;
   colors: uiPWindowSkinColors;
   {are we currently hovering over this window}
   hovering: boolean;

procedure RenderWnd();
var
   r: oxTRect;
   tx: array[0..3] of TVector2f;

function getHoveringColor(color: TColor4ub): TColor4ub;
begin
   Result := color;

   if(hovering) then
      Result := Result.Lighten(WINDOW_HIGHLIGHT_MULTIPLIER);
end;

procedure renderBackgroundBox();
begin
   uiDraw.Box(RPosition.x, RPosition.y - Dimensions.h + 1, RPosition.x + Dimensions.w - 1, RPosition.y);
end;

procedure renderBackground();
var
   texture: oxTTexture;

begin
   if(Background.Typ = uiwBACKGROUND_SOLID) then begin
      SetColor(Background.Color);
      renderBackgroundBox();
   end else if(Background.Typ = uiwBACKGROUND_TEX) then begin
      SetColor(Background.Color);
      texture := oxTTexture(Background.Texture);

      if(oxTTexture(Background.Texture).HasAlpha() or (Background.Color.Transparent())) then
         oxRender.EnableBlend()
      else
         oxRender.DisableBlend();

      {assign background texture}
      if(Background.Fit = uiwBACKGROUND_TEX_FIT) then begin
         oxTex.CoordsQuadWH(texture.Width, texture.Height, Dimensions.w, Dimensions.h, tx);
      end else if(Background.Fit = uiwBACKGROUND_TEX_TILE) then begin
         tx := QuadTexCoords;
         vmScale(tx[0], 4, Background.Tile[0], Background.Tile[1]);

         if(Background.Offset[0] <> 0.0) or (Background.Offset[1] <> 0.0) then
            vmOffset(tx[0], 4, Background.Offset[0], Background.Offset[1]);
      end else begin
         tx := QuadTexCoords;
         vmScale(tx[0], 4, Background.Tile[0], Background.Tile[1]);

         if(Background.Offset[0] <> 0.0) or (Background.Offset[1] <> 0.0) then
            vmOffset(tx[0], 4, Background.Offset[0], Background.Offset[1]);
      end;

      uiDraw.Texture(texture);
      oxRender.TextureCoords(tx[0]);

      {render background}
      renderBackgroundBox();

      uiDraw.ClearTexture();
   end;
end;

procedure renderNiceFrame();
begin
   {title}
   SetColor(getHoveringColor(colors^.cTitle));

   uiDraw.Box(Aposition.x + 1, RPosition.y + 1, Aposition.x + width - 2, Aposition.y - 1);
   uiDraw.HLine(Aposition.x + 2, Aposition.y, Aposition.x + width - 3);

   {frame}
   SetColor(getHoveringColor(colors^.cFrame));

   {left}
   uiDraw.Box(APosition.x + 1, RPosition.y - Dimensions.h + 1, Aposition.x + fw - 1, RPosition.y);
   {right}
   uiDraw.Box(APosition.x + width - fw, RPosition.y - Dimensions.h + 1, Aposition.x + width - 2, RPosition.y);
   {bottom}
   uiDraw.Box(APosition.x + 1, RPosition.y - Dimensions.h - fh + 2, Aposition.x + width - 2, RPosition.y - Dimensions.h);
   {left line}
   uiDraw.VLine(APosition.x, Aposition.y - 1, RPosition.y - Dimensions.h - 1);
   {right line}
   uiDraw.VLine(APosition.x + width - 1, Aposition.y - 2, RPosition.y - Dimensions.h - 1);
   {bottom line}
   uiDraw.HLine(APosition.x + 2, RPosition.y - Dimensions.h - fh + 1, Aposition.x + width - 3);

   {inner frame}
   SetColor(getHoveringColor(colors^.cInnerFrame));

   uiDraw.Rect(Aposition.x + fw - 1, RPosition.y + 1, Aposition.x + width - fw, RPosition.y - Dimensions.h);
end;

procedure renderSimpleFrame();
begin
   {title}
   SetColor(getHoveringColor(colors^.cTitle));

   uiDraw.Box(Aposition.x, RPosition.y + 1, Aposition.x + width - 1, Aposition.y);

   {frame}
   SetColor(getHoveringColor(colors^.cFrame));

   {left}
   uiDraw.Box(Aposition.x, RPosition.y - Dimensions.h + 1, Aposition.x + fw - 1, RPosition.y);
   {right}
   uiDraw.Box(Aposition.x + width - fw, RPosition.y - Dimensions.h + 1, Aposition.x + width - 1, RPosition.y);
   {bottom}
   uiDraw.Box(Aposition.x, RPosition.y - Dimensions.h - fh + 1, Aposition.x + width - 1, RPosition.y - Dimensions.h);
end;

procedure renderIcon();
var
   d: oxTDimensions;
   x,
   y: single;

begin
   if(Icon <> nil) then begin
      d := GetIconDimensions();

      SetColorBlended(colors^.cTitleIcon);

      x := APosition.x + fw;
      y := APosition.y - ((GetTitleHeight() - d.h) div 2) + 1;

      uiDrawUtilities.Glyph(x, y, d.w, d.h, oxTTexture(Icon));
   end;
end;

function getTitleOffset(): loopint;
var
   d: oxTDimensions;

begin
   d := GetIconDimensions();

   Result := fw + d.w + (d.w div 4) + f.GetWidth() div 2;
end;

procedure renderTitleString();
begin
   {write title}
   if(f <> nil) then begin
      f.Start();
      SetColorBlended(colors^.cTitleText);

      r.x := APosition.x + getTitleOffset();
      r.y := APosition.y;
      r.w := width - GetNonClientWidth();
      r.h := GetTitleHeight();

      f.WriteCentered(Title, r, [oxfpCenterVertical]);
      oxf.Stop();
   end;
end;

begin
   {render background}
   renderBackground();

   if(uiwndpSYSTEM in Properties) then
      exit;

   {render frame}
   if(Frame <> uiwFRAME_STYLE_NONE) then begin
      if(uiTSkin(Skin).Window.Frames[ord(Frame)].FrameForm = uiwFRAME_FORM_NICE) then begin
         renderNiceFrame();
      end else
         renderSimpleFrame();

      renderIcon();
      renderTitleString();
   end;
end;

procedure RenderShadow();
var
   shadowSize: loopint;
   r: oxTRect;

begin
   shadowSize := uiTSkin(Skin).Window.ShadowSize;

   r.x := APosition.x + shadowSize;
   r.w := GetTotalWidth() - shadowSize - fw;
   r.y := APosition.y - GetTotalHeight();
   r.h := shadowSize;

   SetColor(colors^.Shadow);
   uiDraw.Box(r);

   r.x := APosition.x + GetTotalWidth() - fw;
   r.w := shadowSize + fw;
   r.y := APosition.y - shadowSize;
   r.h := GetTotalHeight();

   uiDraw.Box(r);
end;

begin
   {check if we can render the window}
   if(IsVisible()) then begin
      {determine if the window is selected}
      wSelected := IsSelected();

      if(wSelected) then
         colors := @uiTSkin(Skin).Window.Colors
      else
         colors := @uiTSkin(Skin).Window.InactiveColors;

      hovering := (not IsSelected()) and (oxui.mSelect.IsIn(Self) >= 0);

      {if it's a sub-window we can render it's shape}
      if(Parent <> nil) then begin
         f := oxui.GetDefaultFont();

         width  := GetTotalWidth();
         fw := GetFrameWidth();
         fh := GetFrameHeight();

         if(uiwndpDROP_SHADOW in Properties) then
            RenderShadow();

         RenderWnd();

         uiDraw.Scissor(RPosition.x, RPosition.y, Dimensions.w, Dimensions.h);
      end;

      {notify of surface rendering}
      Notification(uiWINDOW_RENDER_SURFACE);

      {render the window}
      Render();

      {render window widgets}
      uiWidget.Render(uiTWidgets(Widgets));

      {render sub-windows}
      if(self.W.w.n > 0) then
         RenderSubWindows();

      if(Parent <> nil) then
         uiDraw.DoneScissor();

      {render non-client widgets}
      uiWidget.RenderNonClient(uiTWidgets(Widgets));

      uiWindow.OnPostRender.Call(Self);
      OnPostRender();

      Notification(uiWINDOW_RENDER_POST);
   end;
end;

procedure uiTWindowRenderGlobal.Prepare(wnd: oxTWindow);
begin
   oxTProjection.Create(Projection, @wnd.Viewport);

   Projection.Ortho(0.375, wnd.Dimensions.w + 0.375, 0.375, wnd.Dimensions.h + 0.375, -1.0, 1.0);
   Projection.Apply();

   uiDraw.Start();
end;

procedure uiTWindowRenderGlobal.Render(wnd: oxTWindow);
begin
   if(uiwndpVISIBLE in uiTWindow(wnd).Properties) then begin
      Prepare(wnd);
      uiTWindow(wnd).RenderWindow();
      uiWindow.OxwPostRender.Call(wnd);
   end;
end;

END.
