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
      oxuProjectionType, oxuProjection, oxuWindowTypes, oxuWindow, oxuWindows, oxuFont,
      oxumPrimitive, oxuTexture, oxuTransform, oxuRender, oxuRenderer, oxuMaterial, oxuRunRoutines,
      {test}
      uTestTools;

VAR
   primitive: oxTPrimitiveModel;
   projections: array[0..3] of oxTProjection;

   initRoutines,
   runRoutine: oxTRunRoutine;

procedure RenderScene(var projection: oxTProjection);
var
   f: oxTFont;

begin
   projection.Apply();

   oxTransform.Identity();
   oxTransform.Translate(0, 0, -5.0);
   oxTransform.Apply();

   oxRender.CullFace(oxCULL_FACE_NONE);

   tt.RotateXYZ();
   oxCurrentMaterial.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);

   primitive.Render();

   projection.QuickOrtho2DZero();
   f := oxf.Default;
   f.Start();
      f.Write(2, 2, projection.Name);
   oxf.Stop();
end;

procedure Render({%H-}wnd: oxTWindow);
begin
   RenderScene(projections[0]);
   RenderScene(projections[1]);
   RenderScene(projections[2]);
   RenderScene(projections[3]);

   oxRenderer.ClearColor(0.0, 0.0, 0.0, 1.0);
end;

procedure initialize();
begin
   oxWindows.OnRender.Add(@Render);

   { disable default context }
   oxWindow.Current.Projection.Enabled := false;

   oxTProjection.Create(projections[0]);
   projections[0].Initialize(0, 240, 320, 240);
   projections[0].Name := '0';
   projections[0].ClearColor.Assign(0.2, 0.2, 1.0, 1.0);
   projections[0].Perspective(60, 0.5, 1000.0);

   oxTProjection.Create(projections[1]);
   projections[1].Initialize(320, 240, 320, 240);
   projections[1].Name := '1';
   projections[1].ClearColor.Assign(0.2, 1.0, 0.2, 1.0);
   projections[1].Ortho(2.5, 2.5, 0.5, 1000.0);

   oxTProjection.Create(projections[2]);
   projections[2].Initialize(0, 0, 640, 240);
   projections[2].Name := '1';
   projections[2].ClearColor.Assign(1.0, 0.2, 0.2, 1.0);
   projections[2].Perspective(60, 0.5, 1000.0);

   oxTProjection.Create(projections[3]);
   projections[3].Initialize(560, 20, 64, 64);
   projections[3].Name := '2';
   projections[3].ClearColor.Assign(0.2, 0.2, 0.2, 1.0);
   projections[3].Ortho(2.5, 2.5, 0.5, 1000.0);

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

BEGIN
   appInfo.setName('Viewports');

   ox.OnInitialize.Add(initRoutines, 'init', @initialize, @deinitialize);
   ox.OnRun.Add(runRoutine, 'run', @run);

   oxRun.Go();
END.
