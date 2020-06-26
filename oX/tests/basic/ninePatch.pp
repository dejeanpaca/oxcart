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
      oxuViewport,
      oxuWindowTypes, oxuWindows, oxuRender, oxu9Patch, oxuRunRoutines,
      oxuRenderer, oxuTransform, oxuTexture, oxuTextureGenerate, uiuDraw, oxu9PatchFile;

VAR
   patch: oxT9Patch;

procedure Render({%H-}wnd: oxTWindow);
var
   m: TMatrix4f;
   w2, h2: single;

begin
   oxViewport^.ClearColor.Assign(0.2, 0.2, 0.5, 1.0);

   uiDraw.Start();

   w2 := wnd.dimensions.w div 2;
   h2 := wnd.dimensions.h div 2;

   m := oxTTransform.OrthoFrustum(-w2, w2, -h2, h2, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   oxTransform.Identity();
   oxTransform.Translate(-192, -128, 0);
   oxTransform.Apply();

   if(patch <> nil) then
      patch.Render(384, 256);
end;

procedure Initialize();
begin
   patch := oxf9Patch.Read('data' + DirectorySeparator + '9patch.9p');

   oxWindows.OnRender.Add(@Render);
end;

BEGIN
   appInfo.setName('test9Patch');
   ox.OnInitialize.Add('initialize', @Initialize);

   oxRun.Go();
END.
