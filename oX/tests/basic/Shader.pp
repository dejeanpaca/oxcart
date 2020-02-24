{
   Shader, tests shader functionality
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
PROGRAM Shader;

   USES
      uStd,
      {$INCLUDE oxappuses.inc},
      {app}
      uApp, uColors,
      {oX}
      oxuWindowTypes, oxuWindows, oxuProjection, oxuPaths, oxuShaderFile,
      oxuRenderer, oxuShader, uiuWindowRender;

VAR
   shd: oxTShader;

procedure Render(wnd: oxTWindow);
begin
   wnd.Projection.ClearColor.Assign(0.2, 0.2, 0.5, 1.0);

   uiWindowRender.Prepare(wnd);
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
   ox.OnInitialize.Add('initialize', @Initialize, @DeInitialize);
   oxWindows.onRender.Add(@Render);
end;

BEGIN
   appInfo.setName('shader');
   ox.PreInit.Add('app', @init);

   oxRun.Go();
END.
