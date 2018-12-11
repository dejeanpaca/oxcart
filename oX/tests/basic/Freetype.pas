{
   FreetypeFont, tests freetype font functionality.

   Started On:    25.04.2017.
}

{$INCLUDE oxdefines.inc}
PROGRAM Freetype;

   USES
      uStd, uColors, vmVector, uLog,
      {app}
      uAppInfo, uApp,
      {oX}
      {$INCLUDE oxappuses.inc}, oxuWindowTypes, oxuWindows, oxuFont, oxuContext, oxuRender, 
      oxuFreetype, oxuRenderer, oxuTransform;

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
      f := oxDefaultFont;

   oxTContext(wnd.context).ClearColor.Assign(0.2, 0.2, 0.5, 1.0);

   charsPerRow := 16;

   w2 := wnd.dimensions.w div 2;
   h2 := wnd.dimensions.h div 2;

   m := oxTransform.OrthoFrustum(-w2, w2, -h2, h2, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   oxTransform.Identity();
   oxTransform.Apply();

   f.Start();

   oxRender.Color3f(1.0, 1.0, 1.0);
   oxf.Write(-w2 + 2, h2 - f.GetHeight(), 'oX Engine');

   for i := 0 to (f.chars - 1) do begin
      line := i div charsPerRow;

      px := (i mod charsPerRow) * f.GetWidth() - w2;
      py := (font.lines - 1 - line) * f.GetHeight();

      f.Write(px, py, char(i + f.base));
   end;

   oxf.Stop();
end;

function doRoutine(action: oxTDoAction): boolean;
begin
   result := true;

   if(action = oxDO_INITIALIZE) then begin
      font := oxFreetypeManager.CreateFont('Inconsolata.ttf', 14);
      if(font = nil) then
         log.e('Font failed to load');
   end else if (action = oxDO_DEINITIALIZE) then begin
      FreeObject(font);
   end;
end;

BEGIN
   appInfo.setName('font');
   oxWindows.onRender := @Render;

   ox.DoRoutines.Add(@doRoutine);

   oxRun.Go();
END.
