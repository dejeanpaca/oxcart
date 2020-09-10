{
   oxeduSceneEdit, oxed scene edit window
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduSceneEdit;

INTERFACE

   USES
      uStd, vmVector, vmCollision, vmQuaternions, uColors,
      {app}
      appuMouse, appuActionEvents, appuKeys,
      {ox}
      oxuGridRender, oxuCamera, oxuRender, oxuRenderUtilities,
      oxuSceneRender, oxuEntity, oxuTypes, oxuTransform, oxumPrimitive, oxuResourcePool,
      {ui}
      uiuWindow, oxuMaterial,
      {oxed}
      uOXED, oxeduMenubar, oxeduWindow, oxeduSceneWindow, oxeduScene, oxeduComponent, oxeduThingies, oxeduEntityTypes,
      oxeduSettings, oxeduProjectRunner, oxeduComponentGlyph, oxeduActions;

CONST
   OXED_DISTANCE_SCALE: single = 1 / 6.0;
   OXED_GLYPH_DISTANCE_SCALE: single = 1 / 30.0;
   OXED_GLYPH_3D_DISTANCE_SCALE: single = 0.5;
   OXED_LINE_GRID_LENGTH: single = 200;

   SELECT_LINE_LENGTH = 1.25;
   CONE_RADIUS = 0.115;
   CONE_LENGTH = 0.175;
   CONE_DIVISIONS = 64;

   AxisColors: array[0..2] of TColor4f = (
      (1.0, 0.0, 0.0, 1.0),
      (0.0, 1.0, 0.0, 1.0),
      (0.0, 0.0, 1.0, 1.0)
   );

TYPE
   oxedTSceneEditTool = (
      OXED_SCENE_EDIT_TOOL_TRANSLATE,
      OXED_SCENE_EDIT_TOOL_ROTATE,
      OXED_SCENE_EDIT_TOOL_SCALE
   );

   { oxedTSceneEditWindow }

   oxedTSceneEditWindow = class(oxedTSceneWindow)
      Transform: oxTTransform;
      ConeModel: oxTPrimitiveModel;

      CameraOrbitMode: boolean;

      SelectionRay: record
        Origin,
        EndPosition: TVector3f;
      end;

      CurrentTool: oxedTSceneEditTool;
      AxisBBoxes: array[0..2] of TBoundingBox;
      {which axis is currently selected for a tool (-1 means none)}
      SelectedAxis: loopint;

      Material: oxTMaterial;

      procedure Initialize(); override;
      procedure DeInitialize(); override;
      procedure SceneRenderEnd(); override;

      procedure UpdateAxisBBoxes();
      procedure RenderSelectAxes();
      procedure RenderGlyphs(const componentPairs: oxedTThingieComponentPairs);
      procedure RenderGlyphStart();
      procedure RenderGlyph(entity: oxTEntity; component: oxedPComponent);
      procedure RenderGlyphDone();

      function GetDistanceScale(const p: TVector3f): single;

      {camera rotation control}
      function OrbitControl(var e: appTMouseEvent): boolean;
      procedure Point(var e: appTMouseEvent; x, y: longint); override;
      function Key(var k: appTKeyEvent): boolean; override;
      {called when the current tool changes}
      procedure ToolChanged();
   end;

   oxedTSceneEdit = class(oxedTWindowClass)
   end;

   { oxedTSceneEditRenderer }

   oxedTSceneEditRenderer = class(oxTSceneRenderer)
      public
      Window: oxedTSceneEditWindow;
      Material: oxTMaterial;

      procedure RenderEntity(var params: oxTSceneRenderParameters); override;

      procedure CameraEnd(var params: oxTSceneRenderParameters); override;
   end;

VAR
   oxedSceneEdit: oxedTSceneEdit;

IMPLEMENTATION

procedure init();
begin
   oxedSceneEdit := oxedTSceneEdit.Create('Editor', oxedTSceneEditWindow);
end;

procedure initMenubar();
begin
   oxedMenubar.OpenWindows.AddItem('Scene Edit', TObjectProcedure(@oxedSceneEdit.CreateWindow));
end;

procedure deinit();
begin
   FreeObject(oxedSceneEdit);
end;

{ oxedTSceneEditRenderer }

procedure oxedTSceneEditRenderer.RenderEntity(var params: oxTSceneRenderParameters);
var
   editRender: oxedTThingieRenderParameters;
   editorData: oxedTEntityData;

begin
   inherited RenderEntity(params);

   editorData := oxedTEntityData(params.Entity.Editor);

   if(editorData <> nil) and (editorData.ComponentRenderers.n > 0) then begin
      editRender.Entity := params.Entity;
      editRender.Camera := params.Camera;
      editRender.Projection := params.Projection;
      editRender.Scene := params.Scene;
      editRender.Window := Window;

      editorData.ComponentRenderers.Call(editRender);

      { render glyphs }
      Window.RenderGlyphs(editorData.ComponentRenderers);
   end;
end;

procedure oxedTSceneEditRenderer.CameraEnd(var params: oxTSceneRenderParameters);
begin
   params.Camera^.Apply();

   { render a base grid }

   oxRender.BlendDefault();
   oxRender.DepthWrite(false);
   Material.ApplyColor('color', 0.5, 0.5, 0.5, 0.5);
   oxRender.DepthDefault();
   oxGridRender.Render2D(OXED_LINE_GRID_LENGTH, 50);
   Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxRender.DepthWrite(true);
   oxRender.DisableBlend();

   { render XYZ axis lines }

   oxRender.DepthTest(oxTEST_FUNCTION_NONE);
   Material.ApplyColor('color', cRed4f);
   oxRenderUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(OXED_LINE_GRID_LENGTH, 0.0, 0.0));
   Material.ApplyColor('color', cGreen4f);
   oxRenderUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, OXED_LINE_GRID_LENGTH, 0.0));
   Material.ApplyColor('color', cBlue4f);
   oxRenderUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, 0.0, OXED_LINE_GRID_LENGTH));
   oxRender.DepthTest(oxTEST_FUNCTION_DEFAULT);
