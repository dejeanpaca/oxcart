{
   test9Patch, tests 9patch functionality.

   Started On:    02.04.2017.
}

{$INCLUDE oxdefines.inc}
PROGRAM test9Patch;

   USES
      vmVector,
      {app}
      uAppInfo, uApp, uColors,
      {oX}
      {$INCLUDE oxappuses.inc}, oxuWindowTypes, oxuWindows, oxuRender, oxu9Patch,
      oxuRenderer, oxuTransform, oxuTexture, oxuTextureGenerate, uiuDraw;

VAR
   patch: oxT9Patch;
   texture: oxTTexture;

procedure Render({%H-}wnd: oxTWindow);
var
   m: TMatrix4f;
   w2, h2: single;

begin
   uiDraw.Start();

   w2 := wnd.dimensions.w div 2;
   h2 := wnd.dimensions.h div 2;

   m := oxTTransform.OrthoFrustum(-w2, w2, -h2, h2, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   oxTransform.Identity();
   oxTransform.Translate(-192, -128, 0);
   oxTransform.Apply();

   patch.Render(384, 256, texture);
end;

function doRoutine(action: oxTDoAction): boolean;
begin
   result := true;

   if(action = oxDO_INITIALIZE) then begin
      oxTextureGenerate.Generate('data' + DirectorySeparator + '9patch.png', texture);
      patch := oxT9Patch.Create();
      patch.Compute(4, 16, 16);
   end;
end;

{$R *.res}

BEGIN
   appInfo.setName('test9Patch');
   oxWindows.onRender := @Render;

   ox.DoRoutines.Add(@doRoutine);

   oxRun.Go();
END.
