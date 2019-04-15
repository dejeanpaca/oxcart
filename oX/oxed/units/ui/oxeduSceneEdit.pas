{
   oxeduSceneEdit, oxed scene edit window
   Copyright (C) 2016. Dejan Boras

   Started On:    26.12.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSceneEdit;

INTERFACE

   USES
      uStd, uInit, vmVector, vmCollision, uColors,
      {app}
      appuMouse, appuActionEvents,
      {ox}
      oxuRunRoutines, oxuGridRender, oxuCamera, oxuRender, oxuRenderUtilities,
      oxuScene, oxuSceneRender, oxuEntity, oxuTypes, oxuTransform, oxumPrimitive, oxuResourcePool,
      {ui}
      oxuUI, uiuWindow, oxuMaterial,
      {oxed}
      uOXED, oxeduMenubar, oxeduWindow, oxeduSceneWindow, oxeduScene, oxeduComponent, oxeduEditRenderers, oxeduEntityTypes,
      oxeduSettings, oxeduActions, oxeduDefaultScene, oxeduProjectRunner, oxeduComponentGlyph;

CONST
   OXED_DISTANCE_SCALE: single = 1 / 6.0;
   OXED_GLYPH_DISTANCE_SCALE: single = 1 / 30.0;
   OXED_GLYPH_3D_DISTANCE_SCALE: single = 0.5;
   OXED_LINE_GRID_LENGTH: single = 200;

   CONE_RADIUS = 0.075;
   CONE_LENGTH = 0.15;
   CONE_DIVISIONS = 32;

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

      SelectionRay: record
        Origin,
        EndPosition: TVector3f;
      end;

      CurrentTool: oxedTSceneEditTool;
      AxisBBoxes: array[0..2] of TBoundingBox;
      {which axis is currently selected for a tool (-1 means none)}
      SelectedAxis: loopint;

      Material: oxTMaterial;

      procedure Initialize; override;
      procedure DeInitialize; override;
      procedure SceneRenderEnd; override;

      procedure UpdateAxisBBoxes();
      procedure RenderSelectAxes();
      procedure RenderGlyphs(const componentPairs: oxedTEditRendererComponentPairs);
      procedure RenderGlyphStart();
      procedure RenderGlyph(entity: oxTEntity; component: oxedPComponent);
      procedure RenderGlyphDone();

      function GetDistanceScale(const p: TVector3f): single;

      procedure Point(var e: appTMouseEvent; x, y: longint); override;
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
   editRender: oxedTEditRenderParameters;
   editorData: oxedTEntityData;

begin
   inherited RenderEntity(params);

   editorData := oxedTEntityData(params.Entity.Editor);

   if(editorData <> nil) and (editorData.ComponentRenderers.n > 0) then begin
      editRender.Entity := params.Entity;
      editRender.Camera := params.Camera;
      editRender.Projection := Window.Projection;
      editRender.Scene := Scene;
      editRender.Window := Window;

      editorData.ComponentRenderers.Call(editRender);

      { render glyphs }
      Window.RenderGlyphs(editorData.ComponentRenderers);
   end;
end;

procedure oxedTSceneEditRenderer.CameraEnd(var params: oxTSceneRenderParameters);
begin
   params.Camera.Transform.Apply();

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
   oxRenderingUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(OXED_LINE_GRID_LENGTH, 0.0, 0.0), cRed4f);
   oxRenderingUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, OXED_LINE_GRID_LENGTH, 0.0), cGreen4f);
   oxRenderingUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, 0.0, OXED_LINE_GRID_LENGTH), cBlue4f);
   oxRender.DepthTest(oxTEST_FUNCTION_DEFAULT);
end;

{ oxedTSceneEditWindow }

procedure InitCone(out m: oxTPrimitiveModel);
begin
   oxmPrimitive.Init(m);
   m.Cone(CONE_DIVISIONS, CONE_RADIUS, CONE_LENGTH);
   m.Mesh.CullFace := oxCULL_FACE_NONE;
