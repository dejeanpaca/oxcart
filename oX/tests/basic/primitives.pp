{
   primitives, test primitive model functionality
   Copyright (C) 2012. Dejan Boras
}

{$INCLUDE oxdefines.inc}
PROGRAM primitives;

   USES
      {$INCLUDE oxappuses.inc},
      uColors,
      StringUtils, vmVector, uLog,
      {app}
      appuKeys,
      {oX}
      oxuProjection, oxuKeyboardControl,
      oxuWindowTypes, oxuWindows, oxuFont,
      oxumPrimitive, oxuTexture, oxuTransform, oxuRender, oxuRenderer,
      {test}
      uTestTools;

CONST
   MAX_PRIMITIVE = 8;

VAR
   primitive: oxTPrimitiveModel;
   selectedPrimitive: longint;
   normalsType: oxTNormalsMode;
   {the normals used are the ones provided by the primitive, not automatically calculated ones}
   primitiveNormals: boolean = false;

   texture: oxTTextureID;
   textureEnabled: boolean = false;

procedure InitLights();
begin
   tt.setupDefaultLight();

   oxRender.DepthTest(oxDEPTH_TEST_DEFAULT);
end;

procedure buildPrimitive();
var
   errcode: longint;

begin
   primitive.Recycle();

   case selectedPrimitive of
      0: errcode := primitive.Triangle();
      1: errcode := primitive.Circle();
      2: errcode := primitive.Disk();
      3: errcode := primitive.Quad();
      4: errcode := primitive.Cube(oxmPRIMITIVE_CUBE_METHOD_DEFAULT);
      5: errcode := primitive.Sphere(oxmPRIMITIVE_SPHERE_METHOD_SIMPLE);
      6: errcode := primitive.Cylinder();
      7: errcode := primitive.Torus();
      8: errcode := primitive.Cone();
   end;

   if(errcode <> 0) then
      log.e('Error(' + sf(errcode) + ') building primitive model ' + sf(selectedPrimitive));

   if(primitive.mesh.Data.nNormals = 0) then begin
      errcode := primitive.mesh.ComputeNormals(normalsType);
      if(errcode <> 0) then
         log.e('Error(' + sf(errcode) + ') computing normals for primitive model.');

      log.i('Using normals type: ' + sf(longint(normalsType)));
      primitiveNormals := false;
   end else begin
      primitiveNormals := true;
      log.i('Using normals type: primitive');
   end;

   log.i('Using primitive model: ' + sf(longint(primitive.primitiveType)));

   primitive.SetExternalTexture(texture);
end;

procedure previousPrimitive();
begin
   dec(selectedPrimitive);

   if(selectedPrimitive < 0) then
      selectedPrimitive := MAX_PRIMITIVE;

   buildPrimitive()
end;

procedure nextPrimitive();
begin
   inc(selectedPrimitive);

   if(selectedPrimitive > MAX_PRIMITIVE) then
      selectedPrimitive := 0;

   buildPrimitive()
end;

procedure Render(wnd: oxTWindow);
var
   m: TMatrix4f;
   normalsString: string = '';

begin
   oxRender.DepthTest(oxDEPTH_TEST_DEFAULT);

   m := oxTransform.PerspectiveFrustum(75, 640 / 480, 0.5, 1000.0);
   oxRenderer.SetProjectionMatrix(m);

   oxTransform.Identity();
   oxTransform.Translate(0, 0, -5.0);
   oxTransform.Apply();

   tt.RotateXYZ();
   oxRender.Color4f(1.0, 1.0, 1.0, 1.0);

   if(textureEnabled) then
      oxRender.EnableTexture();

   primitive.SetTexRender(textureEnabled);
   primitive.cullFace := oxCULL_FACE_NONE;
   primitive.Render();

   m := oxTransform.OrthoFrustum(0, oxProjection.Dimensions.w, 0, oxProjection.Dimensions.h, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   if(not primitiveNormals) then
      normalsString := sf(longint(normalsType))
   else
      normalsString := 'primitive';

   oxf.Default.Start();
      oxf.Default.Write(2, 2, sf(selectedPrimitive) + ' | primitive: ' + sf(longint(primitive.Mesh.Primitive)) + ' | normals: ' + normalsString);
   oxf.Stop();
end;

function Perform(a: oxTDoAction): boolean;
begin
   result := true;

   case a of
      oxDO_INITIALIZE: begin
         oxWindows.onRender.Add(@Render);
         oxProjection.ClearColor.Assign(0.1, 0.1, 0.25, 1.0);
         InitLights();

         {load texture}
         tt.LoadTexture('textures' + DirectorySeparator + 'primitive.tga', texture);
         primitive.SetTexture(texture);

         {initialize primitive}
         oxmPrimitive.defaults.sphereStacks := oxmPrimitive.defaults.sphereStacks * 2;
         oxmPrimitive.defaults.sphereSlices := oxmPrimitive.defaults.sphereSlices * 2;

         primitive.Init();
         buildPrimitive();
      end;

      oxDO_RUN: begin
         tt.dtRotateXYZ();
      end;

      oxDO_DEINITIALIZE: begin
         primitive.Dispose();
         texture.Delete();
      end;
   end;
end;

procedure Keyz(var key: appTKeyEvent; wnd: oxTWindow);
begin
   case key.Key.KeyCode of
      kcLEFT:  previousPrimitive();
      kcRIGHT: nextPrimitive();

      kcN: begin
         normalsType := oxTNormalsMode(longint(normalsType) + 1);
         if(longint(normalsType) > longint(oxNORMALS_MODE_NORMALIZED_VERTICES)) then
            normalsType := oxTNormalsMode(0);
         buildPrimitive();
      end;

      kcT: begin
         textureEnabled := textureEnabled xor true;
         log.v('texturing: ' + sf(textureEnabled));
      end;
      else
         tt.DefaultKeyUp(key, wnd);
   end;
end;

BEGIN
   appInfo.setName('Primitives Test');
   ox.DoRoutines.Add(@Perform);
   oxKeyUpRoutine := @Keyz;

   oxRun.Go();
END.
