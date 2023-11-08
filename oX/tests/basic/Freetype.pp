{
   FreetypeFont, tests freetype font functionality.

   Started On:    25.04.2017.
}

{$INCLUDE oxdefines.inc}
PROGRAM Freetype;

   USES
      {$INCLUDE oxappuses.inc},
      uStd, uColors, vmVector, uLog,
      {app}
      uApp,
      {oX}
      oxuWindowTypes, oxuWindows, oxuFont, oxuProjection, oxuRender, oxuMaterial,
      oxuFreetype, oxuFreetypeFonts, oxuRenderer, oxuTransform;

VAR
   font: oxTFont;

procedure Render(wnd: oxTWindow);
var
   i,
   px,
   py,
   w2,
   h2,
   charsPerRow,
   line: longint;
   m: TMatrix4f;
   f: oxTFont;

begin
   f := font;
   if(f = nil) then
      f := oxFont.Default;

   wnd.Projection.ClearColor.Assign(0.2, 0.2, 0.5, 1.0);

   charsPerRow := 16;

   w2 := wnd.dimensions.w div 2;
   h2 := wnd.dimensions.h div 2;

   m := oxTransform.OrthoFrustum(-w2, w2, -h2, h2, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   oxTransform.Identity();
   oxTransform.Apply();

   f.Start();

   oxCurrentMaterial.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxRender.BlendDefault();

   f.Write(-w2 + 2, h2 - f.GetHeight(), 'oX Engine');

   for i := 0 to (f.chars - 1) do begin
      line := i div charsPerRow;

      px := (i mod charsPerRow) * f.GetWidth() - w2;
      py := (f.lines - 1 - line) * f.GetHeight();

      f.Write(px, py, char(i + f.base));
   end;

   oxf.Stop();
end;

procedure Initialize();
begin
   oxWindows.onRender.Add(@Render);

   font := oxFreetypeManager.CreateFont('Inconsolata.ttf', 14);

   if(font = nil) then
      log.e('Font failed to load');
end;
procedure Deinitialize();
begin
   FreeObject(font);
end;

BEGIN
   appInfo.setName('font');

   ox.OnInitialize.Add(@Initialize);
   ox.OnDeinitialize.Add(@Deinitialize);

   oxRun.Go();
END.
