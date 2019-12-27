{
   uTest, implements basic test functionality

   Started On:    18.02.2011.

   This test requires a texture. The texture name is specified with the
   texname constant.
}

{$INCLUDE oxdefines.inc}
PROGRAM Tex;

   USES
      uAppInfo, vmVector,
      {oX}
      {$INCLUDE oxappuses.inc}, oxuWindows, oxuWindowTypes,
      oxumPrimitive, oxuTexture, oxuTextureGenerate,
      uTestTools, oxuTransform, oxuRender, oxuRenderer;

CONST
   texname = 'data/9patch.png';

VAR
   quad: oxTPrimitiveModel;

procedure Render(wnd: oxTWindow);
var
   m: TMatrix4f;

begin
   m := oxTransform.PerspectiveFrustum(60, wnd.Dimensions.w / wnd.Dimensions.h, 1.0, 1000.0);
   oxRenderer.SetProjectionMatrix(m);

   {render quad}
   oxRender.Color4f(1.0, 1.0, 1.0, 1.0);

   oxTransform.Identity();
   oxTransform.Translate(0.0, 0.0, -5.0);
   oxTransform.Apply();

   tt.RotateXYZ();

   oxRender.EnableBlend();
   quad.Render();
end;

function Perform(a: oxTDoAction): boolean;
begin
   result := true;
   case a of
      oxDO_INITIALIZE: begin
         oxRenderer.ClearColor(0.1, 0.1, 0.25, 1.0);

         quad.InitQuad();

         tt.LoadTexture(texname, quad.texture);

         quad.SetTexRender(true);
      end;

      oxDO_RUN: begin
         tt.RotateXYZ();
      end;
   end;
end;

procedure InitializeTest();
begin
   appInfo.setName('tex');

   ox.DoRoutines.Add(@Perform);
   oxWindows.onRender := @Render;
end;

BEGIN
   InitializeTest();

   oxRun.Go();
END.
