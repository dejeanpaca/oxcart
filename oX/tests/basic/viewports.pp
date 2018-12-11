{
   viewports, test viewport

   Started On:    14.05.2012.
}

{$INCLUDE oxdefines.inc}
PROGRAM viewports;

   USES
      {oX}
      {$INCLUDE oxappuses.inc}, uColors,
      {ox}
      oxuProjection, oxuWindowTypes, oxuWindow, oxuWindows, oxuFont,
      oxumPrimitive, oxuTexture, oxuTransform, oxuRender, oxuRenderer,
      {test}
      uTestTools;

VAR
   primitive: oxTPrimitiveModel;
   contexts: array[0..3] of oxTProjection;

procedure RenderScene(var cxt: oxTProjection);
var
   f: oxTFont;

begin
   oxTransform.Identity();
   oxTransform.Translate(0, 0, -5.0);
   oxTransform.Apply();

   oxRender.CullFace(oxCULL_FACE_NONE);

   tt.RotateXYZ();
   oxRender.Color4f(1.0, 1.0, 1.0, 1.0);

   primitive.Render();

   cxt.QuickOrtho2DZero();
   f := oxf.Default;
   f.Start();
      f.Write(2, 2, cxt.Name);
   oxf.Stop();
end;

procedure Render(wnd: oxTWindow);
begin
   contexts[0].Apply();
   RenderScene(contexts[0]);

   contexts[1].Apply();
   RenderScene(contexts[1]);

   contexts[2].Apply();
   RenderScene(contexts[2]);

   contexts[3].Apply();
   RenderScene(contexts[3]);

   oxRenderer.ClearColor(0.0, 0.0, 0.0, 1.0);
end;

procedure initialize();
begin
   { disable default context }
   oxTProjection(oxWindow.Current.Projection).Enabled := false;

   contexts[0] := oxTProjection.Create(0, 240, 320, 240);
   contexts[0].Name := '0';
   contexts[0].ClearColor.Assign(0.2, 0.2, 1.0, 1.0);
   contexts[0].Perspective(60, 0.5, 1000.0);

   contexts[1] := oxTProjection.Create(320, 240, 320, 240);
   contexts[1].Name := '1';
   contexts[1].ClearColor.Assign(0.2, 1.0, 0.2, 1.0);
   contexts[1].Ortho(2.5, 2.5, 0.5, 1000.0);

   contexts[2] := oxTProjection.Create(0, 0, 640, 240);
   contexts[2].Name := '1';
   contexts[2].ClearColor.Assign(1.0, 0.2, 0.2, 1.0);
   contexts[2].Perspective(60, 0.5, 1000.0);

   contexts[3] := oxTProjection.Create(560, 20, 64, 64);
   contexts[3].Name := '2';
   contexts[3].ClearColor.Assign(0.2, 0.2, 0.2, 1.0);
   contexts[3].Ortho(2.5, 2.5, 0.5, 1000.0);

   primitive.InitCube();
end;

procedure run();
begin
   tt.dtRotateXYZ();
end;

procedure deinitialize();
begin
   primitive.Dispose();
end;

procedure InitializeTest();
begin
   ox.OnInitialize.Add(@initialize);
   ox.OnRun.Add(@run);
   ox.OnDeinitialize.Add(@deinitialize);

   oxWindows.OnRender.Add(@Render);
end;

BEGIN
   appInfo.setName('Viewports');
   ox.AppProcs.iAdd('app', @InitializeTest);

   oxRun.Go();
END.