end;

{ oxedTSceneEditWindow }

procedure InitCone(out m: oxTPrimitiveModel);
begin
   oxmPrimitive.Init(m);
   m.Cone(CONE_DIVISIONS, CONE_RADIUS, CONE_LENGTH);
   m.Mesh.CullFace := oxCULL_FACE_NONE;
end;

procedure oxedTSceneEditWindow.Initialize();
begin
   inherited;

   Transform := oxTransform.Instance();
   SelectedAxis := -1;

   StateWidgetEnabled := false;

   {TODO: Rotate cone vertices, so no rotation transformation is necessary}
   InitCone(ConeModel);

   Material := oxMaterial.Make();
   Material.Name := 'oxed.scene_edit';
   Material.MarkPermanent();

   wdg.SceneRender.SceneRenderer := oxedTSceneEditRenderer.Create();
   wdg.SceneRender.RenderSceneCameras := false;

   oxedTSceneEditRenderer(wdg.SceneRender.SceneRenderer).Material := Material;
   oxedTSceneEditRenderer(wdg.SceneRender.SceneRenderer).Window := Self;
end;

procedure oxedTSceneEditWindow.DeInitialize();
begin
   inherited;

   FreeObject(Transform);
   oxResource.Free(Material);
end;

procedure oxedTSceneEditWindow.SceneRenderEnd();
var
   componentRenderParams: oxedTThingieRenderParameters;

begin
   { render selected entity }
   if(oxedScene.SelectedEntity <> nil) then begin
      RenderSelectAxes();

      { render components }

      oxedThingies.InitParams(componentRenderParams);

      componentRenderParams.Window := Self;
      componentRenderParams.Camera := @wdg.SceneRender.Camera;
      componentRenderParams.Projection := @wdg.SceneRender.Projection;
      componentRenderParams.Scene := wdg.SceneRender.Scene;
      componentRenderParams.Entity := oxedScene.SelectedEntity;

      oxedScene.SelectedComponentPairs.Call(componentRenderParams);
   end;
end;

procedure oxedTSceneEditWindow.UpdateAxisBBoxes();
var
   p: TVector3f;
   distanceScale,
   coneLength,
   offset: single;

begin
   ZeroOut(AxisBBoxes, SizeOf(axisBBoxes));

   if(oxedScene.SelectedEntity <> nil) then begin
      oxedScene.SelectedEntity.GetWorldPosition(p);
      distanceScale := GetDistanceScale(p);
      coneLength := CONE_LENGTH * distanceScale;
      offset := 1 * distanceScale - coneLength;

      AxisBBoxes[0].AssignPoint(p[0] + offset, p[1], p[2], coneLength / 2);
      AxisBBoxes[1].AssignPoint(p[0], p[1] + offset, p[2], coneLength / 2);
      AxisBBoxes[2].AssignPoint(p[0], p[1], p[2] + offset, coneLength / 2);
   end;
end;

procedure oxedTSceneEditWindow.RenderSelectAxes();
var
   p,
   rotation: TVector3f;
   distanceScale: single;
   BBox: TBoundingBox;
   camera: oxPCamera;

procedure RenderCone(index: loopint; const x, y, z: single; const rX, rY, rZ: single);
begin
   Transform.Translate(x, y, z);
   Transform.Rotate(rX, rY, Rz);
   Transform.Apply();

   Material.ApplyColor('color', AxisColors[index]);
   ConeModel.Render();

   Transform.Rotate(-rX, -rY, -Rz);
   Transform.Translate(-x, -y, -z);
end;

