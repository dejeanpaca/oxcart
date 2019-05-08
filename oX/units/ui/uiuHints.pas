{
   uiuHints, renders widget hints
   Copyright (C) 2016. Dejan Boras

   Started On:    30.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT uiuHints;

INTERFACE

   USES
      uStd, uColors, uTiming, StringUtils,
      {oX}
      oxuTypes, oxuFont, oxuUI,
      {ui}
      uiuWindowTypes, uiuWindow, uiuWidget, uiWidgets, uiuSkinTypes,
      uiuWidgetRender;

CONST
   uiHINTS_DEFAULT_WAIT_TIME = 500;

TYPE
   uiTHintsGlobal = record
      Padding: longint;
      {wait time before showing a hint, in miliseconds}
      WaitTime: longword;
   end;

VAR
   uiHints: uiTHintsGlobal;

IMPLEMENTATION

CONST
   HINT_PADDING = 7;
   HINT_SEPARATION = 20;

procedure renderHint(wnd: uiTWindow);
var
   oxw: uiTWindow;
   ms: uiTWidget;
   p: oxTPoint;
   d: oxTDimensions;
   f: oxTFont;
   r: oxTRect;
   cSurface: TColor4ub;
   maxlen,
   lines: loopint;

begin
   ms := oxui.mSelect.GetSelectedWdg();

   if(ms <> nil) and (ms.Hint <> '') then begin
      if(timer.Cur() - oxui.mLastEventTime < uiHints.WaitTime) then
         exit;

      oxw := uiTWindow(wnd.oxwParent);

      f := oxui.GetDefaultFont();
      maxlen := f.GetMultilineLength(ms.Hint);
      lines := StringCount(ms.Hint, #13) + 1;

      p.x := ms.RPosition.x + oxui.mSelect.x;
      p.y := ms.RPosition.y + oxui.mSelect.y - (ms.Dimensions.h + HINT_SEPARATION);

      d.w := maxlen + uiHints.Padding * 2;
      d.h := (f.GetHeight() * lines) + uiHints.Padding * 2;

      if(p.x + d.h >= oxw.Dimensions.h) then
         p.x := oxw.Dimensions.w - (d.w + 1 + HINT_SEPARATION);

      if(p.y - d.h < 0) then
         p.y := d.h - 1 + HINT_SEPARATION;

      cSurface := uiTSkin(uiTWindow(oxw).Skin).Colors.Surface;
      uiRenderWidget.Box(p, d, cSurface, uiTSkin(uiTWindow(oxw).Skin).Colors.Highlight, wdgRENDER_BLOCK_ALL, 0.75);

      r.Assign(p, d);

      inc(r.x, uiHints.Padding);
      dec(r.y, uiHints.Padding);
      dec(r.w, uiHints.Padding);
      dec(r.h, uiHints.Padding);

      f.Start();
         oxw.SetColorBlended(uiTSkin(uiTWindow(oxw).Skin).Colors.Text);
         f.WriteInRect(ms.hint, r, false, true);
      oxf.Stop();
   end;
end;

INITIALIZATION
   uiHints.WaitTime := uiHINTS_DEFAULT_WAIT_TIME;
   uiHints.Padding := HINT_PADDING;

   uiWindow.OxwPostRender.Add(@renderHint);

END.

