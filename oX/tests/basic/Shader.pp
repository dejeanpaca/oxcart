{
   Shader, tests shader functionality

   Started On:    27.09.2017.
}

{$INCLUDE oxdefines.inc}
PROGRAM Shader;

   USES
      uStd,
      {$INCLUDE oxappuses.inc},
      {app}
      uApp, uColors, vmVector,
      {oX}
      oxuWindowTypes, oxuWindows, oxuFont, oxuProjection, oxuRender, oxuPaths, oxuShaderFile,
      oxuRenderer, oxuTransform, oxuShader, uiuDraw, uiuWindow;

VAR
   shd: oxTShader;

procedure Render(wnd: oxTWindow);
begin
   wnd.Projection.ClearColor.Assign(0.2, 0.2, 0.5, 1.0);

   uiWindow.RenderPrepare(wnd);
end;

procedure Initialize();
begin
   shd := oxfShader.Read(oxPaths.Shaders + 'test' + DirectorySeparator + 'simple' + DirectorySeparator + 'simple.oxs');
end;

procedure DeInitialize();
begin
   FreeObject(shd);
end;

procedure init();
begin
   ox.OnInitialize.Add(@Initialize);
   ox.OnDeinitialize.Add(@DeInitialize);
   oxWindows.onRender.Add(@Render);
end;

BEGIN
   appInfo.setName('shader');
   ox.AppProcs.iAdd('app', @init);

   oxRun.Go();
END.
