UNIT gltransform;

INTERFACE

   USES
      uColors, appuKeys,
      uOX, oxuScene, oxuWindowTypes, oxuWindow, oxuWindows, oxuProjection,
      oxuTypes, oxuRender, oxuRenderer, oxuMaterial, oxuTransform,
      oxuFont, oxumPrimitive, oxuKeyboardControl,
      {$INCLUDE usesgl.inc},
      vmVector;

IMPLEMENTATION

VAR
   projections: array[0..1] of oxTProjection;
   primitive: oxTPrimitiveModel;
   rotation: TVector3f;

procedure renderScene(projection: oxTProjection);
var
   f: oxTFont;

begin
   primitive.Render();

   projection.QuickOrtho2DZero();

   f := oxf.Default;
   f.Start();
      f.Write(2, 2, projection.Name);
   oxf.Stop();
end;

procedure render({%H-}wnd: oxTWindow);
begin
   oxRender.CullFace(oxCULL_FACE_NONE);
   oxCurrentMaterial.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);

   projections[0].Apply();

   oxTransform.Identity();
   oxTransform.Translate(0, 0, -5.0);

   oxTransform.vPosition[0] := 0;
   oxTransform.vPosition[1] := 0;
   oxTransform.vPosition[2] := -5.0;

   oxTransform.Identity();
   oxTransform.vRotation := rotation;

   oxTransform.SetupMatrix();
   oxTransform.Apply();

   renderScene(projections[0]);

   projections[1].Apply();
   glLoadIdentity();
   glTranslatef(0, 0, -5.0);

   glRotatef(rotation[1], 0, 1, 0);
   glRotatef(rotation[2], 0, 0, 1);
   glRotatef(rotation[0], 1, 0, 0);

   renderScene(projections[1]);

   oxRenderer.ClearColor(0.0, 0.0, 0.0, 1.0);
end;

function key(var k: appTKeyEvent; {%H-}wnd: oxTWindow): boolean;
begin
   Result := false;

   if(k.Key.Equal(kcUP)) then begin
     rotation[0] := rotation[0] + 5;
   end else if(k.Key.Equal(kcDOWN)) then begin
     rotation[0] := rotation[0] - 5;
   end else if(k.Key.Equal(kcLEFT)) then begin
     rotation[1] := rotation[1] + 5;
   end else if(k.Key.Equal(kcRIGHT)) then begin
     rotation[1] := rotation[1] - 5;
   end else if(k.Key.Equal(kcQ)) then begin
     rotation[2] := rotation[2] + 5;
   end else if(k.Key.Equal(kcE)) then begin
     rotation[2] := rotation[2] - 5;
   end;
end;

procedure init();
var
   wnd: oxTWindow;

begin
   oxWindows.OnRender.Add(@render);
   oxKey.UpRoutine := @key;

   wnd := oxWindow.Current;

   projections[0] := oxTProjection.Create(oxTProjection(wnd.Projection));
   projections[0].Name := 'ox';
   projections[0].ClearColor.Assign(0.2, 0.2, 1.0, 1.0);
   projections[0].SetViewport(0, 0, wnd.Dimensions.w div 2, wnd.Dimensions.h);
   projections[0].Perspective(60, 0.5, 1000.0);

   projections[1] := oxTProjection.Create(oxTProjection(wnd.Projection));
   projections[1].Name := 'gl';
   projections[1].ClearColor.Assign(1.0, 0.2, 0.2, 1.0);
   projections[1].SetViewport(wnd.Dimensions.w div 2, 0, wnd.Dimensions.w div 2, wnd.Dimensions.h);
   projections[1].Perspective(60, 0.5, 1000.0);

   oxTProjection(wnd.Projection).Enabled := false;

   primitive.InitCube();
end;

procedure deinit();
begin
   primitive.Dispose();
end;

INITIALIZATION
   ox.OnInitialize.Add(@init);
   ox.OnDeinitialize.Add(@deinit);

   oxSceneManagement.Enabled := false;

END.
