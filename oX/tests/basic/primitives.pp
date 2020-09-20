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
      oxuWindowTypes, oxuWindows, oxuFont, oxuTypes,
      oxumPrimitive, oxuTexture, oxuTransform, oxuRender, oxuRenderer, oxuViewport,
      uiuUI,
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

procedure buildPrimitive();
var
   errcode: longint;

begin
   primitive.Recycle();

   case selectedPrimitive of
      0: primitive.Triangle();
      1: primitive.Circle();
      2: primitive.Disk();
      3: primitive.Quad();
      4: primitive.Cube(oxmPRIMITIVE_CUBE_METHOD_DEFAULT);
      5: primitive.Sphere(oxmPRIMITIVE_SPHERE_METHOD_SIMPLE);
      6: primitive.Cylinder();
      7: primitive.Torus();
      8: primitive.Cone();
   end;

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

procedure Render({%H-}wnd: oxTWindow);
var
   m: TMatrix4f;
   normalsString: string = '';

begin
   oxRender.DepthDefault();

   m := oxTransform.PerspectiveFrustum(75, 640 / 480, 0.5, 1000.0);
   oxRenderer.SetProjectionMatrix(m);

   oxTransform.Identity();
   oxTransform.Translate(0, 0, -5.0);
   oxTransform.Apply();

   tt.RotateXYZ();
   oxRender.Color(cWhite4f);

   primitive.Mesh.CullFace := oxCULL_FACE_NONE;
   primitive.Render();

   m := oxTransform.OrthoFrustum(0, oxViewport^.Dimensions.w, 0, oxViewport^.Dimensions.h, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);

   if(not primitiveNormals) then
      normalsString := sf(longint(normalsType))
   else
      normalsString := 'primitive';

   oxf.Default.Start();
      oxf.Default.Write(2, 2, sf(selectedPrimitive) + ' | primitive: ' + sf(longint(primitive.Mesh.Primitive)) + ' | normals: ' + normalsString);
   oxf.Stop();
end;

procedure run();
begin
   tt.dtRotateXYZ();
end;

function Keyz(oxui: uiTUI; var key: appTKeyEvent; wnd: oxTWindow): boolean;
begin
   Result := true;

   case key.Key.Code of
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
         Result := tt.DefaultKeyUp(oxui, key, wnd);
   end;
end;

procedure Initialize();
begin
   oxKey.UpRoutine := @Keyz;

   oxWindows.OnRender.Add(@Render);
   oxViewport^.ClearColor.Assign(0.1, 0.1, 0.25, 1.0);

   {load texture}
   tt.LoadTexture('textures' + DirectorySeparator + 'primitive.tga', texture);

   {initialize primitive}
   oxmPrimitive.Defaults.SphereStacks := oxmPrimitive.Defaults.sphereStacks * 2;
   oxmPrimitive.Defaults.SphereSlices := oxmPrimitive.Defaults.sphereSlices * 2;

   primitive.Init();
   buildPrimitive();
end;

procedure deinitialize();
begin
   primitive.Dispose();
   texture.Delete();
end;

BEGIN
   appInfo.setName('Primitives Test');
   ox.OnInitialize.Add('initialize', @initialize, @deinitialize);
   ox.OnRun.Add('run', @run);

   oxRun.Go();
END.
