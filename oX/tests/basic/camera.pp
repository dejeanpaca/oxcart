{
   Started On:	   21.03.2012.
}

{$INCLUDE oxdefines.inc}
PROGRAM camera;

   USES
      {$INCLUDE oxappuses.inc},
      uColors, vmVector,
      {oX}
      oxumPrimitive, oxuWindowTypes, oxuRender, oxuProjection, oxuRenderer, oxuWindows, oxuWindow,
      oxuTransform, oxuCamera;

VAR
   cam:  oxTCamera;
   prim: oxTPrimitiveModel;
   projection: oxTProjection;

procedure run();
begin
{
   appm.GetPosition(0, oxWindows[0].w, x, y);
   appm.GetPosition(0, oxWindows[0].w, 0, 0);
}
end;

procedure render({%H-}wnd: oxTWindow);
var
   m: TMatrix4f;

begin
   m := oxTTransform.PerspectiveFrustum(projection.p.fovY, projection.a.Aspect, projection.p.zNear, projection.p.zFar);
   oxRenderer.SetProjectionMatrix(m);

   cam.LookAt();

   prim.Render();
end;

procedure Initialize();
begin
   oxWindows.OnRender.Add(@render);

   prim.Init();
   prim.Cube(oxmPRIMITIVE_CUBE_METHOD_DEFAULT);

   cam := oxTCamera.Create();
   cam.vPos.Assign(0, 2, -5);
   cam.vView.Assign(0, -0.5, 1.0);
   cam.vView.Normalize();

   cam.Radius  := 1.0;
   cam.Style   := oxCAMERA_STYLE_FPS;

   projection := oxTProjection(oxWindow.Current.Projection);
   projection.ClearColor.Assign(0.2, 0.2, 0.5, 1.0);
   projection.Perspective(60, 0.5, 2000.0);
end;

BEGIN
   appInfo.SetName('Camera Test');

   ox.OnInitialize.Add(@Initialize);
   ox.OnRun.Add(@run);

   oxRun.Go();
END.