end;

procedure oxedTSceneEditWindow.Initialize;
begin
   inherited Initialize;

   Transform := oxTransform.Instance();
   SelectedAxis := -1;

   StateWidgetEnabled := false;

   {TODO: Rotate cone vertices, so no rotation transformation is necessary}
   InitCone(ConeModel);

   Material := oxMaterial.Make();
   Material.Name := 'oxed.scene_edit';
   Material.MarkPermanent();

   SceneRenderer := oxedTSceneEditRenderer.Create();
   SceneRenderer.Scene := Scene;
   oxedTSceneEditRenderer(SceneRenderer).Material := Material;
   oxedTSceneEditRenderer(SceneRenderer).Window := Self;
end;

procedure oxedTSceneEditWindow.DeInitialize;
begin
   inherited DeInitialize;

   FreeObject(Transform);
   oxResource.Free(Material);
end;

procedure oxedTSceneEditWindow.SceneRenderEnd;
var
   componentRenderParams: oxedTEditRenderParameters;

begin
   { render selected entity }
   if(oxedScene.SelectedEntity <> nil) then begin
      RenderSelectAxes();

      { render components }

      oxedEditRenderers.InitParams(componentRenderParams);

      componentRenderParams.Window := Self;
      componentRenderParams.Camera := Camera;
      componentRenderParams.Projection := Projection;
      componentRenderParams.Scene := Scene;
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
   camMatrix,
   tempMatrix: TMatrix4f;
   BBox: TBoundingBox;

procedure RenderCone(index: loopint; const x, y, z: single; const rX, rY, rZ: single);
begin
   Camera.Transform.Matrix := tempMatrix;
   Camera.Transform.Translate(x, y, z);

   Camera.Transform.Rotate(rX, rY, Rz);

   Camera.Transform.Apply();
   Material.ApplyColor('color', AxisColors[index]);
   ConeModel.Render();
end;

begin
   Material.Apply();

   oxedScene.SelectedEntity.GetWorldPosition(p);
   oxedScene.SelectedEntity.GetWorldRotation(rotation);

   distanceScale := GetDistanceScale(p);

   Transform.vPosition := p;
   Transform.vRotation := rotation;
   Transform.vScale.Assign(distanceScale, distanceScale, distanceScale);
   Transform.SetupMatrix();

   camMatrix := Camera.Transform.Matrix;
   Camera.Transform.Matrix := Camera.Transform.Matrix * Transform.Matrix;
   Camera.Transform.Apply();

   oxRender.LineWidth(3.0);

   oxRender.DepthTest(oxTEST_FUNCTION_NONE);
   oxRender.DepthWrite(false);

   oxRenderingUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(1.0, 0.0, 0.0), cRed4f);
   oxRenderingUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, 1.0, 0.0), cGreen4f);
   oxRenderingUtilities.Line(vmCreate(0.0, 0.0, 0.0), vmCreate(0.0, 0.0, 1.0), cBlue4f);

   oxRender.LineWidth(1.0);

   tempMatrix := Camera.Transform.Matrix;

   if(oxedSettings.Debug.RenderSelectorBBox) then begin
      BBox := vmBBoxZero;
      BBox[0].Assign(-CONE_LENGTH / 2, -CONE_LENGTH / 2, -CONE_LENGTH / 2);
      BBox[1].Assign(CONE_LENGTH / 2, CONE_LENGTH / 2, CONE_LENGTH / 2);

      Material.ApplyColor('color', AxisColors[0]);
      p.Assign(1.0 - CONE_LENGTH / 2, 0, 0);
      oxRenderingUtilities.BBox(p, BBox);

      Material.ApplyColor('color', AxisColors[1]);
      p.Assign(0, 1.0 - CONE_LENGTH / 2, 0);
      oxRenderingUtilities.BBox(p, BBox);

      Material.ApplyColor('color', AxisColors[2]);
      p.Assign(0, 0, 1.0 - CONE_LENGTH / 2);
      oxRenderingUtilities.BBox(p, BBox);
   end;

   RenderCone(0, {pos} 1.0 - CONE_LENGTH, 0.0, 0.0, {rot} 0.0, 0.0, -90);
   RenderCone(1, {pos} 0.0, 1.0 - CONE_LENGTH, 0.0, {rot} 0.0, 0.0, 0.0);
   RenderCone(2, {pos} 0.0, 0.0, 1.0 - CONE_LENGTH, {rot}  90, 0.0, 0.0);

   Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxRender.DepthDefault();

   Camera.Transform.Apply(camMatrix);
