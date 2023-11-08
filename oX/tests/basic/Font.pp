{
   Font, tests font functionality.

   Started On:    12.03.2011.
}

{$INCLUDE oxdefines.inc}
PROGRAM Font;

   USES
      {$INCLUDE oxappuses.inc},
      {app}
      uApp, uColors, vmVector,
      {oX}
      oxuWindowTypes, oxuWindows, oxuFont, oxuProjection, oxuRender,
      oxuRenderer, oxuTransform, uiuWindow;

procedure Render(wnd: oxTWindow);
var
   i, j, px, py, w2, h2: longint;
   fnt: oxTFont;

begin
   fnt := oxf.Default;

   wnd.Projection.ClearColor.Assign(0.2, 0.2, 0.5, 1.0);

   uiWindow.RenderPrepare(wnd);

   w2 := wnd.Dimensions.w div 2;
   h2 := wnd.Dimensions.h div 2;

   fnt.Start();

   oxRender.Color3f(1.0, 1.0, 1.0);
   oxf.Write(-w2 + 2, h2 - 2 - fnt.GetHeight(), 'oX Engine');

   for j := 0 to (fnt.lines - 1) do
      for i := 0 to (fnt.cpline - 1) do begin
         px := (i * fnt.fw) - w2;
         py := ((fnt.lines - 1 - j) * fnt.fh) - fnt.fh;

         oxf.Write(px, py, char(j * fnt.cpline + i));
      end;

   oxf.Stop();
end;

procedure init();
begin
   oxWindows.onRender.Add(@Render);
end;

BEGIN
   appInfo.setName('font');
   ox.AppProcs.iAdd('init', @init);

   oxRun.Go();
END.