begin
   camera := @wdg.SceneRender.Camera;
   Material.Apply();

   Transform.Identity();
   Transform.Matrix := camera^.Matrix;

   oxedScene.SelectedEntity.GetWorldPosition(p);
   oxedScene.SelectedEntity.GetWorldRotation(rotation);

   distanceScale := GetDistanceScale(p);

   Transform.vPosition := p;
   vmqFromEuler(rotation, Transform.vRotation);
   Transform.vScale.Assign(distanceScale, distanceScale, distanceScale);
   Transform.SetupMatrix();

   Transform.Matrix := camera^.Matrix * Transform.Matrix;
   Transform.Apply();

   oxRender.LineWidth(1.5);

   oxRender.DepthTest(oxTEST_FUNCTION_NONE);
   oxRender.DepthWrite(false);

   Material.ApplyColor('color', cRed4f);
   oxRenderUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(SELECT_LINE_LENGTH, 0.0, 0.0));
   Material.ApplyColor('color', cGreen4f);
   oxRenderUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, SELECT_LINE_LENGTH, 0.0));
   Material.ApplyColor('color', cBlue4f);
   oxRenderUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, 0.0, SELECT_LINE_LENGTH));

   oxRender.LineWidth(1.0);

   Transform.Matrix := camera^.Matrix;

   if(oxedSettings.Debug.RenderSelectorBBox) then begin
      BBox := vmBBoxZero;
      BBox[0].Assign(-CONE_LENGTH / 2, -CONE_LENGTH / 2, -CONE_LENGTH / 2);
      BBox[1].Assign(CONE_LENGTH / 2, CONE_LENGTH / 2, CONE_LENGTH / 2);

      Material.ApplyColor('color', AxisColors[0]);
      p.Assign(SELECT_LINE_LENGTH - CONE_LENGTH / 2, 0, 0);
      oxRenderUtilities.BBox(p, BBox);

      Material.ApplyColor('color', AxisColors[1]);
      p.Assign(0, SELECT_LINE_LENGTH - CONE_LENGTH / 2, 0);
      oxRenderUtilities.BBox(p, BBox);

      Material.ApplyColor('color', AxisColors[2]);
      p.Assign(0, 0, SELECT_LINE_LENGTH - CONE_LENGTH / 2);
      oxRenderUtilities.BBox(p, BBox);
   end;

   Transform.Scale(distanceScale, distanceScale, distanceScale);

   RenderCone(0, {pos} SELECT_LINE_LENGTH - CONE_LENGTH, 0.0, 0.0, {rot} 0.0, 0.0, -90);
   RenderCone(1, {pos} 0.0, SELECT_LINE_LENGTH - CONE_LENGTH, 0.0, {rot} 0.0, 0.0, 0.0);
   RenderCone(2, {pos} 0.0, 0.0, SELECT_LINE_LENGTH - CONE_LENGTH, {rot}  90, 0.0, 0.0);

   Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxRender.DepthDefault();

   camera^.Apply();
end;

procedure oxedTSceneEditWindow.RenderGlyphs(const componentPairs: oxedTThingieComponentPairs);
var
   i: loopint;
   component: oxedPComponent;

begin
   RenderGlyphStart();

   for i := 0 to (componentPairs.n - 1) do begin
      component := componentPairs.List[i].Component;

      if(component <> nil) and (component^.Glyph.Texture <> nil) then
         RenderGlyph(oxTEntity(componentPairs.List[i].ComponentObject.Parent), component);
   end;

   RenderGlyphDone();
   Material.ApplyTexture('texture', nil);
end;

procedure oxedTSceneEditWindow.RenderGlyphStart();
begin
   Material.Apply();
   oxRender.BlendDefault();
   oxRender.CullFace(oxCULL_FACE_NONE);
   oxRender.DepthTest(oxTEST_FUNCTION_LEQUAL);
   oxRender.AlphaTest(oxTEST_FUNCTION_GREATER, 0.5);
end;

procedure oxedTSceneEditWindow.RenderGlyph(entity: oxTEntity; component: oxedPComponent);
var
   p,
   rotation: TVector3f;
   distance,
   distanceScale: single;
   pMatrix: TMatrix4f;
   camera: oxPCamera;

begin
   camera := @wdg.SceneRender.Camera;

   entity.GetWorldPosition(p);
   entity.GetWorldRotation(rotation);

   Transform.vPosition := p;
   vmqFromEuler(rotation, Transform.vRotation);

   distance := camera^.vPos.Distance(p);
   if(not oxedThingies.Glyphs3D) then
      distanceScale := distance * OXED_GLYPH_DISTANCE_SCALE
   else
      distanceScale := 1 * OXED_GLYPH_3D_DISTANCE_SCALE;

   Transform.vScale.Assign(distanceScale, distanceScale, distanceScale);
   Transform.SetupMatrix();

   Transform.Matrix := camera^.Matrix * Transform.Matrix;

   {shadow}
   pMatrix := Transform.Matrix;
   Transform.Scale(1.15, 1.15, 1);
   Transform.Apply();

   Material.ApplyColor('color', 0.0, 0.0, 0.0, 0.75);
   oxRenderUtilities.Quad(component^.Glyph.Texture);

   {glyph}
   Transform.Apply(pMatrix);

   Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxRenderUtilities.Quad();
