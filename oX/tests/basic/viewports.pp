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
      oxumPrimitive, oxuTexture, oxuTransform, oxuRender, oxuRenderer, oxuMaterial,
      {test}
      uTestTools;

VAR
   primitive: oxTPrimitiveModel;
   projections: array[0..3] of oxTProjection;

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
   { disable default context }
   oxTProjection(oxWindow.Current.Projection).Enabled := false;

   projections[0] := oxTProjection.Create(0, 240, 320, 240);
   projections[0].Name := '0';
   projections[0].ClearColor.Assign(0.2, 0.2, 1.0, 1.0);
   projections[0].Perspective(60, 0.5, 1000.0);

   projections[1] := oxTProjection.Create(320, 240, 320, 240);
   projections[1].Name := '1';
   projections[1].ClearColor.Assign(0.2, 1.0, 0.2, 1.0);
   projections[1].Ortho(2.5, 2.5, 0.5, 1000.0);

   projections[2] := oxTProjection.Create(0, 0, 640, 240);
   projections[2].Name := '1';
   projections[2].ClearColor.Assign(1.0, 0.2, 0.2, 1.0);
   projections[2].Perspective(60, 0.5, 1000.0);

   projections[3] := oxTProjection.Create(560, 20, 64, 64);
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