end;

procedure oxedTSceneEditWindow.RenderGlyphs(const componentPairs: oxedTEditRendererComponentPairs);
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
   pMatrix,
   camMatrix: TMatrix4f;

begin
   entity.GetWorldPosition(p);
   entity.GetWorldRotation(rotation);

   Transform.vPosition := p;
   Transform.vRotation := rotation;

   distance := Camera.vPos.Distance(p);
   if(not oxedEditRenderers.Glyphs3D) then
      distanceScale := distance * OXED_GLYPH_DISTANCE_SCALE
   else
      distanceScale := 1 * OXED_GLYPH_3D_DISTANCE_SCALE;

   Transform.vScale.Assign(distanceScale, distanceScale, distanceScale);
   Transform.SetupMatrix();

   camMatrix := Camera.Transform.Matrix;
   Camera.Transform.Matrix := Camera.Transform.Matrix * Transform.Matrix;
   pMatrix := Camera.Transform.Matrix;

   Camera.Transform.Apply();

   oxRenderingUtilities.StartQuad(component^.Glyph.Texture);

   {shadow}
   Camera.Transform.Scale(1.15, 1.15, 1);
   Camera.Transform.Apply();

   Material.ApplyColor('color', 0.0, 0.0, 0.0, 0.75);
   oxRenderingUtilities.Quad();

   {glyph}
   Camera.Transform.Apply(pMatrix);

   Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
   oxRenderingUtilities.Quad();

   Camera.Transform.Matrix := camMatrix;
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
   Result := Camera.vPos.Distance(p) * OXED_DISTANCE_SCALE;
end;

procedure oxedTSceneEditWindow.Point(var e: appTMouseEvent; x, y: longint);
var
   enter,
   leave: TVector3f;

begin
   inherited Point(e, x, y);

   if(e.Button.IsSet(appmcLEFT) and e.IsPressed()) then begin
      if(oxedScene.SelectedEntity <> nil) then begin
         if(CurrentTool = OXED_SCENE_EDIT_TOOL_TRANSLATE) then begin
            Camera.GetPointerRay(x, y, SelectionRay.Origin, SelectionRay.EndPosition, Projection);

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
               oxui.PointerCapture.LockWindow();
         end;
      end;
   end else if(e.Button.IsSet(appmcLEFT) and e.IsReleased()) then begin
      // TODO: Release lock if any
      if(SelectedAxis <> -1) then
         oxui.PointerCapture.Clear();
   end;
end;

procedure oxedTSceneEditWindow.ToolChanged();
begin

end;

procedure clearScene();
begin
   oxScene.Empty();
   oxed.OnSceneChange.Call();
end;

procedure defaultScene();
begin
   oxedDefaultScene.Create();
   oxed.OnSceneChange.Call();
end;

procedure projectStop();
begin
   if(oxedSettings.FocusGameViewOnStart) and (oxedSceneEdit.Instance <> nil) then
      oxedSceneEdit.Instance.Select();
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'scene.edit', @init, @deinit);
   oxedMenubar.OnInit.Add(@initMenubar);

   oxedActions.SCENE_CLEAR := appActionEvents.SetCallback(@clearScene);
   oxedActions.SCENE_DEFAULT := appActionEvents.SetCallback(@defaultScene);

   oxedProjectRunner.OnStop.Add(@projectStop);

END.