end;

procedure oxedTSceneEditWindow.RenderGlyphDone();
begin
   Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxRender.CullFace(oxCULL_FACE_DEFAULT);
   oxRender.AlphaTest(oxTEST_FUNCTION_NONE, 1);
   oxRender.DepthDefault();
end;

function oxedTSceneEditWindow.GetDistanceScale(const p: TVector3f): single;
begin
   Result := wdg.SceneRender.Camera.vPos.Distance(p) * OXED_DISTANCE_SCALE;
end;

function oxedTSceneEditWindow.OrbitControl(var e: appTMouseEvent): boolean;
begin
   {middle button}
   if(e.bState.IsSet(appmcMIDDLE) and e.IsButtonAction()) or
      {shift + right button}
      (e.bState.IsSet(appmcRIGHT) and e.IsButtonAction() and appk.Alt()) then begin
      if(not CameraOrbitMode) then begin
         LockPointer();

         if(oxedSettings.PointerCenterEnable) then
            SetPointerCentered();

         CursorControl.CursorAngleSpeed := oxedSettings.CameraAngleSpeed;
         CursorControl.Start();
      end;

      CameraOrbitMode := true;
   end else begin
      if(CameraOrbitMode) then begin
         UnlockPointer();
         CameraOrbitMode := false;
      end;
   end;

   if(CameraOrbitMode) then begin
      CursorControl.OrbitControl(Self, wdg.SceneRender.Camera, oxedSettings.PointerCenterEnable);
      exit(true);
   end;

   Result := false;
end;

procedure oxedTSceneEditWindow.Point(var e: appTMouseEvent; x, y: longint);
var
   enter,
   leave: TVector3f;
   camera: oxPCamera;

begin
   if(OrbitControl(e)) then
      exit;

   camera := @wdg.SceneRender.Camera;

   {move camera forward/backward in view direction via the scroll wheel}
   if(e.IsWheel()) then begin
      if(not appk.Shift()) then
         camera^.vPos := camera^.vPos + (camera^.vView * -1.0 * e.Value * oxedSettings.CameraScrollSpeed)
      else
         camera^.vPos := camera^.vPos + (camera^.vUp * -1.0 * e.Value * oxedSettings.CameraScrollSpeed);
   end;

   inherited Point(e, x, y);

   if(e.Button.IsSet(appmcLEFT) and e.IsPressed()) then begin
      {selection translation}
      if(oxedScene.SelectedEntity <> nil) then begin
         if(CurrentTool = OXED_SCENE_EDIT_TOOL_TRANSLATE) then begin
            camera^.GetPointerRay(x, y, SelectionRay.Origin, SelectionRay.EndPosition, wdg.SceneRender.Projection);

            UpdateAxisBBoxes();

            if(vmRayAABBCollide(AxisBBoxes[0], SelectionRay.Origin, SelectionRay.EndPosition, enter, leave)) then
               SelectedAxis := 0
            else  if(vmRayAABBCollide(AxisBBoxes[1], SelectionRay.Origin, SelectionRay.EndPosition, enter, leave)) then
               SelectedAxis := 1
            else if(vmRayAABBCollide(AxisBBoxes[2], SelectionRay.Origin, SelectionRay.EndPosition, enter, leave)) then
               SelectedAxis := 2
            else
               SelectedAxis := -1;

            if(SelectedAxis <> -1) then
               GetUI().PointerCapture.LockWindow();
         end;
      end;
   end else if(e.Button.IsSet(appmcLEFT) and e.IsReleased()) then begin
      // TODO: Release lock if any
      if(SelectedAxis <> -1) then
         GetUI().PointerCapture.Clear();
   end;
end;

function oxedTSceneEditWindow.Key(var k: appTKeyEvent): boolean;
begin
   if(k.Key.Equal(kcF)) then begin
      appActionEvents.Queue(oxedActions.FOCUS_SELECTED);
      exit(true);
   end;

   Result := inherited Key(k);
end;

procedure oxedTSceneEditWindow.ToolChanged();
begin

end;

procedure projectStop();
begin
   if(oxedSettings.FocusGameViewOnStart) and (oxedSceneEdit.Instance <> nil) then
      oxedSceneEdit.Instance.Select();
end;

INITIALIZATION
   oxed.Init.Add('scene.edit', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedProjectRunner.OnStop.Add(@projectStop);

END.
