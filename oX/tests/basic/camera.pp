{
   Started On:	   21.03.2012.
}

{$INCLUDE oxdefines.inc}
PROGRAM camera;

   USES appuMouse, uAppInfo, uColors, vmVector,
      {oX}
      oxuDefaults, uOX, oxuTypes, oxumPrimitive, oxuWindowTypes, oxuRender, oxuContext, oxuRenderer,
      oxuRun, oxuConstants, oxuWindows,  oxuTransform,
      oxuCamera;

VAR
   cam:  oxTCamera;
   prim: oxTPrimitiveModel;
   context: oxTContext;

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
   m := oxTTransform.PerspectiveFrustum(context.p.fovY, context.a.Aspect, context.p.zNear, context.p.zFar);
   oxRenderer.SetProjectionMatrix(m);

   cam.LookAt();

   prim.Render();
end;

function Perform(action: oxTDoAction): boolean;
begin
   result := true;

   case action of
      oxDO_INITIALIZE: begin
         prim.Init();
         prim.Cube(oxmPRIMITIVE_CUBE_METHOD_DEFAULT);

         cam := oxTCamera.Create();
         cam.vPos.Assign(0, 2, -5);
         cam.vView.Assign(0, -0.5, 1.0);
         cam.vView.Normalize();

         cam.Radius  := 1.0;
         cam.Style   := oxCAMERA_STYLE_FPS;

         context := oxTContext(oxW.context);
         context.ClearColor.Assign(0.2, 0.2, 0.5, 1.0);
         context.Perspective(60, 0.5, 2000.0);
      end;

      oxDO_RUN: begin
         run();
      end;
   end;
end;

BEGIN
   appInfo.SetName('Camera Test');

   ox.DoRoutines.Add(@Perform);
   oxWindows.onRender := @render;

   oxRun.Go();
END.

