{
   Bkgrnd, implements background test functionality.

   Started On:    12.03.2011.
}

{$INCLUDE oxdefines.inc}
PROGRAM Bkgrnd;

   USES
      uAppInfo, uColors, vmVector,
      {app}
      uApp, appuKeys,
      {oX}
      {$INCLUDE oxappuses.inc}, oxuWindow, oxuWindowTypes, oxuRender, oxuRenderer,
      oxuTimer, oxuWindows, oxumPrimitive, oxuTransform,
      oxuContext, oxuKeyboardControl, oxuBackground2D,
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
   t := oxMainTimeFlow;

   y := 2.0 - ((2.0 / MAX_TIME) * t);
   if(y < 0.0) then
      y := 0.0;

   oxbk2dMove(bk, 0, y-1.0);

   {prepare}
   oxRenderer.ClearColor(0.1, 0.1, 0.25, 1.0);

   bk.screenx := oxContext.a.acX;
   bk.screeny := oxContext.a.acY;

   m := oxTransform.OrthoFrustum(-1.0 * oxContext.a.acX, 1.0 * oxContext.a.acX,
      -1.0 * oxContext.a.acY, 1.0 * oxContext.a.acY,
      -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   {render}
   oxbk2dRender(bk);
end;

function Perform(a: oxTDoAction): boolean;
begin
   result := true;

   case a of
      oxDO_INITIALIZE: begin
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
   end;
end;

procedure InitWindow();
begin
   oxWindows.Allocate(1);
end;

procedure InitializeTest();
begin
   ox.DoRoutines.Add(@Perform);
   oxWindows.onRender   := @Render;
   oxWindows.onCreate   := @InitWindow;
end;

BEGIN
   appInfo.name      := 'Background Test';
   appInfo.nameShort := 'backgroundtest';

   InitializeTest();

   oxRun.Go();
END.

