{
   Starfield

   Started On:    07.05.2011.
}

{$INCLUDE oxdefines.inc}
PROGRAM Starfield;

   USES
      uTiming, vmVector,
      {app}
      uAppInfo, uApp, appuKeys,
      {oX}
      {$INCLUDE oxappuses.inc}, oxuWindow, oxuWindowTypes,
      oxuTimer, oxuWindows, oxumPrimitive, oxuglTexture,
      oxuContext, oxuFramerate, oxuTransform,
      uTestTools,
      oxuStarfield;

VAR
   stars: oxTStarfield;

procedure Render(wnd: oxTWindow);
var
   m: TMatrix4f;

begin
   m := oxTransform.PerspectiveFrustum(75.0, 1.5, 1.0, 1000.0);

   oxTransform.Translate(0.0, 0.0, -5.0);
   oxTransform.Apply();

   stars.Render();

   oxFramerate.Increment();
   writeln(oxFramerate.Get());
end;

function Perform(a: oxTDoAction): boolean;
begin
   result := true;

   case a of
      oxDO_INITIALIZE: begin
        oxFramerateInit(oxFramerate);

        stars := oxTStarfield.Create();
        stars.CreateStars(3000);
      end;
   end;
end;

BEGIN
   appInfo.name         := 'Starfield';
   appInfo.nameShort    := 'starfield';

   ox.DoRoutines.Add(@Perform);
   oxWindows.onRender   := @Render;

   oxRun.Go();
END.

