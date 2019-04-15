{
   Bkgrnd, implements background test functionality.

   Started On:    12.03.2011.
}

{$INCLUDE oxdefines.inc}
PROGRAM Bkgrnd;

   USES
      {$INCLUDE oxappuses.inc},
      uColors, vmVector,
      {app}
      uApp, appuKeys,
      {oX}
      oxuWindow, oxuWindowTypes, oxuRender, oxuRenderer,
      oxuTimer, oxuWindows, oxumPrimitive, oxuTransform,
      oxuProjection, oxuKeyboardControl, oxuBackground2D,
      uTestTools;

CONST
   MAX_TIME = 10.0;

VAR
   bk: oxTBackground2D;

procedure Render({%H-}wnd: oxTWindow);
var
   t, y: single;
   m: TMatrix4f;

begin
   {move background according to time}
   t := oxTime.Flow;

   y := 2.0 - ((2.0 / MAX_TIME) * t);
   if(y < 0.0) then
      y := 0.0;

   oxbk2dMove(bk, 0, y-1.0);

   {prepare}
   oxRenderer.ClearColor(0.1, 0.1, 0.25, 1.0);

   bk.screenx := oxProjection.a.acX;
   bk.screeny := oxProjection.a.acY;

   m := oxTransform.OrthoFrustum(-1.0 * oxProjection.a.acX, 1.0 * oxProjection.a.acX,
      -1.0 * oxProjection.a.acY, 1.0 * oxProjection.a.acY,
      -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   {render}
   oxbk2dRender(bk);
end;

procedure Initialize();
begin
   oxWindows.OnRender.Add(@Render);

   {create a background}
   oxbk2dInit(bk);
   oxbk2dBuild(bk);
   {load texture for background}
   if(oxbk2dTexture(bk, 'textures'+DirectorySeparator+'background.tga') <> 0) then begin
      writeln('Failed to load background texture.');
      exit();
   end;

   {start timer}
   writeln('Initialized...');
end;


BEGIN
   appInfo.SetName('Background Test');

   ox.OnInitialize.Add(@Initialize);

   oxRun.Go();
END.
