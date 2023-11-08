{
   ninePatch, tests 9patch functionality.
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
PROGRAM ninePatch;

   USES
      {$INCLUDE oxappuses.inc},
      vmVector,
      {app}
      uApp, uColors,
      {oX}
      oxuWindowTypes, oxuWindows, oxuRender, oxu9Patch, oxuRunRoutines,
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

procedure Initialize();
begin
   oxTextureGenerate.Generate('data' + DirectorySeparator + '9patch.png', texture);

   patch := oxT9Patch.Create();
   patch.Compute(4, 16, 16);
   oxWindows.OnRender.Add(@Render);
end;

BEGIN
   appInfo.setName('test9Patch');
   ox.OnInitialize.Add('initialize', @Initialize);

   oxRun.Go();
END.
