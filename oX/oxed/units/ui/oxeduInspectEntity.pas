{
   oxeduInspectorWindow, oxed inspector window
   Copyright (C) 2017. Dejan Boras

   Started On:    04.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduInspectEntity;

INTERFACE

   USES
      uStd, uColors, vmVector, sysutils,
      {app}
      appuMouse,
      {ox}
      oxuTypes, oxuEntity, oxuComponent, oxuComponentDescriptors,
      {ui}
      uiuTypes, uiWidgets, uiuWidget,
      wdguLabel, wdguWorkbar, wdguCheckbox, wdguInputBox, wdguGroup,
      {oxed}
      uOXED, oxeduWindow, oxeduInspectorWindow, oxeduProjectRunner, oxeduEntities;

TYPE

   { oxedTInspectorWindowTransformWidgets }

   oxedTInspectorWindowTransformWidgets = record
      Previous: TVector3f;

      Lbl,
      XLabel,
      YLabel,
      ZLabel: wdgTLabel;
      X,
      Y,
      Z: wdgTInputBox;

      procedure SetValue(w: wdgTInputBox; p, v: single; update: boolean = true);

      procedure SetValue(const value: TVector3f; update: boolean = true);
      procedure GetValues(out xValue, yValue, zValue: single);
   end;

   oxedTInspectorWindowGroupWidgets = specialize TPreallocatedArrayList<wdgTGroup>;

   { oxedTInspectEntity }

   oxedTInspectEntity = class(oxedTInspector)
      wdg: record
         Enable: wdgTCheckbox;
         Name: wdgTInputBox;
         Position,
         Rotation,
         Scale: oxedTInspectorWindowTransformWidgets;
         Transform: wdgTGroup;
      end;

      Entity: oxTEntity;

      procedure SetEntity(newEntity: oxTEntity);

      procedure Open(wnd: oxedTWindow); override;
      procedure Close({%H-}wnd: oxedTWindow); override;
      procedure SizeChanged(wnd: oxedTWindow); override;

      procedure CreateVector(const caption: string; var v: oxedTInspectorWindowTransformWidgets; onChange: wdgTInputBoxOnChangeMethod = nil);
      procedure PositionVector(y: loopint; var v: oxedTInspectorWindowTransformWidgets);

      procedure Update({%H-}wnd: oxedTWindow); override;
   end;

VAR
   oxedInspectEntity: oxedTInspectEntity;

IMPLEMENTATION

{ oxedTInspectorWindowTransformWidgets }

procedure oxedTInspectorWindowTransformWidgets.SetValue(w: wdgTInputBox; p, v: single; update: boolean);
begin
   if(w <> nil) and (p <> v) then begin
      w.SetText(FormatFloat('', v), wdgINPUT_BOX_NO_TEXT_CHANGE);
      w.GoToHome();

      if(update) then
         w.CallTextChanged();
   end;
end;

procedure oxedTInspectorWindowTransformWidgets.SetValue(const value: TVector3f; update: boolean);
begin
   SetValue(X, Previous[0], value[0], update);
   SetValue(Y, Previous[1], value[1], update);
   SetValue(Z, Previous[2], value[2], update);

   Previous := value;
end;


function getSingle(const s: string): single;
begin
   result := 0;

   try
      result := s.ToSingle();
   except
      result := 0;
   end;
end;

procedure oxedTInspectorWindowTransformWidgets.GetValues(out xValue, yValue, zValue: single);
begin
   xValue := getSingle(X.GetText());
   yValue := getSingle(Y.GetText());
   zValue := getSingle(Z.GetText());
end;

procedure positionChanged({%H-}wdg: wdgTInputBox);
var
   x, y, z: single;

begin
   oxedInspectEntity.wdg.Position.GetValues(x, y, z);

   if(oxedInspectEntity.Entity <> nil) then
      oxedInspectEntity.Entity.SetPosition(x, y, z);
end;

procedure rotationChanged({%H-}wdg: wdgTInputBox);
var
   x, y, z: single;

begin
   oxedInspectEntity.wdg.Rotation.GetValues(x, y, z);

   if(oxedInspectEntity.Entity <> nil) then
      oxedInspectEntity.Entity.SetRotation(x, y, z);
end;

procedure scaleChanged({%H-}wdg: wdgTInputBox);
var
   x, y, z: single;

begin
   oxedInspectEntity.wdg.Scale.GetValues(x, y, z);

   if(oxedInspectEntity.Entity <> nil) then
      oxedInspectEntity.Entity.SetScale(x, y, z);
end;

{ oxedTInspectorWindow }

procedure oxedTInspectEntity.Open(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;
   group: oxedTInspectorWindowGroup;

begin
   inspector := oxedTInspectorWindow(wnd);

   { header }
   inspector.wdg.Header := wdgWorkbar.Add(oxedInspector.Instance);

   uiWidget.PushTarget();
   inspector.wdg.Header.SetTarget();

   wdg.Enable := wdgCheckbox.Add('', oxNullPoint, True);
   wdg.Name := wdgInputBox.Add('', oxNullPoint, oxNullDimensions);

   uiWidget.PopTarget();

   { transform group }
   group := inspector.AddGroup('Transform');

   wdg.Transform := group.Wdg;
   uiWidget.PushTarget();
   wdg.Transform.SetTarget();

   CreateVector('Position', wdg.Position, @positionChanged);
   CreateVector('Rotation', wdg.Rotation, @rotationChanged);
   CreateVector('Scale', wdg.Scale, @scaleChanged);

   uiWidget.PopTarget();

   SetEntity(nil);
end;

procedure oxedTInspectEntity.Close(wnd: oxedTWindow);
begin

end;

procedure oxedTInspectEntity.SetEntity(newEntity: oxTEntity);
var
   inspector: oxedTInspectorWindow;
   i: loopint;
   descriptor: oxPComponentDescriptor;

begin
   Entity := newEntity;
   inspector := oxedTInspectorWindow(oxedInspector.Instance);

   if(Entity <> nil) then begin
      inspector.wdg.Header.Enable();

      if(wdg.Enable <> nil) then
         wdg.Enable.Check(Entity.Enabled);

      if(wdg.Name <> nil) then
         wdg.Name.SetText(Entity.Name);

      wdg.Position.SetValue(Entity.vPosition, false);
      wdg.Rotation.SetValue(Entity.vRotation, false);
      wdg.Scale.SetValue(Entity.vScale, false);

      for i := 0 to (Entity.Components.n - 1) do begin
         descriptor := Entity.Components.List[i].GetDescriptor();
         inspector.AddGroup(descriptor^.Name);
      end;

      SizeChanged(inspector);
   end else begin
      if(inspector.wdg.Header <> nil) then
         inspector.wdg.Header.Disable();

      wdg.Enable.Check(true);
      wdg.Name.SetText('');
      wdg.Position.SetValue(vmvZero3f);
      wdg.Rotation.SetValue(vmvZero3f);
      wdg.Scale.SetValue(vmvUnit3f);
   end;
end;

procedure oxedTInspectEntity.SizeChanged(wnd: oxedTWindow);
var
   inspector: oxedTInspectorWindow;

begin
   inspector := oxedTInspectorWindow(wnd);
   inspector.wdg.Header.Move(0, wnd.Dimensions.h - 1);
   inspector.wdg.Header.Resize(wnd.Dimensions.w, 32);

   wdg.Enable.SetPosition(wdgPOSITION_HORIZONTAL_LEFT or wdgPOSITION_VERTICAL_CENTER);

   wdg.Name.MoveRightOf(wdg.Enable);
   wdg.Name.Resize(wdg.Enable.RemainingWidth() - wdgDEFAULT_SPACING * 2, inspector.wdg.Header.Dimensions.h - 10);
   wdg.Name.Move(wdg.Name.Position.x, 20);
   wdg.Name.SetPosition(wdgPOSITION_VERTICAL_CENTER);

   PositionVector(wdg.Transform.Dimensions.h - wdg.Transform.CachedFont.GetHeight() - wdgDEFAULT_SPACING, wdg.Position);
   PositionVector(wdg.Position.Lbl.BelowOf(), wdg.Rotation);
   PositionVector(wdg.Rotation.Lbl.BelowOf(), wdg.Scale);
end;

procedure oxedTInspectEntity.CreateVector(const caption: string; var v: oxedTInspectorWindowTransformWidgets; onChange: wdgTInputBoxOnChangeMethod);
begin
   v.Lbl := wdgLabel.Add(caption, oxPoint(0, 0), oxNullDimensions);

   v.XLabel := wdgLabel.Add('X', oxPoint(0, 0), oxNullDimensions);
   v.YLabel := wdgLabel.Add('Y', oxPoint(0, 0), oxNullDimensions);
   v.ZLabel := wdgLabel.Add('Z', oxPoint(0, 0), oxNullDimensions);

   v.X := wdgInputBox.Add('0', oxPoint(0, 0), oxNullDimensions);
   v.X.InputType := wdgINPUT_BOX_TYPE_FLOAT;
   v.X.OnTextChanged := onChange;

   v.Y := wdgInputBox.Add('0', oxPoint(0, 0), oxNullDimensions);
   v.Y.InputType := wdgINPUT_BOX_TYPE_FLOAT;
   v.Y.OnTextChanged := onChange;

   v.Z := wdgInputBox.Add('0', oxPoint(0, 0), oxNullDimensions);
   v.Z.InputType := wdgINPUT_BOX_TYPE_FLOAT;
   v.Z.OnTextChanged := onChange;
end;

procedure oxedTInspectEntity.PositionVector(y: loopint; var v: oxedTInspectorWindowTransformWidgets);
var
   w,
   iw,
   parentW,
   spacing: loopint;

begin
   v.Lbl.Move(0, y - 2);

   parentW := wdg.Transform.Dimensions.w;
   spacing := 2;

   w := (parentW - v.Lbl.CachedFont.GetLength('Position   ') - spacing * 3 - wdgDEFAULT_SPACING * 3) div 3;
   iw := w - v.XLabel.CachedFont.GetLength(v.XLabel.Caption);

   v.Z.Move(parentW - wdgDEFAULT_SPACING - iw, y);
   v.Z.Resize(iw, 15);

   v.ZLabel.Move(v.Z.LeftOf(0) - v.ZLabel.Dimensions.w, y - 2);

   v.Y.Move(v.ZLabel.LeftOf(0) - iw - spacing, y);
   v.Y.Resize(iw, 15);

   v.YLabel.Move(v.Y.LeftOf(0) - v.YLabel.Dimensions.w, y - 2);

   v.X.Move(v.YLabel.LeftOf(0) - iw - spacing, y);
   v.X.Resize(iw, 15);

   v.XLabel.Move(v.X.LeftOf(0) - v.XLabel.Dimensions.w, y - 2);
end;

procedure oxedTInspectEntity.Update(wnd: oxedTWindow);
begin
   if(Entity <> nil) then begin
      wdg.Position.SetValue(Entity.vPosition, false);
      wdg.Rotation.SetValue(Entity.vRotation, false);
      wdg.Scale.SetValue(Entity.vScale, false);
   end;
end;

procedure entityRemoved(entity: oxTEntity);
var
   inspector: oxedTInspectEntity;

begin
   inspector := oxedTInspectEntity(oxedInspector.GetInspector(oxedTInspectEntity));
   if(inspector <> nil) then begin
      if(inspector.Entity = entity) or (inspector.Entity.HasParent(entity)) then begin
         oxedInspector.Close();
      end;
   end;
end;

procedure sceneChange();
begin
   if(oxedInspector.GetInspector(oxedTInspectEntity) <> nil) then begin
      oxedInspector.Close();
   end;
end;

procedure init();
begin
   oxedInspectEntity := oxedTInspectEntity.Create();
   oxedEntities.OnRemove.Add(@entityRemoved);
end;

procedure deinit();
begin
   FreeObject(oxedInspectEntity);
end;

INITIALIZATION
   oxed.Init.Add('scene.inspector', @init, @deinit);

   oxed.OnSceneChange.Add(@sceneChange);
   oxedProjectRunner.OnStart.Add(@sceneChange);
   oxedProjectRunner.OnBeforeStop.Add(@sceneChange);

END.
